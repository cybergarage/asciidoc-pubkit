# frozen_string_literal: true

module AsciidocPubkit
  class Rules
    INLINE = /`[^`\n]*`|\+\+\+.*?\+\+\+|\+\+[^\n]*?\+\+|(?<!\w)\+[^+\n]+\+|「[^」\n]*」|『[^』\n]*』|\{[^}\n]+\}|<<[^>\n]+>>|\[\[[^\]\n]+\]\]|(?:link|xref|image|footnote|pass):[^\s\[]*\[[^\]\n]*\]|https?:\/\/[^\s\[\]<>]+(?:\[[^\]\n]*\])?/m
    TERMS = {
      'abstract-reference' => [%w[コスト 境界 契約 観点 土台 橋渡し], 'Identify the concrete referent, components, or measurable work. Keep established technical meanings.'],
      'weak-predicate' => [%w[利用します 整理します 扱います 示します], 'Check whether the purpose, operation, or result is clear from the surrounding paragraph.'],
      'generic-framing' => [%w[重要なのは ポイントは 本章では ここでは まとめると], 'Check whether this framing adds useful scope or information instead of repeating the explanation.']
    }.freeze

    def self.mask(text)
      # Keep character offsets stable while excluding common inline constructs.
      text.gsub(INLINE) { |match| match.gsub(/[^\n]/, ' ') }
    end

    def self.scan(paragraphs, settings)
      findings = []
      paragraphs.each do |paragraph|
        text = mask(paragraph.fetch('text'))
        TERMS.each do |rule, (terms, question)|
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
