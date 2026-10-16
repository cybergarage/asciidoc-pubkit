# frozen_string_literal: true

module AsciidocPubkit
  module Analysis
    def self.build(settings)
      case settings.fetch('tokenizer', 'mecab')
      when 'mecab' then Morphology.new(settings)
      when 'english-lexical' then EnglishLexical.new(settings)
      when 'literal' then settings['language'] == 'en' ? EnglishLexical.new(settings) : nil
      else raise Error, "Unsupported analysis backend: #{settings['tokenizer'].inspect}."
      end
    end

    def self.identity(tokenizer)
      tokenizer ? tokenizer.identity : { 'engine' => 'literal' }
    end
  end
end
