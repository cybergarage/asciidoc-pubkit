# frozen_string_literal: true

module AsciidocPubkit
  # Lexical tokens retain source character offsets; no normalized text is written.
  class EnglishLexical
    TOKEN = /[\p{L}\p{M}\p{N}_]+(?:['’\-‐‑.][\p{L}\p{M}\p{N}_]+)*/
    VERSION = '1'

    def initialize(settings = {})
      @settings = settings
    end

    def identity
      { 'engine' => @settings.fetch('tokenizer', 'english-lexical'),
        'language' => 'en', 'version' => VERSION, 'boundary_policy' => 'unicode-lexical-v1' }
    end

    def tokenize(text)
      text.to_enum(:scan, TOKEN).map do
        m = Regexp.last_match
        { 'surface' => m[0], 'offset' => m.begin(0), 'end_offset' => m.end(0) }
      end
    end
  end

  module EnglishRuleSet
    ROOT_KEYS = %w[schema_version language rules].freeze
    RULE_KEYS = %w[id match terms case boundary severity question exceptions].freeze

    def self.validate(data, headings: false)
      RuleSet.mapping(data, ROOT_KEYS + (headings ? %w[fixed_titles duplicate_siblings style] : []), 'English rule set')
      raise Error, 'English rules require schema_version 2 and language en.' unless data['schema_version'] == 2 && data['schema_version'].is_a?(Integer) && data['language'] == 'en'
      raise Error, 'English rules must be an array.' unless data['rules'].is_a?(Array)
      ids = []
      data['rules'].each do |rule|
        RuleSet.mapping(rule, RULE_KEYS, 'English rule')
        raise Error, 'English rule id must be a stable lowercase identifier.' unless rule['id'].is_a?(String) && rule['id'].match?(/\A[a-z][a-z0-9-]*\z/)
        ids << rule['id']
        raise Error, 'English match must be phrase or repeated-word.' unless %w[phrase repeated-word].include?(rule['match'])
        raise Error, 'English case must be sensitive or insensitive.' unless %w[sensitive insensitive].include?(rule['case'])
        raise Error, 'English boundary must be lexical.' unless rule['boundary'] == 'lexical'
        raise Error, 'English severity must be hint.' unless rule['severity'] == 'hint'
        raise Error, 'English question must be nonempty text.' unless rule['question'].is_a?(String) && !rule['question'].strip.empty?
        %w[terms exceptions].each { |key| RuleSet.strings(rule[key], "English #{key}") }
        raise Error, 'Phrase rules require terms; repeated-word rules require empty terms.' unless (rule['match'] == 'phrase' && !rule['terms'].empty?) || (rule['match'] == 'repeated-word' && rule['terms'].empty?)
        (rule['terms'] + rule['exceptions']).each do |term|
          tokens = EnglishLexical.new.tokenize(term)
          reconstructed = tokens.map { |t| t['surface'] }.join(' ')
          raise Error, 'English terms and exceptions must be lexical tokens separated by whitespace.' unless !tokens.empty? && reconstructed == term.split.join(' ')
        end
      end
      raise Error, 'English rule IDs must be unique.' unless ids.uniq == ids
      if headings
        RuleSet.strings(data['fixed_titles'], 'English fixed_titles')
        raise Error, 'English duplicate_siblings must be boolean.' unless [true, false].include?(data['duplicate_siblings'])
        raise Error, 'English heading style currently supports mixed only.' unless data['style'] == 'mixed'
      end
      data
    end
  end

  module EnglishRules
    def self.scan(entries, settings, tokenizer: nil, headings: false)
      data = EnglishRuleSet.validate(settings.fetch(headings ? 'heading_rules' : 'rules'), headings: headings)
      tokenizer ||= EnglishLexical.new(settings)
      findings = []
      duplicates = entries.group_by { |entry| [entry['parent_index'], entry['text']] } if headings
      entries.each do |entry|
        next if headings && data['fixed_titles'].include?(entry['text'])
        text = entry.fetch('text')
        tokens = tokenizer.tokenize(Rules.mask(text))
        emit = lambda do |first, last, id, question|
          surface = text[first['offset']...last['end_offset']]
          next if settings.fetch('allows', []).include?(surface)
          if headings
            HeadingRules.add(findings, entry, first['offset'], surface, id, question)
          else
            Rules.add(findings, entry, text, first['offset'], surface, id, 'hint', question)
          end
        end
        data['rules'].each do |rule|
          insensitive = rule['case'] == 'insensitive'
          fold = ->(word) { insensitive ? word.downcase : word }
          exceptions = rule['exceptions'].map { |s| s.split.map(&fold) }
          patterns = rule['terms'].map { |s| s.split.map(&fold) }
          if rule['match'] == 'repeated-word'
            tokens.each_cons(2) do |pair|
              words = pair.map { |t| fold.call(t['surface']) }
              next unless words[0] == words[1] && !exceptions.include?(words) && contiguous?(text, pair)
              emit.call(pair.first, pair.last, rule['id'], rule['question'])
            end
          else
            patterns.each do |pattern|
              next if settings.fetch('allows', []).any? { |s| s.split.map(&fold) == pattern }
              tokens.each_cons(pattern.length) do |group|
                words = group.map { |t| fold.call(t['surface']) }
                next unless words == pattern && !exceptions.include?(words) && contiguous?(text, group)
                emit.call(group.first, group.last, rule['id'], rule['question'])
              end
            end
          end
        end
        settings.fetch('glossary', {}).each do |canonical, variants|
          variants.each do |variant|
            pattern = tokenizer.tokenize(variant).map { |t| t['surface'] }
            next if pattern.empty? || pattern.join(' ') != variant.split.join(' ')
            tokens.each_cons(pattern.length) do |group|
              next unless group.map { |t| t['surface'] } == pattern && contiguous?(text, group)
              emit.call(group.first, group.last, headings ? 'heading-glossary-variant' : 'glossary-variant', "Compare #{canonical.inspect} with this variant in context; preserve official names and distinct concepts.")
            end
          end
        end
        if headings && data['duplicate_siblings'] && duplicates.fetch([entry['parent_index'], text]).length > 1
          HeadingRules.add(findings, entry, 0, text, 'heading-duplicate', 'Compare sibling subjects; necessary repeated titles may be retained.')
        end
      end
      findings.uniq { |f| f['id'] }
    end

    def self.contiguous?(text, tokens)
      tokens.each_cons(2).all? { |a, b| text[a['end_offset']...b['offset']].match?(/\A[[:space:]]+\z/) }
    end
  end
end
