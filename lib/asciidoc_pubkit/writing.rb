# frozen_string_literal: true

module AsciidocPubkit
  module Writing
    DATA_ROOT = File.expand_path('../../data/writing', __dir__)

    def self.criteria(language = Language::DEFAULT)
      Language.validate!(language, operation: 'writing')
      AsciidocPubkit.read_text(File.join(DATA_ROOT, language, 'criteria.md'))
    end

    def self.prompt_criteria(language = Language::DEFAULT)
      criteria(language).sub(/\A# [^\n]+\n\n/, '').gsub(/^## /, '### ')
    end

    def self.prompt(language = Language::DEFAULT)
      guide = prompt_criteria(language)
      <<~TEXT
        # Japanese technical writing prompt

        Language: #{language}

        Write Japanese technical prose for the user's assigned work. Read the applicable project instructions, source evidence, and established voice before writing. Follow the user's scope and the book's format; this prompt does not authorize edits or publication.

        Use the shared criteria below to plan and revise whole paragraphs. Treat examples and search terms as context-dependent review cues, not banned words or fixed templates. State technical claims only to the extent supported by the available evidence. Keep book-specific style choices with the book.

        ## Shared prose criteria

        #{guide.rstrip}
      TEXT
    end
  end
end
