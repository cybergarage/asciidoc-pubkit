# frozen_string_literal: true

require 'open3'

module AsciidocPubkit
  # An adapter for the MeCab CLI with UTF-8 IPADIC features. No shell is used.
  class Morphology
    attr_reader :identity

    def initialize(settings)
      @command = settings.fetch('mecab_command', 'mecab')
      @args = []
      dictionary = settings['mecab_dictionary']
      @args += ['--dicdir', dictionary] if dictionary
      version = execute(['--version']).strip
      info = execute(@args + ['--dictionary-info'])
      charsets = info.scan(/^charset:\s*(\S+)/).flatten
      unless !charsets.empty? && charsets.all? { |charset| %w[utf8 utf-8].include?(charset.downcase) }
        raise Error, 'MeCab requires a UTF-8 IPADIC dictionary. Set review.mecab_dictionary to its directory.'
      end
      files = info.scan(/^filename:\s*(.+)$/).flatten.map(&:strip)
      raise Error, 'MeCab did not report a dictionary filename.' if files.empty?
      fingerprints = files.flat_map do |file|
        [file, *%w[unk.dic matrix.bin char.bin dicrc].map { |name| File.join(File.dirname(file), name) }]
      end.uniq.to_h do |file|
        raise Error, "MeCab dictionary component is missing: #{file}" unless File.file?(file)
        [File.realpath(file), Digest::SHA256.file(file).hexdigest]
      end
      @identity = { 'engine' => 'mecab', 'version' => version, 'feature_schema' => 'ipadic', 'dictionary_files' => fingerprints }
      probe = tokenize('食べました。浅かった。')
      unless probe.any? { |t| t['lemma'] == '食べる' && t['pos'] == '動詞' } &&
             probe.any? { |t| t['lemma'] == '浅い' && t['pos'] == '形容詞' }
        raise Error, 'Unsupported MeCab dictionary. Use UTF-8 IPADIC; UniDic and other feature schemas are not supported.'
      end
    end

    def tokenize(text)
      return [] if text.empty?
      raise Error, 'MeCab input contains a NUL character.' if text.include?("\0")
      format = '%m\t%H\t%s\n'
      buffer = [8192, text.lines.map(&:bytesize).max.to_i + 1].max
      output = execute(@args + ['--node-format', format, '--unk-format', format,
                                '--bos-format', '', '--eos-format', '', '--input-buffer-size', buffer.to_s], text)
      cursor = 0
      tokens = output.lines.filter_map do |line|
        surface, feature, kind = line.chomp.split("\t", 3)
        raise Error, 'MeCab returned an invalid token record.' unless surface && feature && kind && !surface.empty?
        offset = text.index(surface, cursor)
        unless offset && text[cursor...offset].match?(/\A[[:space:]]*\z/)
          raise Error, 'MeCab token positions could not be aligned with the source text.'
        end
        cursor = offset + surface.length
        fields = feature.split(',', -1)
        if kind == '0' && fields.length != 9
          raise Error, 'Unsupported MeCab feature schema. A UTF-8 IPADIC dictionary is required.'
        end
        {
          'surface' => surface, 'offset' => offset, 'end_offset' => cursor,
          'pos' => fields[0], 'pos_detail' => fields[1],
          'lemma' => fields[6] == '*' ? surface : fields[6], 'unknown' => kind != '0'
        }
      end
      unless text[cursor..].match?(/\A[[:space:]]*\z/)
        raise Error, 'MeCab did not analyze the entire source text.'
      end
      tokens
    end

    private

    def execute(args, input = '')
      stdout, stderr, status = Open3.capture3(@command, *args, stdin_data: input)
      # MeCab 0.996 returns 1 after successfully printing dictionary information.
      dictionary_info = args.include?('--dictionary-info') && status.exitstatus == 1 && stderr.empty? && stdout.start_with?('filename:')
      raise Error, "MeCab failed (exit #{status.exitstatus}): #{(stderr.empty? ? stdout : stderr).strip[0, 1000]}" unless status.success? || dictionary_info
      stdout.force_encoding(Encoding::UTF_8)
      raise Error, 'MeCab output is not UTF-8.' unless stdout.valid_encoding?
      stdout
    rescue Errno::ENOENT
      raise Error, 'MeCab is not installed. Install MeCab and UTF-8 IPADIC (macOS: brew install mecab mecab-ipadic), or explicitly use --tokenizer literal for limited phrase matching.'
    end
  end
end
