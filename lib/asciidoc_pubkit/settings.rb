# frozen_string_literal: true

module AsciidocPubkit
  class Settings
    attr_reader :data, :path

    def initialize(entry, options)
      @path = options[:config] && File.expand_path(options[:config])
      unless @path
        directory = File.dirname(File.expand_path(entry))
        loop do
          candidate = File.join(directory, '.asciidoc-pubkit.yml')
          if File.file?(candidate)
            @path = candidate
            break
          end
          parent = File.dirname(directory)
          break if parent == directory
          directory = parent
        end
      end
      config = @path ? read_yaml(@path) : {}
      reject_keys(config, ['review'], 'configuration')
      review = config.fetch('review', {})
      raise Error, 'review must be a mapping.' unless review.is_a?(Hash)
      reject_keys(review, %w[language style glossary exclude allows attributes base_dir tokenizer mecab_command mecab_dictionary], 'review')
      raise Error, 'attributes must be a mapping.' unless review.fetch('attributes', {}).is_a?(Hash)
      %w[base_dir glossary mecab_command mecab_dictionary].each do |key|
        raise Error, "#{key} must be a nonempty path string." if review.key?(key) && (!review[key].is_a?(String) || review[key].empty?)
      end
      base = @path ? File.dirname(@path) : File.dirname(File.expand_path(entry))
      @data = {
        'language' => options[:language] || review.fetch('language', 'ja'),
        'style' => options[:style] || review.fetch('style', 'preserve'),
        'exclude' => review.fetch('exclude', []),
        'allows' => review.fetch('allows', []),
        'tokenizer' => options[:tokenizer] || review.fetch('tokenizer', 'mecab'),
        'mecab_command' => review.fetch('mecab_command', 'mecab'),
        'mecab_dictionary' => review['mecab_dictionary'] && File.expand_path(review['mecab_dictionary'], base),
        'attributes' => review.fetch('attributes', {}).merge(options.fetch(:attributes, {})),
        'base_dir' => File.expand_path(options[:base_dir] || review.fetch('base_dir', base), options[:base_dir] ? Dir.pwd : base),
        'glossary' => {}
      }
      raise Error, 'Only Japanese (ja) is supported in this release.' unless @data['language'] == 'ja'
      raise Error, 'tokenizer must be mecab or literal.' unless %w[mecab literal].include?(@data['tokenizer'])
      raise Error, 'style must be preserve, desu-masu, or dearu.' unless %w[preserve desu-masu dearu].include?(@data['style'])
      %w[exclude allows].each do |key|
        raise Error, "#{key} must be an array of strings." unless @data[key].is_a?(Array) && @data[key].all? { |v| v.is_a?(String) }
      end
      raise Error, 'attributes must map names to string, numeric, or boolean values.' unless @data['attributes'].is_a?(Hash) && @data['attributes'].all? { |k, v| k.is_a?(String) && [String, Integer, Float, TrueClass, FalseClass].any? { |t| v.is_a?(t) } }
      raise Error, 'Remote includes are not supported.' if @data['attributes'].key?('allow-uri-read')
      if review['glossary']
        glossary = read_yaml(File.expand_path(review['glossary'], base))
        unless glossary.all? { |k, v| k.is_a?(String) && !k.empty? && v.is_a?(Array) && v.all? { |s| s.is_a?(String) && !s.empty? } }
          raise Error, 'The glossary must map canonical terms to arrays of nonempty variant strings.'
        end
        @data['glossary'] = glossary
      end
    end

    private

    def read_yaml(path)
      result = YAML.safe_load(AsciidocPubkit.read_text(path), permitted_classes: [], aliases: false) || {}
      raise Error, "Expected a YAML mapping: #{path}" unless result.is_a?(Hash)
      result
    rescue Psych::Exception => e
      raise Error, "Invalid YAML in #{path}: #{e.message}"
    end

    def reject_keys(mapping, allowed, label)
      unknown = mapping.keys - allowed
      raise Error, "Unknown #{label} keys: #{unknown.join(', ')}" unless unknown.empty?
    end
  end
end
