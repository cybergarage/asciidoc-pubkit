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
