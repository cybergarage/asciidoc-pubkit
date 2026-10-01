# frozen_string_literal: true

module AsciidocPubkit
  class Rules
    CONTEXTUAL_PREDICATES = { '地味に' => '効く', '静かに' => '壊れる',
                              '時間を' => '溶かす', '側に' => '倒す' }.freeze
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
        contextual = tokenizer ? contextual_predicates(text, token_groups[index], terms) : []
        scan_morphemes(findings, paragraph, text, token_groups[index], settings, rules, terms, contextual) if tokenizer
        scan_literal_terms(findings, paragraph, text, terms, settings, morphological: !!tokenizer, contextual: contextual)
        settings.fetch('glossary').each do |canonical, variants|
          variants.each do |variant|
            find_term(findings, paragraph, text, variant, 'glossary-variant', 'warning', "Use #{canonical.inspect} when this variant refers to the same concept; preserve identifiers and quotations.")
          end
        end
        endings = text.to_enum(:scan, /[^。！？]+/).filter_map do
          sentence = Regexp.last_match
          next if sentence[0].strip.empty?
          ending = sentence[0].match(/(\p{Han}+(?:します|できます)|しています|されます|ません|です)[[:space:]]*\z/)
          { 'match' => ending && ending[1], 'offset' => ending && sentence.begin(0) + ending.begin(1) }
        end
        repeated = endings.each_cons(3).find { |items| items.first['match'] && items.map { |item| item['match'] }.uniq.length == 1 }
        if repeated
          ending = repeated.last
          add(findings, paragraph, text, ending['offset'], ending['match'], 'repeated-ending', 'info', 'Three consecutive sentences share an ending. Check rhythm without changing precise technical verbs.')
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

    def self.contextual_predicates(text, tokens, terms)
      surfaces, question = terms.fetch('contextual-phrase')
      tokens.each_with_index.filter_map do |token, index|
        next if token['unknown'] || token['pos'] != '動詞' || token['pos_detail'] != '自立'
        pattern = CONTEXTUAL_PREDICATES.find do |prefix, lemma|
          surfaces.include?(prefix + lemma) && token['lemma'] == lemma &&
            token['offset'] >= prefix.length && text[token['offset'] - prefix.length...token['offset']] == prefix
        end
        next unless pattern
        prefix, lemma = pattern
        start = token['offset'] - prefix.length
        prefix_index = tokens[0...index].rindex { |member| member['offset'] == start }
        next unless prefix_index
        members = tokens[prefix_index..predicate_end(tokens, index, text)]
        next if members.any? { |member| member['unknown'] }
        finish = members.last['end_offset']
        metadata = { 'lemma' => prefix + lemma, 'part_of_speech' => '動詞',
                     'negative' => negative?(members), 'detector' => 'mecab-ipadic' }
        [start, finish, text[start...finish], 'contextual-phrase', question, metadata]
      end
    end

    def self.negative?(members)
      members.any? { |member| member['pos'] == '助動詞' && %w[ない ぬ ん].include?(member['lemma']) }
    end

    def self.scan_morphemes(findings, paragraph, text, tokens, settings, rules, terms, contextual = [])
      phrase_ranges = terms['contextual-phrase'][0].flat_map do |phrase|
        text.to_enum(:scan, Regexp.new(Regexp.escape(phrase))).map do
          match = Regexp.last_match
          match.begin(0)...match.end(0)
        end
      end
      phrase_ranges.concat(contextual.map { |start, finish, *_| start...finish })
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
        elsif token['pos'] == '名詞' && token['pos_detail'] == 'サ変接続' && rules.fetch('sahen').include?(lemma) &&
              (following = tokens[index + 1]) && following['pos'] == '動詞' &&
              %w[する できる].include?(following['lemma']) && adjacent?(token, following, text)
          lemma += 'する'
          rule = 'weak-predicate'
          finish_index = predicate_end(tokens, index + 1, text)
        elsif token['pos'] == '名詞' && terms['abstract-reference'][0].include?(lemma)
          rule = 'abstract-reference'
        elsif token['pos'] == '形容詞' && terms['vague-degree'][0].include?(lemma)
          rule = 'vague-degree'
          finish_index = predicate_end(tokens, index, text)
        elsif token['pos'] == '動詞' && (entry = rules.fetch('verbs').find { |_canonical, forms| forms.include?(lemma) })
          lemma = entry[0]
          rule = 'weak-predicate'
          finish_index = predicate_end(tokens, index, text)
        end
        next unless rule
        members = tokens[index..finish_index]
        negative = negative?(members)
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

    def self.scan_literal_terms(findings, paragraph, text, terms, settings, morphological:, contextual: [])
      candidates = contextual.dup
      terms.each do |rule, (surfaces, question)|
        next if morphological && !%w[generic-framing contextual-phrase].include?(rule)
        surfaces.each do |surface|
          text.to_enum(:scan, Regexp.new(Regexp.escape(surface))).each do
            match = Regexp.last_match
            next if contextual.any? { |start, finish, _, candidate_rule, *_| start == match.begin(0) && finish == match.end(0) && candidate_rule == rule }
            candidates << [match.begin(0), match.end(0), surface, rule, question]
          end
        end
      end
      # Keep the most specific phrase, including when it is explicitly allowed.
      candidates.each do |start, finish, surface, rule, question, metadata|
        next if candidates.any? { |left, right, *_| left <= start && right >= finish && right - left > finish - start }
        forms = metadata ? [surface, surface + '。', metadata['lemma']] : [surface]
        next if forms.any? { |form| settings.fetch('allows').include?(form) }
        add(findings, paragraph, text, start, surface, rule, 'hint', question)
        findings.last.merge!(metadata) if metadata
      end
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
