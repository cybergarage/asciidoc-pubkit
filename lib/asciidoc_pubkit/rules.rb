# frozen_string_literal: true

module AsciidocPubkit
  class Rules
    INLINE = /`[^`\n]*`|\+\+\+.*?\+\+\+|\+\+[^\n]*?\+\+|(?<!\w)\+[^+\n]+\+|「[^」\n]*」|『[^』\n]*』|\{[^}\n]+\}|<<[^>\n]+>>|\[\[[^\]\n]+\]\]|(?:link|xref|image|footnote|pass):[^\s\[]*\[[^\]\n]*\]|https?:\/\/[^\s\[\]<>]+(?:\[[^\]\n]*\])?/m
    def self.mask(text)
      # Keep character offsets stable while excluding common inline constructs.
      text.gsub(INLINE) { |match| match.gsub(/[^\n]/, ' ') }
    end

    def self.scan(paragraphs, settings, tokenizer: nil)
      rules = RuleSet.validate(settings.fetch('rules') { RuleSet.load })
      terms = rules.fetch('terms').transform_values { |entry| entry.values_at('terms', 'question') }
      findings = []
      if settings.fetch('tokenizer', 'mecab') == 'mecab'
        tokenizer ||= Morphology.new(settings)
      end
      token_groups = tokenizer ? tokenize_paragraphs(paragraphs, tokenizer) : []
      paragraphs.each_with_index do |paragraph, index|
        text = mask(paragraph.fetch('text'))
        scan_morphemes(findings, paragraph, text, token_groups[index], settings, rules, terms) if tokenizer
        terms.each do |rule, (terms, question)|
          next if tokenizer && !%w[generic-framing contextual-phrase].include?(rule)
          terms.each do |term|
            next if settings.fetch('allows').include?(term)
            find_term(findings, paragraph, text, term, rule, 'hint', question)
          end
        end
        settings.fetch('glossary').each do |canonical, variants|
          variants.each do |variant|
            find_term(findings, paragraph, text, variant, 'glossary-variant', 'warning', "Use #{canonical.inspect} when this variant refers to the same concept; preserve identifiers and quotations.")
          end
        end
        sentences = text.split(/[。！？]/).map(&:strip).reject(&:empty?)
        endings = sentences.map { |sentence| sentence[/(?:\p{Han}+(?:します|できます)|しています|されます|ません|です)\z/] }
        repeated = endings.each_cons(3).find { |items| items.first && items.uniq.one? }
        if repeated
          add(findings, paragraph, text, text.index(repeated.first), repeated.first, 'repeated-ending', 'info', 'Three consecutive sentences share an ending. Check rhythm without changing precise technical verbs.')
        end
        pattern = case settings.fetch('style')
                  when 'desu-masu' then /(?:である|だった|なのだ)(?=。|\z)/
                  when 'dearu' then /(?:です|ます|ません)(?=。|\z)/
                  end
        if pattern
          text.to_enum(:scan, pattern).each do
            match = Regexp.last_match
            add(findings, paragraph, text, match.begin(0), match[0], 'style-candidate', 'hint', 'Check this sentence ending against the configured prose style. Preserve quotations and intentional exceptions.')
          end
        end
      end
      findings
    end

    def self.tokenize_paragraphs(paragraphs, tokenizer)
      text = +''
      spans = paragraphs.map do |paragraph|
        start = text.length
        text << mask(paragraph['text'])
        finish = text.length
        text << "\n"
        [start, finish]
      end
      tokens = tokenizer.tokenize(text)
      cursor = 0
      spans.map do |start, finish|
        group = []
        while cursor < tokens.length && tokens[cursor]['offset'] < finish
          token = tokens[cursor]
          raise Error, 'A morphological token crossed a paragraph boundary.' if token['offset'] < start || token['end_offset'] > finish
          group << token.merge('offset' => token['offset'] - start, 'end_offset' => token['end_offset'] - start)
          cursor += 1
        end
        group
      end
    end

    def self.scan_morphemes(findings, paragraph, text, tokens, settings, rules, terms)
      phrase_ranges = terms['contextual-phrase'][0].flat_map do |phrase|
        text.to_enum(:scan, Regexp.new(Regexp.escape(phrase))).map do
          match = Regexp.last_match
          match.begin(0)...match.end(0)
        end
      end
      tokens.each_with_index do |token, index|
        next if token['unknown'] || phrase_ranges.any? { |range| range.cover?(token['offset']) }
        lemma = token['lemma']
        rule = nil
        finish_index = index
        compound = rules.fetch('compound_nouns').find do |term|
          surface = +''
          cursor = index
          while (member = tokens[cursor]) && member['pos'] == '名詞' && !member['unknown']
            break if cursor > index && tokens[cursor - 1]['end_offset'] != member['offset']
            surface << member['surface']
            break unless term.start_with?(surface)
            if surface == term
              finish_index = cursor
              break
            end
            cursor += 1
          end
          surface == term
        end
        if compound
          lemma = compound
          rule = 'abstract-reference'
        elsif token['pos'] == '名詞' && terms['abstract-reference'][0].include?(lemma)
          rule = 'abstract-reference'
        elsif token['pos'] == '形容詞' && terms['vague-degree'][0].include?(lemma)
          rule = 'vague-degree'
          finish_index = predicate_end(tokens, index, text)
        elsif token['pos'] == '動詞' && (entry = rules.fetch('verbs').find { |_canonical, forms| forms.include?(lemma) })
          lemma = entry[0]
          rule = 'weak-predicate'
          finish_index = predicate_end(tokens, index, text)
        elsif token['pos'] == '名詞' && token['pos_detail'] == 'サ変接続' && rules.fetch('sahen').include?(lemma)
          following = tokens[index + 1]
          next unless following && following['pos'] == '動詞' && following['lemma'] == 'する' && adjacent?(token, following, text)
          lemma += 'する'
          rule = 'weak-predicate'
          finish_index = predicate_end(tokens, index + 1, text)
        end
        next unless rule
        members = tokens[index..finish_index]
        negative = members.any? { |member| member['pos'] == '助動詞' && %w[ない ぬ ん].include?(member['lemma']) }
        next if rules.fetch('negative_only').include?(lemma) && !negative
        surface = text[token['offset']...tokens[finish_index]['end_offset']]
        allows = settings.fetch('allows')
        next if [lemma, token['lemma'], surface, surface + '。'].any? { |form| allows.include?(form) }
        add(findings, paragraph, text, token['offset'], surface, rule, 'hint', terms.fetch(rule)[1])
        findings.last.merge!('lemma' => lemma, 'part_of_speech' => token['pos'], 'negative' => negative,
                             'detector' => 'mecab-ipadic')
      end
    end

    def self.adjacent?(left, right, text)
      text[left['end_offset']...right['offset']].match?(/\A\n?\z/)
    end

    def self.predicate_end(tokens, index, text)
      finish = index
      while (following = tokens[finish + 1]) && adjacent?(tokens[finish], following, text)
        auxiliary = following['pos'] == '助動詞'
        dependent_verb = following['pos'] == '動詞' && %w[非自立 接尾].include?(following['pos_detail'])
        connector = following['pos'] == '助詞' && following['pos_detail'] == '接続助詞' && %w[て で].include?(following['lemma'])
        break unless auxiliary || dependent_verb || connector
        finish += 1
      end
      finish
    end

    def self.find_term(findings, paragraph, text, term, rule, severity, question)
      text.to_enum(:scan, Regexp.new(Regexp.escape(term))).each do
        match = Regexp.last_match
        add(findings, paragraph, text, match.begin(0), term, rule, severity, question)
      end
    end

    def self.add(findings, paragraph, text, offset, match, rule, severity, question)
      prefix = text[0...offset]
      findings << {
        'id' => AsciidocPubkit.hash_text([paragraph['id'], rule, offset, match].join(':'))[0, 16],
        'paragraph_id' => paragraph['id'], 'rule' => rule, 'severity' => severity,
        'file' => paragraph['file'], 'line' => paragraph['line'] + prefix.count("\n"),
        'column' => (prefix.rindex("\n") ? prefix.length - prefix.rindex("\n") : prefix.length + 1),
        'match' => match, 'question' => question
      }
    end
  end
end
