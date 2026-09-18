# frozen_string_literal: true

module AsciidocPubkit
  class RuleSet
    DEFAULT_PATH = File.expand_path('../../data/review-rules.ja.yml', __dir__)
    CATEGORIES = %w[abstract-reference weak-predicate vague-degree contextual-phrase generic-framing].freeze
    KEYS = %w[schema_version terms verbs sahen negative_only compound_nouns].freeze

    def self.load(path = DEFAULT_PATH)
      validate(YAML.safe_load(AsciidocPubkit.read_text(path), permitted_classes: [], aliases: false))
    rescue Psych::Exception => e
      raise Error, "Invalid rule YAML in #{path}: #{e.message}"
    end

    def self.mapping(value, keys, label)
      unless value.is_a?(Hash) && (value.keys - keys).empty? && (keys - value.keys).empty?
        raise Error, "#{label} must contain exactly these keys: #{keys.join(', ')}."
      end
    end

    def self.strings(value, label)
      unless value.is_a?(Array) && value.all? { |s| s.is_a?(String) && !s.strip.empty? } && value.uniq == value
        raise Error, "#{label} must be an array of unique nonempty strings."
      end
    end

    def self.validate(data)
      mapping(data, KEYS, 'Rule set')
      raise Error, 'Rule schema_version must be integer 1.' unless data['schema_version'].is_a?(Integer) && data['schema_version'] == 1
      mapping(data['terms'], CATEGORIES, 'Rule terms')
      data['terms'].each do |category, entry|
        mapping(entry, %w[terms question], category)
        strings(entry['terms'], "#{category}.terms")
        raise Error, "#{category}.question must be a nonempty string." unless entry['question'].is_a?(String) && !entry['question'].strip.empty?
      end
      verbs = data['verbs']
      raise Error, 'verbs must be a mapping of canonical forms to lemma arrays.' unless verbs.is_a?(Hash)
      verbs.each do |canonical, forms|
        raise Error, 'Verb canonical forms must be nonempty strings.' unless canonical.is_a?(String) && !canonical.strip.empty?
        strings(forms, "verbs.#{canonical}")
        raise Error, "verbs.#{canonical} must contain at least one lemma." if forms.empty?
      end
      aliases = verbs.values.flatten
      raise Error, 'Verb lemmas must have only one canonical form.' unless aliases.uniq == aliases
      %w[sahen negative_only compound_nouns].each { |key| strings(data[key], key) }
      canonical_forms = verbs.keys + data['sahen'].map { |noun| noun + 'する' }
      raise Error, 'negative_only must refer to configured canonical predicates.' unless (data['negative_only'] - canonical_forms).empty?
      raise Error, 'compound_nouns must also appear in abstract-reference terms.' unless (data['compound_nouns'] - data['terms']['abstract-reference']['terms']).empty?
      data
    end
  end
end
