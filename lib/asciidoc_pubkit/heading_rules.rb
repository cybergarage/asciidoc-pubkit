# frozen_string_literal: true

module AsciidocPubkit
  class HeadingRuleSet
    KEYS = %w[schema_version terms fixed_titles duplicate_siblings style].freeze

    def self.default_path(language)
      Language.validate!(language, operation: 'review')
      File.expand_path("../../data/heading-rules.#{language}.yml", __dir__)
    end

    def self.load(path)
      validate(YAML.safe_load(AsciidocPubkit.read_text(path), permitted_classes: [], aliases: false))
    rescue Psych::Exception => e
      raise Error, "Invalid heading rule YAML in #{path}: #{e.message}"
    end

    def self.validate(data)
      RuleSet.mapping(data, KEYS, 'Heading rule set')
      raise Error, 'Heading rule schema_version must be integer 1.' unless data['schema_version'].is_a?(Integer) && data['schema_version'] == 1
      raise Error, 'Heading terms must be a mapping.' unless data['terms'].is_a?(Hash)
      data['terms'].each do |name, entry|
        raise Error, 'Heading rule names must be nonempty strings.' unless name.is_a?(String) && !name.strip.empty?
        RuleSet.mapping(entry, %w[terms question], "Heading rule #{name}")
        RuleSet.strings(entry['terms'], "Heading rule #{name}.terms")
        unless entry['question'].is_a?(String) && !entry['question'].strip.empty?
          raise Error, "Heading rule #{name}.question must be a nonempty string."
        end
      end
      RuleSet.strings(data['fixed_titles'], 'Heading fixed_titles')
      unless [true, false].include?(data['duplicate_siblings'])
        raise Error, 'Heading duplicate_siblings must be boolean.'
      end
      raise Error, 'Heading style must be mixed, nominal, or action.' unless %w[mixed nominal action].include?(data['style'])
      data
    end
  end

  class HeadingRules
    def self.scan(headings, settings, tokenizer: nil)
      rules = HeadingRuleSet.validate(settings.fetch('heading_rules'))
      tokenizer ||= Morphology.new(settings) if settings.fetch('tokenizer', 'mecab') == 'mecab'
      findings = []
      duplicates = headings.group_by { |h| [h['parent_index'], h['text']] }
      # Use the configured analyzer; never silently substitute literal analysis.
      tokens = tokenizer ? Rules.tokenize_paragraphs(headings, tokenizer) : []
      headings.each_with_index do |heading, index|
        next if rules['fixed_titles'].include?(heading['text'])
        text = Rules.mask(heading['text'])
        rules['terms'].each do |rule, entry|
          entry['terms'].each do |term|
            next if settings['allows'].include?(term)
            text.to_enum(:scan, Regexp.new(Regexp.escape(term))).each do
              match = Regexp.last_match
              next if term == '人' && !Rules.standalone_human?(text, match.begin(0))
              add(findings, heading, match.begin(0), term, rule, entry['question'])
            end
          end
        end
        settings['glossary'].each do |canonical, variants|
          variants.each do |variant|
            next if settings['allows'].include?(variant)
            text.to_enum(:scan, Regexp.new(Regexp.escape(variant))).each do
              match = Regexp.last_match
              add(findings, heading, match.begin(0), variant, 'heading-glossary-variant', "Check #{canonical.inspect} against the book's glossary. Preserve official names and identifiers.")
            end
          end
        end
        if rules['duplicate_siblings'] && duplicates.fetch([heading['parent_index'], heading['text']]).length > 1
          add(findings, heading, 0, heading['text'], 'heading-duplicate', 'Sibling headings have identical titles. Check whether their subjects can be distinguished; necessary repetition is valid.')
        end
        next if rules['style'] == 'mixed' || text.strip.empty?
        last = tokenizer && tokens[index].last
        # These are cues for review, not a complete grammatical classifier.
        action = last ? %w[動詞 助動詞].include?(last['pos']) : !!text.match(/(?:する|します|できる|ない|学ぶ|使う|選ぶ|読む|続ける|分ける|確かめる)\z/)
        next if (rules['style'] == 'action') == action
        add(findings, heading, 0, heading['text'], 'heading-style', "Check this heading against the book's #{rules['style']} preference. Preserve questions, principles and justified exceptions; do not change meaning to fit a template.")
      end
      findings
    end

    def self.add(findings, heading, offset, match, rule, question)
      findings << { 'id' => AsciidocPubkit.hash_text([heading['id'], rule, offset, match].join(':'))[0, 16],
                    'heading_id' => heading['id'], 'rule' => rule, 'severity' => 'hint',
                    'file' => heading['file'], 'line' => heading['line'],
                    'column' => heading['column'] + offset, 'match' => match, 'question' => question }
    end
  end
end
