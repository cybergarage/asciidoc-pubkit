# frozen_string_literal: true

module AsciidocPubkit
  class Rules
    INLINE = /`[^`\n]*`|\+\+\+.*?\+\+\+|\+\+[^\n]*?\+\+|(?<!\w)\+[^+\n]+\+|「[^」\n]*」|『[^』\n]*』|\{[^}\n]+\}|<<[^>\n]+>>|\[\[[^\]\n]+\]\]|(?:link|xref|image|footnote|pass):[^\s\[]*\[[^\]\n]*\]|https?:\/\/[^\s\[\]<>]+(?:\[[^\]\n]*\])?/m
    TERMS = {
      'abstract-reference' => [%w[コスト 境界 契約 観点 土台 橋渡し 入口 記述 場所 意図], 'Identify the concrete referent, components, or measurable work. Keep established technical meanings.'],
      'weak-predicate' => [%w[利用します 整理します 扱います 示します 変わります 把握します 分けられます そろえます まとまっています 加えます 探します 到達しません 扱いません そろいます], 'Check whether the purpose, operation, or result is clear from the surrounding paragraph. Preserve negation and conditions.'],
      'vague-degree' => [%w[浅い 深い], 'Identify the concrete depth, level, scope, or comparison. Keep literal measurements and established technical meanings.'],
      'generic-framing' => [%w[重要なのは ポイントは 本章では ここでは まとめると], 'Check whether this framing adds useful scope or information instead of repeating the explanation.']
    }.freeze
    VERBS = {
      '扱う' => %w[扱う], '示す' => %w[示す], '変わる' => %w[変わる],
      '分ける' => %w[分ける], 'そろえる' => %w[そろえる 揃える],
      'まとまる' => %w[まとまる 纏まる], '加える' => %w[加える],
      '探す' => %w[探す], 'そろう' => %w[そろう 揃う]
    }.freeze
    SAHEN = %w[利用 整理 把握 到達].freeze

    def self.mask(text)
      # Keep character offsets stable while excluding common inline constructs.
      text.gsub(INLINE) { |match| match.gsub(/[^\n]/, ' ') }
    end

    def self.scan(paragraphs, settings, tokenizer: nil)
      findings = []
      if settings.fetch('tokenizer', 'mecab') == 'mecab'
        tokenizer ||= Morphology.new(settings)
      end
      token_groups = tokenizer ? tokenize_paragraphs(paragraphs, tokenizer) : []
      paragraphs.each_with_index do |paragraph, index|
        text = mask(paragraph.fetch('text'))
        scan_morphemes(findings, paragraph, text, token_groups[index], settings) if tokenizer
        TERMS.each do |rule, (terms, question)|
          next if tokenizer && rule != 'generic-framing'
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

    def self.scan_morphemes(findings, paragraph, text, tokens, settings)
      tokens.each_with_index do |token, index|
        next if token['unknown']
        lemma = token['lemma']
        rule = nil
        finish_index = index
        if token['pos'] == '名詞' && TERMS['abstract-reference'][0].include?(lemma)
          rule = 'abstract-reference'
        elsif token['pos'] == '形容詞' && TERMS['vague-degree'][0].include?(lemma)
          rule = 'vague-degree'
          finish_index = predicate_end(tokens, index, text)
        elsif token['pos'] == '動詞' && (entry = VERBS.find { |_canonical, forms| forms.include?(lemma) })
          lemma = entry[0]
          rule = 'weak-predicate'
          finish_index = predicate_end(tokens, index, text)
        elsif token['pos'] == '名詞' && token['pos_detail'] == 'サ変接続' && SAHEN.include?(lemma)
          following = tokens[index + 1]
          next unless following && following['pos'] == '動詞' && following['lemma'] == 'する' && adjacent?(token, following, text)
          lemma += 'する'
          rule = 'weak-predicate'
          finish_index = predicate_end(tokens, index + 1, text)
        end
        next unless rule
        members = tokens[index..finish_index]
        negative = members.any? { |member| member['pos'] == '助動詞' && %w[ない ぬ ん].include?(member['lemma']) }
        next if lemma == '到達する' && !negative
        surface = text[token['offset']...tokens[finish_index]['end_offset']]
        allows = settings.fetch('allows')
        next if [lemma, token['lemma'], surface, surface + '。'].any? { |form| allows.include?(form) }
        add(findings, paragraph, text, token['offset'], surface, rule, 'hint', TERMS.fetch(rule)[1])
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
