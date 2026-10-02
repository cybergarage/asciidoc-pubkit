# frozen_string_literal: true

require 'minitest/autorun'
require 'asciidoc_pubkit'

class DefaultRulesTest < Minitest::Test
  EXPRESSIONS = %w[
    木 余白 明示選択 欠落理由 構成要素 部品 開発者 区別 単発 よいこと おそれ 準備 別枠 祖先 子孫 予算
    別の 別に 空の 別々に 返す 分けて
    決まります 記述できます 組み立てられます 意味しません 用意します 記述します
    わけではありません 組み合わせます 足りません 別です 区別します 区別できます 扱います
    もあります 把握します 置き換えます まとまっています 必要がありません 加えます 加わります
    ことだけで 返します 避けられます 到達しません 求めます 証拠にはできません 送れます
    おそれがあります 選びます 変わります 分けません 同じものではありません ではありません
    読みます 目安です 付けます 残します 持ちます 決まるわけではありません 表します
    終えられます 消しません 調べます 作ります 抜けられます 調べられます 解消する
    分けています 証明するものではありません 権限にはなりません 方式ではありません
    方式にはしません ことはしません ことではありません 解消したことにはしません
    継続できるわけではありません 代用にしません にはしません 分けて扱います 混同しません
    分けて決めます 捉えます 表してはいません 選択を分ける 処理ではありません 書きます
    混ぜません 利用するわけではありません 推測してはいけません 表しません
    判断するものではありません 意味ではありません 追えます 自動修正されるわけではありません
    証拠にはなりません という関係でもありません 用意されるわけではありません
  ].freeze

  def scan(text, mode, allows: [])
    paragraph = { 'id' => 'sample', 'file' => '/example.adoc', 'line' => 1, 'text' => text }
    settings = { 'tokenizer' => mode, 'allows' => allows, 'glossary' => {}, 'style' => 'preserve' }
    tokenizer = mode == 'mecab' ? (@tokenizer ||= AsciidocPubkit::Morphology.new(settings)) : nil
    AsciidocPubkit::Rules.scan([paragraph], settings, tokenizer: tokenizer)
  end

  %w[mecab literal].each do |mode|
    define_method("test_technical_wording_candidates_in_#{mode}") do
      examples = {
        '木' => 'abstract-reference',
        '構築入口' => 'contextual-phrase',
        '実装の読解' => 'contextual-phrase',
        'エラーを回収する' => 'contextual-phrase',
        '介入パターン' => 'contextual-phrase',
        'ツールを呼ぶ' => 'contextual-phrase',
        '責務を持つ' => 'contextual-phrase',
        '指示を読み取る' => 'contextual-phrase',
        '設定を書く' => 'contextual-phrase',
        '値を拾う' => 'contextual-phrase',
        '切り出す合図です' => 'contextual-phrase',
        '設定を書きます' => 'weak-predicate',
        '無効化したりできます' => 'contextual-phrase',
        '提供することが前提です' => 'contextual-phrase',
        '宣言することは別です' => 'contextual-phrase',
        'そうではありません' => 'contextual-phrase',
        '構造が見えてきます' => 'generic-framing',
        '理由がここにあります' => 'generic-framing',
        '設計の肝です' => 'generic-framing'
      }
      examples.each do |phrase, rule|
        findings = scan("😀#{phrase}。", mode).select { |f| f['rule'] == rule }
        assert_equal 1, findings.length, "#{mode}: #{phrase}"
        finding = findings.first
        assert_equal finding['match'], "😀#{phrase}。"[finding['column'] - 1, finding['match'].length]
        assert_empty scan("`#{phrase}`。「#{phrase}」。", mode)
      end
      %w[エラーを回収します ツールを呼びます 指示を読み取ります 値を拾います].each do |phrase|
        assert_equal [phrase], scan(phrase + '。', mode).map { |f| f['match'] }
        assert_empty scan(phrase + '。', mode, allows: [phrase])
      end
      assert_equal ['構築入口'], scan('構築入口。', mode).map { |f| f['match'] }
      assert_empty scan('構築入口。', mode, allows: ['構築入口'])
      assert_empty scan('人を呼ぶ。落ち葉を拾う。信号を読み取る。', mode)
    end

    define_method("test_metaphor_corpus_in_#{mode}") do
      corpus = JSON.parse(File.read(File.join(__dir__, 'fixtures/prose_evaluation.ja.json')))
      corpus.fetch('detection_cases').each do |entry|
        findings = scan(entry.fetch('text'), mode).select { |f| f['rule'] == 'contextual-phrase' }
        # Other contextual cues remain independent of metaphor coverage.
        metaphors = findings.select { |f| f['match'].match?(/地味に効|静かに壊れ|時間を溶か|側に倒/) }
        assert_equal entry.fetch('metaphor_matches'), metaphors.map { |f| f['match'] }, entry.fetch('id')
        metaphors.each do |finding|
          assert_equal finding['match'], entry.fetch('text')[finding['column'] - 1, finding['match'].length]
        end
      end
    end

    define_method("test_metaphor_allow_lists_and_inline_exclusions_in_#{mode}") do
      phrase = '静かに壊れます'
      text = "😀失効すると#{phrase}。\n再実行すると#{phrase}。"
      findings = scan(text, mode).select { |f| f['match'] == phrase }
      assert_equal [[1, 7], [2, 7]], findings.map { |f| f.values_at('line', 'column') }
      assert_empty scan(text, mode, allows: [phrase]).select { |f| f['match'] == phrase }
      assert_empty scan("`#{phrase}`。「#{phrase}」。link:https://example.com[#{phrase}]。", mode)
    end

    define_method("test_requested_expressions_are_covered_in_#{mode}") do
      EXPRESSIONS.each do |expression|
        findings = scan(expression + '。', mode)
        refute_empty findings, "#{mode}: #{expression}"
        findings.each do |finding|
          assert_equal finding['match'], expression[finding['column'] - 1, finding['match'].length]
        end
      end
    end

    define_method("test_nested_phrases_and_allow_lists_in_#{mode}") do
      %w[わけではありません であることだけでは].each do |phrase|
        assert_equal [phrase], scan(phrase + '。', mode).map { |f| f['match'] }
        assert_empty scan(phrase + '。', mode, allows: [phrase])
      end
      assert_equal %w[わけではありません ではありません],
                   scan('わけではありません。ではありません。', mode).map { |f| f['match'] }
      assert_equal ['ではありません'],
                   scan('わけではありません。ではありません。', mode, allows: ['わけではありません']).map { |f| f['match'] }
      assert_empty scan('`木`。「明示選択」。`記述できます`。', mode)
      assert_equal ['contextual-phrase'], scan('欠落理由。', mode).map { |f| f['rule'] }
    end

    define_method("test_generic_recaps_are_review_candidates_in_#{mode}") do
      text = 'このように、処理します。要するに、結果を返します。'
      matches = ->(allows) { scan(text, mode, allows: allows).select { |f| f['rule'] == 'generic-framing' }.map { |f| f['match'] } }
      assert_equal %w[このように 要するに], matches.call([])
      assert_equal ['要するに'], matches.call(['このように'])
    end
  end

  def test_nouns_and_sahen_potential_predicates_are_distinct
    findings = scan('記述。区別。記述できます。区別しません。', 'mecab')
    assert_equal %w[abstract-reference abstract-reference weak-predicate weak-predicate], findings.map { |f| f['rule'] }
    assert_equal %w[記述 区別 記述する 区別する], findings.map { |f| f['lemma'] }
    assert_equal %w[記述 区別 記述できます 区別しません], findings.map { |f| f['match'] }
    assert findings.last['negative']
    assert_empty scan('区別しません。', 'mecab', allows: ['区別する'])
  end

  def test_literal_predicates_do_not_duplicate_their_nouns_or_shorter_forms
    %w[記述できます 区別します 分けています].each do |expression|
      assert_equal [expression], scan(expression + '。', 'literal').map { |f| f['match'] }
    end
  end

  def test_default_term_lists_do_not_repeat_terms_across_categories
    terms = AsciidocPubkit::RuleSet.load['terms'].values.flat_map { |entry| entry['terms'] }
    assert_equal terms.uniq, terms
  end
end
