# frozen_string_literal: true

require 'find'

module AsciidocPubkit
  # Read-only document utilities, independent of Japanese review settings.
  class DocumentCommands
    METADATA = %w[subtitle description keywords lang uuid author producer creator].freeze

    def self.run(command, args, out:, err:)
      options = { attributes: {} }
      parser = OptionParser.new do |opts|
        opts.banner = "Usage: asciidoc-pubkit document #{command} [options] #{command == 'index' ? 'DIRECTORY' : 'FILE'}"
        opts.on('-o', '--output FILE', 'New output file (default: standard output)') { |v| options[:output] = v }
        opts.on('--base-dir DIR', 'Local include boundary (default: input directory)') { |v| options[:base_dir] = v }
        opts.on('-a', '--attribute NAME=VALUE', 'Set an Asciidoctor attribute; repeat as needed') do |v|
          key, value = v.split('=', 2)
          raise Error, 'Attribute name cannot be empty.' if key.empty?
          raise Error, 'Remote includes are not supported.' if key == 'allow-uri-read'
          options[:attributes][key] = value || ''
        end
        if command == 'toc'
          opts.on('--depth N', 'Maximum section level (positive integer)') do |v|
            options[:depth] = CLI.positive_depth(v)
          end
          opts.on('--json', 'Output a structured outline with source locations') { options[:json] = true }
          opts.on('-n', '--numbered', 'Output outline numbers such as 1-2') { options[:numbered] = true }
        elsif command == 'index'
          opts.on('-t', '--title TITLE', 'Prepend an AsciiDoc index title') { |v| options[:title] = v }
        else
          opts.on('--json', 'Output JSON') { options[:json] = true }
        end
        opts.on('-h', '--help', 'Show command help') { options[:help] = true }
      end
      parser.parse!(args)
      if options[:help]
        out.puts parser
        return 0
      end
      raise Error, 'Exactly one input is required. Use --help.' unless args.length == 1
      if options[:output] && (File.exist?(options[:output]) || File.symlink?(options[:output]))
        raise Error, "Output already exists: #{options[:output]}"
      end
      tool = new(options, err)
      code = 0
      if command == 'index'
        content = tool.index(args.first)
      else
        doc = tool.load(args.first)
        case command
        when 'toc'
          content = tool.toc(doc)
        when 'info'
          metadata = { 'doctitle' => doc.doctitle(sanitize: true).to_s.strip }
          METADATA.each { |key| metadata[key] = doc.attr(key).to_s.strip }
          content = options[:json] ? JSON.pretty_generate(metadata) + "\n" : metadata.map { |k, v| "#{k}: #{v}\n" }.join
        when 'check-xrefs'
          missing = tool.check_xrefs(doc)
          code = missing.empty? ? 0 : 1
          content = options[:json] ? JSON.pretty_generate(missing) + "\n" : missing.map { |item| "#{item['file']}:#{item['line'] || '?'}\t#{item['refid']}\n" }.join
        end
      end
      CLI.output(content, options[:output], out)
      code
    end

    def initialize(options, err)
      @options, @err = options, err
    end

    def load(file, default_root: nil)
      entry = File.realpath(file)
      root = File.realpath(@options[:base_dir] || default_root || File.dirname(entry))
      raise Error, "Base directory is not a directory: #{root}" unless File.directory?(root)
      check_source(entry, root)
      logger = Asciidoctor::MemoryLogger.new
      previous = Asciidoctor::LoggerManager.logger
      begin
        Asciidoctor::LoggerManager.logger = logger
        doc = Asciidoctor.load_file(entry, safe: :safe, sourcemap: true, parse: false,
                                   base_dir: root, attributes: @options[:attributes])
        owner = self
        # Reject targets before Asciidoctor can clamp an outside path into its
        # safe-mode jail, and before reading any remote or symlinked source.
        doc.reader.define_singleton_method(:resolve_include_path) do |target, attrlist, attributes|
          raise Error, 'Remote includes are not supported.' if Asciidoctor::Helpers.uriish?(target)
          candidate = File.expand_path(target, dir)
          unless candidate.start_with?(root.end_with?('/') ? root : root + '/')
            raise Error, "Include is outside the base directory: #{target}"
          end
          owner.check_source(candidate, root) if File.file?(candidate)
          super(target, attrlist, attributes)
        end
        doc.reader.define_singleton_method(:push_include) do |*args|
          owner.check_source(args[1], root) if args[1] && File.file?(args[1])
          super(*args)
        end
        doc.parse
      ensure
        Asciidoctor::LoggerManager.logger = previous
      end
      messages = logger.messages
      messages.each { |m| @err.puts "#{m[:severity]}: #{m[:message]}" }
      raise Error, "Failed to parse document: #{entry}" if messages.any? { |m| %i[ERROR FATAL].include?(m[:severity]) }
      doc
    end

    def check_source(file, root)
      path = File.realpath(file)
      raise Error, "Source is outside the base directory: #{path}" unless path.start_with?(root.end_with?('/') ? root : root + '/')
      AsciidocPubkit.read_text(path)
    end

    def toc(doc)
      return JSON.pretty_generate(toc_outline(doc)) + "\n" if @options[:json]
      lines = []
      walk = lambda do |sections, prefix, nesting|
        sections.each_with_index do |section, index|
          number = prefix + [index + 1]
          if !@options[:depth] || section.level <= @options[:depth]
            title = section.title
            lines << (@options[:numbered] ? "#{number.join('-')}. #{title}" : "#{'  ' * nesting}#{title}")
            walk.call(section.sections, number, nesting + 1)
          end
        end
      end
      walk.call(doc.sections, [], 0)
      lines.empty? ? '' : lines.join("\n") + "\n"
    end

    def toc_outline(doc)
      entries = []
      source_lines = {}
      walk = lambda do |sections, prefix, nesting, parent_index|
        sections.each_with_index do |section, sibling|
          number = prefix + [sibling + 1]
          next if @options[:depth] && section.level > @options[:depth]
          cursor = section.source_location
          source_title = nil
          if cursor && cursor.file && File.file?(cursor.file)
            lines = source_lines[cursor.file] ||= begin
              check_source(cursor.file, File.realpath(doc.base_dir))
              AsciidocPubkit.read_text(cursor.file).lines
            end
            line = lines[cursor.lineno - 1]
            source_title = line&.match(/\A={1,6}[ \t]+(.*?)[ \t]*\r?\n?\z/)&.[](1)
          end
          index = entries.length
          entries << { 'index' => index, 'parent_index' => parent_index,
                       'level' => section.level, 'nesting' => nesting, 'number' => number.join('-'),
                       'section_id' => section.id, 'title' => section.title,
                       'file' => cursor&.file, 'line' => cursor&.lineno, 'source_title' => source_title }
          walk.call(section.sections, number, nesting + 1, index)
        end
      end
      walk.call(doc.sections, [], 0, nil)
      { 'schema_version' => 1, 'entry' => doc.attr('docfile'), 'depth' => @options[:depth], 'headings' => entries }
    end

    def index(directory)
      root = File.realpath(directory)
      raise Error, "Input is not a directory: #{directory}" unless File.directory?(root)
      entries = []
      Find.find(root) do |path|
        if File.directory?(path)
          Find.prune if path != root && File.basename(path).start_with?('.')
          next
        end
        next unless File.extname(path) == '.adoc'
        next if @options[:output] && File.expand_path(path) == File.expand_path(@options[:output])
        doc = load(path, default_root: root)
        next if doc.id.to_s.empty?
        title = doc.doctitle(sanitize: true).to_s.gsub(/\s*\([^)]*\)/, '').split(/[：:]/, 2).first.to_s.gsub(/\s+/, ' ').strip
        next unless title.ascii_only? && title.match?(/[A-Za-z]/)
        entries << { id: doc.id, title: title, path: Pathname.new(path).relative_path_from(Pathname.new(root)).to_s }
      end
      selected = entries.sort_by { |e| [e[:path].count('/'), e[:path]] }.each_with_object({}) { |e, memo| memo[e[:title].downcase] ||= e }
      lines = []
      if @options[:title]
        raise Error, 'Index title must be a nonempty single line.' if @options[:title].strip.empty? || @options[:title].match?(/[\r\n]/)
        lines.concat(['[#book-index]', "= #{@options[:title]}"])
      end
      selected.values.sort_by { |e| [e[:title].downcase, e[:path]] }.group_by { |e| e[:title][/[A-Za-z]/].upcase }.each do |letter, group|
        lines << '' unless lines.empty?
        lines.concat(['[discrete]', "=== #{letter}"])
        group.each { |e| lines << "* <<#{e[:id]},#{e[:title]}>>" }
      end
      lines.empty? ? '' : lines.join("\n") + "\n"
    end

    # Scan raw AST fields only where macro substitutions are active. Converted
    # text would hide xref targets; source-wide matching would include comments/code.
    def check_xrefs(doc)
      missing = []
      nodes = doc.find_by.dup
      nodes.select { |node| node.context == :table }.each do |table|
        [table.rows.head, table.rows.body, table.rows.foot].flatten.each do |cell|
          nodes << cell
          nodes.concat(cell.inner_document.find_by) if cell.inner_document
        end
      end
      nodes.each do |node|
        cursor = node.source_location
        if node.respond_to?(:subs) && node.subs.include?(:macros)
          if node.respond_to?(:lines)
            node.lines.each_with_index { |line, i| scan_refs(line, node, cursor, i, doc, missing) }
          elsif node.instance_variable_defined?(:@text)
            scan_refs(node.instance_variable_get(:@text), node, cursor, 0, doc, missing)
          end
        end
        title = node.instance_variable_get(:@title)
        scan_refs(title, node, cursor, 0, doc, missing) if title
      end
      missing.uniq { |m| m.values_at('file', 'line', 'refid') }.sort_by { |m| [m['file'], m['line'] || 0, m['refid']] }
    end

    def scan_refs(text, node, cursor, offset, doc, missing)
      text = node.apply_subs(text, [:attributes])
      targets = text.scan(/(?<!\\)xref:([^\[]+)\[(?:\\.|[^\]\\])*\]/).map { |m| [m.first, :macro] }
      targets.concat(text.scan(/(?<!\\)<<(.+?)>>/).map { |m| [m.first.split(',', 2).first, :short] })
      targets.each do |target, kind|
        target = target.strip
        if target.include?('#')
          path, id = target.split('#', 2)
          next unless path.empty? || local_path?(path, doc, cursor)
        else
          next if kind == :macro && !File.extname(target).empty?
          id = target
        end
        next if id.to_s.empty? || doc.catalog[:refs].key?(id) || doc.resolve_id(id)
        missing << { 'refid' => id, 'file' => cursor&.file || doc.attr('docfile'), 'line' => cursor && cursor.lineno + offset }
      end
    end

    def local_path?(path, doc, cursor)
      return false if path.match?(/\A[a-z][a-z0-9+.-]*:/i)
      normalized = path.sub(/\.(?:adoc|asciidoc|asc|ad)\z/, '')
      files = [doc.attr('docfile')] + doc.catalog[:includes].keys
      files.any? do |file|
        candidate = File.expand_path(file, doc.base_dir).sub(/\.(?:adoc|asciidoc|asc|ad)\z/, '')
        [doc.base_dir, cursor&.file && File.dirname(cursor.file)].compact.any? { |base| candidate == File.expand_path(normalized, base) }
      end
    end
  end
end
