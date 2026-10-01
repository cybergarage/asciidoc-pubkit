# frozen_string_literal: true

require 'tmpdir'
require 'tempfile'
require 'open3'

module AsciidocPubkit
  class ReplacementRules
    def self.load(path)
      collect(path, [], {}).each_with_index.map do |rule, index|
        unless rule.is_a?(Hash) && (rule.keys - %w[expected pattern patterns specs]).empty? &&
               rule['expected'].is_a?(String) && (rule.key?('pattern') ^ rule.key?('patterns'))
          raise Error, "Rule #{index + 1} requires expected and exactly one of pattern or patterns; unsupported keys are rejected."
        end
        patterns = rule.key?('pattern') ? [rule['pattern']] : rule['patterns']
        unless patterns.is_a?(Array) && !patterns.empty? && patterns.all? { |p| p.is_a?(String) && !p.empty? }
          raise Error, 'Replacement patterns must be nonempty strings.'
        end
        compiled = patterns.map do |pattern|
          if pattern.start_with?('/')
            match = pattern.match(%r{\A/(.*)/([a-z]*)\z}m)
            raise Error, 'Regex flags are unsupported; omit flags (all matches are collected).' unless match && match[2].empty?
            body = match[1]
            # Deliberately small common JavaScript/Ruby subset; Ruby-only escapes
            # and engine-specific groups must not silently change JS semantics.
            if body.match?(/\\[^\\\/.*+?()\[\]{}^$|nrtdDsSwW-]/) || body.match?(/\(\?(?![:=!]|<[=!])/) || body.include?('&&')
              raise Error, 'Unsupported regex syntax in replacement rule.'
            end
            Regexp.new(body.gsub('\\/', '/'), timeout: 0.1)
          else
            Regexp.new(Regexp.escape(pattern), timeout: 0.1)
          end
        end
        compiled.each do |regex|
          regex.match('') # Detect common empty matches; runtime checks cover contextual ones.
          raise Error, 'Zero-length replacement matches are unsupported.' if regex.match('')
        end
        specs = rule.fetch('specs', [])
        raise Error, 'specs must be an array.' unless specs.is_a?(Array)
        specs.each do |spec|
          RuleSet.mapping(spec, %w[from to], 'Replacement spec')
          raise Error, 'Spec from/to must be strings.' unless spec.values.all? { |v| v.is_a?(String) }
          result = spec['from'].dup
          edits = matches(spec['from'], compiled, rule['expected'])
          reject_overlaps!(edits)
          edits.reverse_each { |edit| result[edit[:start]...edit[:finish]] = edit[:after] }
          raise Error, "Replacement spec failed for rule #{index + 1}." unless result == spec['to']
        end
        { id: "rule-#{index + 1}", patterns: compiled, expected: rule['expected'] }
      end
    rescue RegexpError, Regexp::TimeoutError => e
      raise Error, "Invalid replacement regex: #{e.message}"
    end

    def self.collect(path, active, visited)
      path = File.realpath(path)
      if active.include?(path)
        raise Error, "Circular replacement imports: #{(active + [path]).join(' -> ')}"
      end
      return [] if visited[path]
      raise Error, 'Replacement imports exceed the maximum depth of 100 files.' if active.length >= 100
      data = YAML.safe_load(AsciidocPubkit.read_text(path), permitted_classes: [], aliases: false)
      unless data.is_a?(Hash) && data.key?('version') && (data.keys - %w[version rules imports]).empty?
        raise Error, "Replacement rules in #{path} require version and accept only rules and imports."
      end
      unless data['version'].is_a?(Integer) && data['version'] == 1
        raise Error, "Replacement version in #{path} must be integer 1."
      end
      rules = data.fetch('rules', [])
      imports = data.fetch('imports', [])
      raise Error, "rules in #{path} must be an array." unless rules.is_a?(Array)
      raise Error, "imports in #{path} must be an array." unless imports.is_a?(Array)
      imported = imports.flat_map do |entry|
        if entry.is_a?(Hash)
          RuleSet.mapping(entry, ['path'], "Replacement import in #{path}")
          entry = entry['path']
        end
        unless entry.is_a?(String) && !entry.strip.empty? && !entry.match?(/\A[a-z][a-z0-9+.-]*:/i)
          raise Error, "Replacement imports in #{path} must specify nonempty local file paths."
        end
        collect(File.expand_path(entry, File.dirname(path)), active + [path], visited)
      end
      visited[path] = true
      imported + rules
    rescue Psych::Exception => e
      raise Error, "Invalid replacement YAML in #{path}: #{e.message}"
    end

    def self.expand(template, match)
      template.gsub(/\$\$|\$[1-9][0-9]?|\$./) do |ref|
        if ref == '$$'
          '$'
        elsif ref.match?(/\A\$[1-9][0-9]?\z/) && ref[1..].to_i < match.length
          match[ref[1..].to_i] || ''
        else
          raise Error, "Unsupported replacement reference: #{ref}"
        end
      end
    end

    def self.matches(text, patterns, expected)
      patterns.flat_map do |regex|
        text.to_enum(:scan, regex).map do
          match = Regexp.last_match
          raise Error, 'Zero-length replacement matches are unsupported.' if match.begin(0) == match.end(0)
          { start: match.begin(0), finish: match.end(0), before: match[0], after: expand(expected, match) }
        end
      end.reject { |edit| edit[:before] == edit[:after] }.uniq.sort_by { |edit| edit[:start] }
    rescue Regexp::TimeoutError
      raise Error, 'Replacement regex timed out.'
    end

    def self.reject_overlaps!(edits)
      edits.sort_by { |edit| edit[:start] }.each_cons(2) do |left, right|
        raise Error, 'Conflicting replacement candidates overlap; revise the rules.' if left[:finish] > right[:start]
      end
    end
  end

  class Replacement
    attr_reader :candidates

    def initialize(entry, options)
      raise Error, 'Replacement commands require --rules FILE.' unless options[:rules]
      raise Error, 'Replacement entry must not be a symlink.' if File.symlink?(entry)
      @entry = File.realpath(entry)
      @only = options[:only] && File.realpath(options[:only])
      @settings = Settings.new(entry, options.merge(replacement: true)).data
      @document = Document.new(entry, @settings, only: options[:only])
      raise Error, 'Replacement input has parsing diagnostics.' unless @document.diagnostics.empty?
      rules = ReplacementRules.load(options[:rules])
      @candidates = []
      @document.paragraphs.each do |paragraph|
        text = paragraph['text']
        protected_ranges = text.to_enum(:scan, Rules::INLINE).map do
          match = Regexp.last_match
          match.begin(0)...match.end(0)
        end
        raw = @document.sources.fetch(paragraph['file'])
        lines = raw.lines
        line_offsets = [0]
        lines.each { |line| line_offsets << line_offsets.last + line.length }
        rules.each do |rule|
          ReplacementRules.matches(text, rule[:patterns], rule[:expected]).each do |edit|
            next if protected_ranges.any? { |range| edit[:start] < range.end && edit[:finish] > range.begin }
            # Keep physical line boundaries intact, including CRLF.
            raise Error, 'Replacement matches and results must stay on one line.' if (edit[:before] + edit[:after]).match?(/[\r\n]/)
            prefix = text[0...edit[:start]]
            line = paragraph['line'] + prefix.count("\n")
            column = (prefix.rindex("\n") ? prefix.length - prefix.rindex("\n") : prefix.length + 1)
            start = line_offsets.fetch(line - 1) + column - 1
            raise Error, 'Replacement source mapping is ambiguous.' unless raw[start, edit[:before].length] == edit[:before]
            @candidates << edit.merge(start: start, finish: start + edit[:before].length,
                                     file: paragraph['file'], line: line, column: column, rule: rule[:id])
          end
        end
      end
      @candidates.uniq!
      @candidates.sort_by! { |edit| [edit[:file], edit[:start], edit[:rule]] }
      @candidates.group_by { |edit| edit[:file] }.each_value { |edits| ReplacementRules.reject_overlaps!(edits) }
      @updated = @document.sources.transform_values(&:dup)
      @candidates.reverse_each { |edit| @updated[edit[:file]][edit[:start]...edit[:finish]] = edit[:after] }
      validate unless @candidates.empty?
    end

    def report
      candidates.map { |edit| "#{edit[:file]}:#{edit[:line]}:#{edit[:column]}: #{edit[:rule]} #{edit[:before].inspect} -> #{edit[:after].inspect}\n" }.join +
        "#{candidates.length} replacements; #{@document.coverage.length} coverage notices. Only mapped running prose is eligible.\n"
    end

    def changed
      @updated.select { |path, text| text != @document.sources[path] }
    end

    def diff
      changed.map do |path, text|
        Tempfile.create('pubkit-before') do |before|
          Tempfile.create('pubkit-after') do |after|
            before.binmode.write(@document.sources[path]); before.flush
            after.binmode.write(text); after.flush
            output, error, status = Open3.capture3('diff', '-u', '--label', "#{path} (before)", '--label', "#{path} (after)", before.path, after.path)
            raise Error, "Cannot generate diff: #{error}" unless [0, 1].include?(status.exitstatus)
            output
          end
        end
      end.join
    end

    def validate
      root = File.realpath(@settings['base_dir'])
      Dir.mktmpdir('pubkit-replacement-') do |stage|
        stage = File.realpath(stage)
        @updated.each do |path, text|
          destination = File.join(stage, Pathname.new(path).relative_path_from(Pathname.new(root)).to_s)
          FileUtils.mkdir_p(File.dirname(destination))
          File.binwrite(destination, text)
        end
        staged_entry = File.join(stage, Pathname.new(@entry).relative_path_from(Pathname.new(root)).to_s)
        staged_only = @only && File.join(stage, Pathname.new(@only).relative_path_from(Pathname.new(root)).to_s)
        staged = Document.new(staged_entry, @settings.merge('base_dir' => stage), only: staged_only)
        raise Error, 'Replacement changes parsing or document structure.' unless staged.diagnostics.empty? && staged.structure == @document.structure
        original = Session.protected_content(@document).transform_keys { |path| Pathname.new(path).relative_path_from(Pathname.new(root)).to_s }
        result = Session.protected_content(staged).transform_keys { |path| Pathname.new(path).relative_path_from(Pathname.new(stage)).to_s }
        # --only can leave otherwise eligible paragraphs protected in the original.
        if original != result
          raise Error, 'Replacement changes source membership or protected content.'
        end
      end
    end

    def apply
      installed = []
      prepared = []
      begin
        changed.each do |path, text|
          file = Tempfile.new('.pubkit-replace-', File.dirname(path))
          prepared << [path, file]
          file.binmode.write(text)
          file.flush
          file.fsync
          File.chmod(File.stat(path).mode & 0o777, file.path)
        end
        @document.sources.each do |path, raw|
          unless !File.symlink?(path) && File.binread(path) == raw.b
            raise Error, "Source changed before replacement: #{path}"
          end
        end
        prepared.each do |path, file|
          File.rename(file.path, path)
          installed << path
        end
      rescue StandardError
        installed.reverse_each { |path| File.binwrite(path, @document.sources.fetch(path)) }
        raise
      ensure
        prepared.each { |_, file| file.close! }
      end
    end
  end
end
