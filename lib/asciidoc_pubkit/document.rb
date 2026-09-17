# frozen_string_literal: true

module AsciidocPubkit
  class Document
    attr_reader :sources, :paragraphs, :coverage, :diagnostics, :structure

    def initialize(entry, settings, only: nil)
      @entry = File.realpath(entry)
      @root = File.realpath(settings.fetch('base_dir'))
      @sources = {}
      @paragraphs = []
      @coverage = []
      @diagnostics = []
      @settings = settings
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
      { 'paragraphs' => paragraphs, 'coverage' => coverage, 'structure' => structure }
    end

    private

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
      parent = node.parent
      while parent
        headings.unshift(parent.title) if parent.context == :section && parent.title
        parent = parent.parent
      end
      text = lines.join("\n")
      @paragraphs << {
        'id' => AsciidocPubkit.hash_text([path, line, text].join("\0"))[0, 16],
        'file' => path, 'line' => line, 'end_line' => line + lines.length - 1,
        'headings' => headings, 'text' => text
      }
    end
  end
end
