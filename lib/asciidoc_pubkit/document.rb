# frozen_string_literal: true

module AsciidocPubkit
  class Document
    attr_reader :sources, :paragraphs, :coverage, :diagnostics, :structure, :headings, :outline, :scope

    def initialize(entry, settings, only: nil)
      @entry = File.realpath(entry)
      @root = File.realpath(settings.fetch('base_dir'))
      @sources = {}
      @paragraphs = []
      @headings = []
      @outline = []
      @coverage = []
      @diagnostics = []
      @settings = settings
      @scope = settings.fetch('scope', 'prose')
      @only = only && File.realpath(only)
      capture(@entry)
      logger = Asciidoctor::MemoryLogger.new
      previous_logger = Asciidoctor::LoggerManager.logger
      begin
        Asciidoctor::LoggerManager.logger = logger
        doc = Asciidoctor.load_file(@entry, safe: :safe, sourcemap: true, parse: false,
                                   base_dir: @root, attributes: settings.fetch('attributes'))
        owner = self
        doc.reader.define_singleton_method(:push_include) do |*args|
          owner.capture(args[1]) if args[1] && File.file?(args[1])
          super(*args)
        end
        doc.parse
        document_language = doc.attr('lang')
        if document_language && document_language != settings.fetch('language')
          Language.validate!(document_language, operation: 'review')
          raise Error, "Document language #{document_language.inspect} does not match review language #{settings.fetch('language').inspect}."
        end
        @line_index = Hash.new { |hash, key| hash[key] = [] }
        @source_lines = @sources.to_h do |path, raw|
          lines = raw.lines.map { |line| line.delete_suffix("\n").delete_suffix("\r") }
          lines.each_with_index { |line, index| @line_index[line] << [path, index] }
          [path, lines]
        end
        nodes = doc.find_by
        @structure = nodes.map do |node|
          [node.context.to_s, (node.level if node.respond_to?(:level)),
           node.id, (node.title if node.respond_to?(:title?) && node.title?),
           (node.lines if %i[listing literal pass].include?(node.context))]
        end
        @heading_lines = {}
        @source_lines.each do |path, lines|
          lines.each_with_index do |line, offset|
            match = line.match(/\A(={1,6}[ \t]+)(.*?)([ \t]*)\z/)
            @heading_lines[[path, offset + 1]] = match if match
          end
        end
        @section_indexes = nodes.each_with_index.to_h
        nodes.each_with_index { |node, index| collect_heading(node, index) if node.context == :section && node != doc.header }
        nodes.each { |node| collect(node) }
      ensure
        Asciidoctor::LoggerManager.logger = previous_logger
      end
      @diagnostics = logger.messages.map do |message|
        { 'severity' => message[:severity].to_s, 'message' => message[:message].to_s }
      end
      if @only && !@sources.key?(@only)
        raise Error, '--only must name a file included in the parsed document.'
      end
    end

    def capture(path)
      real = File.realpath(path)
      unless real == @root || real.start_with?(@root + File::SEPARATOR)
        raise Error, "Source is outside the base directory: #{real}"
      end
      @sources[real] ||= AsciidocPubkit.read_text(real)
    end

    def to_h
      { 'paragraphs' => paragraphs, 'headings' => headings, 'outline' => outline, 'coverage' => coverage, 'structure' => structure }
    end

    private

    # Only ATX section titles that match original source text are editable.
    # Converted inline titles, attribute substitutions and old-style titles stay protected.
    def collect_heading(node, index)
      parent_index = @section_indexes[node.parent] if node.parent.context == :section
      @outline << { 'index' => index, 'parent_index' => parent_index,
                    'level' => node.level, 'section_id' => node.id, 'text' => node.title }
      return unless @settings.fetch('scope', 'prose') == 'headings'
      cursor = node.source_location
      path, line = cursor && [cursor.file, cursor.lineno]
      match = @heading_lines[[path, line]]
      unless match && match[2] == node.title
        @coverage << { 'context' => 'heading', 'file' => path, 'line' => line,
                       'reason' => 'Source title could not be resolved unambiguously; only plain ATX section titles are editable.', 'text' => node.title }
        return
      end
      relative = Pathname.new(path).relative_path_from(Pathname.new(@root)).to_s
      return if @only && @only != path
      if @settings.fetch('exclude').any? { |glob| File.fnmatch?(glob, relative, File::FNM_PATHNAME | File::FNM_DOTMATCH) }
        @coverage << { 'context' => 'heading', 'file' => path, 'line' => line, 'reason' => 'Excluded by configuration.' }
        return
      end
      @headings << { 'id' => AsciidocPubkit.hash_text([path, line, match[2]].join("\0"))[0, 16],
                     'index' => index, 'parent_index' => parent_index,
                     'file' => path, 'line' => line, 'column' => match[1].length + 1,
                     'prefix' => match[1], 'suffix' => match[3], 'level' => node.level,
                     'section_id' => node.id, 'text' => match[2] }
    end

    def collect(node)
      if %i[list_item table quote verse listing literal pass].include?(node.context)
        @coverage << { 'context' => node.context.to_s, 'reason' => 'Not reviewed as running prose.' }
      end
      return unless node.context == :paragraph
      parent = node.parent
      while parent
        return if %i[quote verse table listing literal pass list_item ulist olist dlist].include?(parent.context)
        parent = parent.parent
      end
      lines = node.lines
      matches = []
      @line_index[lines.first].each do |path, index|
        matches << [path, index + 1] if @source_lines[path][index, lines.length] == lines
      end
      cursor = node.source_location
      hint = cursor && [cursor.file, cursor.lineno]
      location = matches.include?(hint) ? hint : (matches.one? ? matches.first : nil)
      unless location
        @coverage << { 'context' => 'paragraph', 'reason' => 'Source location could not be resolved unambiguously.', 'text' => lines.join("\n") }
        return
      end
      path, line = location
      relative = Pathname.new(path).relative_path_from(Pathname.new(@root)).to_s
      return if @only && @only != path
      if @settings.fetch('exclude').any? { |glob| File.fnmatch?(glob, relative, File::FNM_PATHNAME | File::FNM_DOTMATCH) }
        @coverage << { 'context' => 'paragraph', 'file' => path, 'line' => line, 'reason' => 'Excluded by configuration.' }
        return
      end
      headings = []
      section_index = nil
      parent = node.parent
      while parent
        if parent.context == :section && parent.title
          headings.unshift(parent.title)
          section_index ||= @section_indexes[parent]
        end
        parent = parent.parent
      end
      text = lines.join("\n")
      @paragraphs << {
        'id' => AsciidocPubkit.hash_text([path, line, text].join("\0"))[0, 16],
        'file' => path, 'line' => line, 'end_line' => line + lines.length - 1,
        'section_index' => section_index, 'headings' => headings, 'text' => text
      }
    end
  end
end
