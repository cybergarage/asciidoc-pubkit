# frozen_string_literal: true

require 'open3'
require 'tempfile'

module AsciidocPubkit
  # Only document-referenced block images are selected; image pixels stay unchanged.
  class ImageCommands
    ARTWORK = %w[cover* chapter-* part-* profile*].freeze
    MACRO = /\A(image::[^\[]+\[)(.*)(\][ \t]*)(\r?\n)?\z/

    class SourceLoader < DocumentCommands
      attr_reader :sources, :image_sources, :source_key

      def initialize(options, err)
        super
        @sources, @image_sources = {}, {}
        @source_key = "pubkit-image-source-#{object_id}"
      end

      def load(file)
        raise Error, "Symlinked source is unsupported: #{file}" if File.symlink?(file)
        owner = self
        super(file) do |doc|
          # Asciidoctor can lose a cursor at an include boundary after lookahead.
          # Attach provenance in memory before parsing, never to the source file.
          doc.reader.define_singleton_method(:process_line) do |line|
            location = cursor
            result = super(line)
            annotated = owner.annotate(result, location)
            replace_next_line(annotated) if annotated && annotated != result
            annotated
          end
        end
      end

      def annotate(line, cursor)
        return line unless line && !line.include?(@source_key) && (match = line.match(MACRO))
        token = @image_sources.length.to_s
        @image_sources[token] = { 'file' => cursor.file && File.realpath(cursor.file), 'line' => cursor.lineno }
        attrs = match[2].empty? ? "#{@source_key}=#{token}" : "#{match[2]},#{@source_key}=#{token}"
        match[1] + attrs + match[3] + match[4].to_s
      end

      def check_source(file, root)
        super
        raise Error, "Symlinked source is unsupported: #{file}" if File.symlink?(file)
        @sources[File.realpath(file)] ||= AsciidocPubkit.read_text(file)
      end
    end

    def self.run(command, args, out:, err:)
      raise Error, 'Unknown image command. Use --help.' unless %w[list stats width].include?(command)
      options = { attributes: {}, exclude: [], ratio: 0.8, min: 40.0, max: 100.0 }
      parser = OptionParser.new do |opts|
        opts.banner = "Usage: asciidoc-pubkit image #{command} DOCUMENT.adoc [options]"
        opts.on('--base-dir DIR', 'Local include and image boundary (default: document directory)') { |v| options[:base_dir] = v }
        opts.on('-a', '--attribute NAME=VALUE', 'Asciidoctor attribute; repeat as needed') do |v|
          key, value = v.split('=', 2)
          raise Error, 'Attribute name cannot be empty.' if key.empty?
          raise Error, 'Remote includes are not supported.' if key == 'allow-uri-read'
          options[:attributes][key] = value || ''
        end
        opts.on('--only FILE', 'Select image references from one included source file') { |v| options[:only] = v }
        opts.on('--exclude GLOB', 'Exclude image basename or document-relative path; repeatable') { |v| options[:exclude] << v }
        opts.on('--include-artwork', 'Include block images matching default artwork exclusions') { options[:artwork] = true }
        opts.on('--json', 'Print a structured report') { options[:json] = true }
        if command == 'width'
          opts.on('--height-width-ratio NUMBER', Float, 'Target image height / text width (default: 0.8)') { |v| options[:ratio] = v }
          opts.on('--min-width PERCENT', Float, 'Minimum display width (default: 40)') { |v| options[:min] = v }
          opts.on('--max-width PERCENT', Float, 'Maximum display width (default: 100)') { |v| options[:max] = v }
          opts.on('--dry-run', 'Preview only (default)') { options[:dry_run] = true }
          opts.on('--diff', 'Preview a unified source diff') { options[:diff] = true }
          opts.on('--in-place', 'Explicitly update source image macros') { options[:in_place] = true }
        end
        opts.on('-h', '--help', 'Show command help') { options[:help] = true }
      end
      parser.parse!(args)
      if options[:help]
        out.puts parser
        return 0
      end
      raise Error, 'Exactly one AsciiDoc document is required.' unless args.length == 1
      raise Error, 'Expected an AsciiDoc document (.adoc or .asciidoc), not an image.' unless %w[.adoc .asciidoc].include?(File.extname(args.first).downcase)
      if command == 'width'
        unless [options[:ratio], options[:min], options[:max]].all?(&:finite?) &&
               options[:ratio].positive? && options[:min].positive? && options[:min] <= options[:max] && options[:max] <= 100
          raise Error, 'Require finite ratio > 0 and 0 < min-width <= max-width <= 100.'
        end
        raise Error, '--in-place cannot be combined with --dry-run or --diff.' if options[:in_place] && (options[:dry_run] || options[:diff])
        raise Error, '--diff cannot be combined with --json.' if options[:diff] && options[:json]
      end
      tool = new(args.first, options, err)
      report = command == 'stats' ? tool.stats : command == 'width' ? tool.width : tool.report
      if options[:diff]
        out.write(tool.diff)
      elsif options[:json]
        out.puts JSON.pretty_generate(report)
      else
        out.write(tool.format(command, report))
      end
      0
    end

    def initialize(entry, options, err)
      @options, @err = options, err
      @entry = File.realpath(entry)
      @root = File.realpath(options[:base_dir] || File.dirname(@entry))
      @loader = SourceLoader.new(options, err)
      @doc = @loader.load(entry)
      @sources = @loader.sources
      @only = options[:only] && File.realpath(options[:only])
      raise Error, '--only must be a source included in the parsed document.' if @only && !@sources.key?(@only)
      @images, @excluded, @references, @changes, @revised = {}, [], [], [], {}
      covers = %w[front-cover-image back-cover-image title-logo-image].filter_map do |key|
        value = @doc.attr(key)
        next unless value && (match = value.match(/\Aimage:{1,2}([^\[]+)\[/))
        resolve_image(match[1], @doc.attr('imagesdir', '')) unless remote?(match[1]) || remote?(@doc.attr('imagesdir', ''))
      end
      @doc.find_by(context: :image).each do |node|
        target, directory = node.attr('target'), node.attr('imagesdir', '')
        cursor = node.source_location
        provenance = @loader.image_sources[node.attr(@loader.source_key)] || {}
        reference = { 'file' => provenance['file'] || (cursor&.file && File.realpath(cursor.file)),
                      'line' => provenance['line'] || cursor&.lineno,
                      'target' => target, 'current_scaledwidth' => node.attr('scaledwidth'),
                      'mapped' => !provenance.empty? }
        @references << reference
        reason = if remote?(target) || remote?(directory)
                   'remote image'
                 elsif @only && reference['file'] != @only
                   'outside --only source'
                 end
        unless reason
          path = resolve_image(target, directory)
          reference['image'] = path
          relative = Pathname.new(path).relative_path_from(Pathname.new(@root)).to_s
          if !options[:artwork] && (covers.include?(path) || ARTWORK.any? { |glob| File.fnmatch?(glob, File.basename(path)) })
            reason = 'artwork'
          elsif options[:exclude].any? { |glob| File.fnmatch?(glob, File.basename(path)) || File.fnmatch?(glob, relative, File::FNM_PATHNAME | File::FNM_EXTGLOB) }
            reason = 'excluded by pattern'
          end
        end
        if reason
          reference['excluded'] = reason
          @excluded << reference
          next
        end
        path = reference.fetch('image')
        raise Error, "Image does not exist: #{path}" unless File.file?(path)
        real = File.realpath(path)
        raise Error, "Image is outside the base directory: #{path}" unless inside?(real)
        reference['image'] = real
        image = @images[real] ||= inspect_image(real)
        reference['editable'] = !!source_macro(reference)
        image['references'] << reference
      end
    end

    def remote?(path)
      Asciidoctor::Helpers.uriish?(path.to_s)
    end

    def inside?(path)
      path.start_with?(@root.end_with?('/') ? @root : @root + '/')
    end

    def resolve_image(target, directory)
      path = File.expand_path(target, File.expand_path(directory, @root))
      raise Error, "Image is outside the base directory: #{path}" unless inside?(path)
      path
    end

    def inspect_image(path)
      command = executable?('magick') ? %w[magick identify] : ['identify']
      stdout, stderr, status = Open3.capture3(*command, '-format', '%w %h\n', '--', path)
      raise Error, "Cannot inspect image #{path}: #{stderr.strip}" unless status.success?
      lines = stdout.lines
      match = lines.length == 1 && lines.first.match(/\A([1-9][0-9]*) ([1-9][0-9]*)\s*\z/)
      raise Error, "Unsupported image dimensions or multiple frames: #{path}" unless match
      w, h = match[1].to_i, match[2].to_i
      { 'path' => path, 'width' => w, 'height' => h, 'aspect_ratio' => w.fdiv(h),
        'bytes' => File.size(path), 'references' => [] }
    end

    def executable?(name)
      ENV.fetch('PATH', '').split(File::PATH_SEPARATOR).any? { |dir| File.file?(path = File.join(dir, name)) && File.executable?(path) }
    end

    def report
      { 'document' => @entry, 'base_dir' => @root, 'images' => @images.values,
        'image_count' => @images.length, 'reference_count' => @images.values.sum { |i| i['references'].length },
        'excluded' => @excluded, 'scope' => 'parsed block image macros; inline images are not included' }
    end

    def stats
      result = report.reject { |key, _| key == 'images' }
      result['total_bytes'] = @images.values.sum { |i| i['bytes'] }
      %w[width height aspect_ratio bytes].each do |key|
        values = @images.values.map { |i| i[key] }
        result[key] = { 'min' => values.min, 'max' => values.max,
                        'mean' => values.empty? ? nil : values.sum.fdiv(values.length) }
      end
      result
    end

    def source_macro(reference)
      file, line = reference.values_at('file', 'line')
      return unless reference['mapped'] && file && line && @sources.key?(file)
      @sources[file].lines[line - 1]&.match(MACRO)
    end

    # Split only top-level attribute commas, retaining the original spelling.
    def attributes(text)
      parts, start, quote, index = [], 0, nil, 0
      while index < text.length
        char = text[index]
        if char == '\\'
          index += 2
          next
        elsif quote
          quote = nil if char == quote
        elsif (char == '"' || char == "'") && text[start...index].strip.match?(/\A(?:[^\s=,]+\s*=\s*)?\z/)
          quote = char
        elsif char == ','
          parts << text[start...index]
          start = index + 1
        end
        index += 1
      end
      raise Error, 'Unclosed quote in source image attributes.' if quote
      parts << text[start..]
    end

    def with_width(match, width)
      parts = attributes(match[2])
      positions = parts.each_index.select { |index| parts[index].match?(/\A\s*scaledwidth\s*=/) }
      raise Error, 'Duplicate scaledwidth attributes are unsupported.' if positions.length > 1
      value = "#{number(width)}%"
      if positions.empty?
        content = match[2].empty? ? "scaledwidth=#{value}" : "#{match[2]},scaledwidth=#{value}"
      else
        index = positions.first
        token = parts[index].match(/\A(\s*scaledwidth\s*=\s*)(.*?)(\s*)\z/)
        old = token[2]
        value = "#{old[0]}#{value}#{old[0]}" if ['"', "'"].include?(old[0]) && old[-1] == old[0]
        parts[index] = token[1] + value + token[3]
        content = parts.join(',')
      end
      match[1] + content + match[3] + match[4].to_s
    end

    def number(value)
      value.to_s.delete_suffix('.0')
    end

    def width
      desired = {}
      @images.each_value do |image|
        raw = 100 * @options[:ratio] * image['aspect_ratio']
        value = [[[[raw, @options[:min]].max, @options[:max]].min.round(1), @options[:min]].max, @options[:max]].min
        image['width_percent'], image['minimum_limited'] = value, raw < @options[:min]
        image['references'].each do |reference|
          match = source_macro(reference)
          raise Error, "Cannot safely map image macro: #{reference['file']}:#{reference['line']}" unless match
          before = match[0]
          after = with_width(match, value)
          file, line = reference.values_at('file', 'line')
          key = [file, line]
          prior = desired[key]
          raise Error, "Reused source image needs conflicting widths: #{file}:#{line}" if prior && prior != after
          desired[key] = after
          next if prior || before == after
          if @excluded.any? { |r| r['file'] == file && r['line'] == line }
            raise Error, "Reused source also has excluded references: #{file}:#{line}"
          end
          @changes << { 'file' => file, 'line' => line, 'image' => image['path'],
                        'width_percent' => value, 'before' => before, 'after' => after }
        end
      end
      @changes.group_by { |c| c['file'] }.each do |file, changes|
        lines = @sources.fetch(file).lines
        changes.each { |c| lines[c['line'] - 1] = c['after'] }
        @revised[file] = lines.join
      end
      apply if @options[:in_place]
      report.merge('settings' => { 'height_width_ratio' => @options[:ratio], 'min_width' => @options[:min], 'max_width' => @options[:max] },
                   'changes' => @changes, 'changed_files' => @revised.keys, 'applied' => !!@options[:in_place])
    end

    def unchanged?(file, content)
      File.file?(file) && !File.symlink?(file) && File.realpath(file) == file && File.binread(file) == content.b
    end

    def apply
      staged, backups, installed = {}, {}, []
      begin
        @sources.each do |file, content|
          raise Error, "Source changed during analysis: #{file}" unless unchanged?(file, content)
        end
        @revised.each do |file, content|
          raise Error, "Source changed during analysis: #{file}" unless unchanged?(file, @sources.fetch(file))
          staged[file] = stage(file, content)
          backups[file] = stage(file, @sources.fetch(file))
        end
        @revised.each_key do |file|
          raise Error, "Source changed during analysis: #{file}" unless unchanged?(file, @sources.fetch(file))
          File.rename(staged.fetch(file).path, file)
          installed << file
        end
      rescue StandardError
        installed.reverse_each do |file|
          # Do not replace another writer's changes while rolling back.
          if File.binread(file) == @revised.fetch(file).b
            File.rename(backups.fetch(file).path, file)
          end
        end
        raise
      ensure
        (staged.values + backups.values).each(&:close!)
      end
    end

    def stage(file, content)
      temp = Tempfile.new(['.pubkit-image-', '.adoc'], File.dirname(file))
      temp.binmode
      temp.write(content)
      temp.flush
      temp.chmod(File.stat(file).mode & 0o777)
      temp
    rescue StandardError
      temp&.close!
      raise
    end

    def diff
      @revised.map do |file, content|
        relative = Pathname.new(file).relative_path_from(Pathname.new(@root)).to_s
        Tempfile.create('pubkit-before') do |a|
          Tempfile.create('pubkit-after') do |b|
            a.write(@sources.fetch(file)); a.flush
            b.write(content); b.flush
            stdout, stderr, status = Open3.capture3('diff', '-u', '--label', "a/#{relative}", '--label', "b/#{relative}", a.path, b.path)
            raise Error, stderr unless [0, 1].include?(status.exitstatus)
            stdout
          end
        end
      end.join
    end

    def format(command, result)
      if command == 'stats'
        "Images: #{result['image_count']}; references: #{result['reference_count']}; bytes: #{result['total_bytes']}\n" +
          %w[width height aspect_ratio bytes].map { |key| "#{key}: #{result[key].to_json}\n" }.join
      else
        result['images'].map do |image|
          "#{image['path']}\t#{image['width']}x#{image['height']}\taspect=#{image['aspect_ratio'].round(4)}\tbytes=#{image['bytes']}\treferences=#{image['references'].length}" +
            (command == 'width' ? "\twidth=#{number(image['width_percent'])}%" : '') + "\n"
        end.join + "Images: #{result['image_count']}; references: #{result['reference_count']}; excluded: #{@excluded.length}" +
          (command == 'width' ? "; changes: #{@changes.length}; #{result['applied'] ? 'applied' : 'preview'}" : '') + "\n"
      end
    end
  end
end
