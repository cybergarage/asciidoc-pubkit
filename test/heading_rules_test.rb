# frozen_string_literal: true

require 'minitest/autorun'
require 'asciidoc_pubkit'

class HeadingRulesTest < Minitest::Test
  def rules
    AsciidocPubkit::HeadingRuleSet.load(AsciidocPubkit::HeadingRuleSet.default_path('ja'))
  end

  def settings(custom = rules)
    { 'heading_rules' => custom, 'glossary' => {}, 'allows' => [], 'tokenizer' => 'literal' }
  end

  def heading(text, parent: 1, id: text)
    { 'id' => id, 'text' => text, 'parent_index' => parent,
      'file' => 'chapter.adoc', 'line' => 8, 'column' => 5 }
  end

  def test_human_actor_cues_in_both_modes_preserve_book_terms_and_exclusions
    %w[literal mecab].each do |mode|
      config = settings
      config['tokenizer'] = mode
      titles = ['人の確認を記録する', '人の介入を測る', '個人の記録', '人数と3人の作業', '人間の判断', '「人」の定義']
      found = AsciidocPubkit::HeadingRules.scan(titles.map { |t| heading(t) }, config)
      assert_equal ['人の確認を記録する', '人の介入を測る'], found.map { |f| f['heading_id'] }
      assert found.all? { |f| f['rule'] == 'heading-human-role' }
      assert_equal [8, 5], found.first.values_at('line', 'column')
      config['allows'] = ['人']
      assert_empty AsciidocPubkit::HeadingRules.scan([heading(titles.first)], config)
    end
  end

  def test_mixed_forms_are_valid_and_prose_rules_are_not_applied
    texts = ['構成要素', 'モデルを選び、接続する', '何を任せるか？', 'nullを返さない', '保存する前に確かめる', '境界と契約の整理']
    assert_empty AsciidocPubkit::HeadingRules.scan(texts.map { |t| heading(t) }, settings)
  end

  def test_unicode_positions_allow_lists_glossary_and_inline_masking
    config = settings
    config['glossary'] = { 'JavaScript' => ['Javascript'] }
    findings = AsciidocPubkit::HeadingRules.scan([heading('日本語とシームレスなJavascript')], config)
    promotion = findings.find { |f| f['rule'] == 'heading-promotion' }
    assert_equal 9, promotion['column']
    assert_equal 8, promotion['line']
    assert findings.any? { |f| f['rule'] == 'heading-glossary-variant' }
    config['allows'] = ['シームレス', 'Javascript']
    assert_empty AsciidocPubkit::HeadingRules.scan([heading('シームレスなJavascript')], config)
    config['allows'] = []
    assert_empty AsciidocPubkit::HeadingRules.scan([heading('「シームレス」と`Javascript`')], config)
  end

  def test_duplicate_check_is_local_to_siblings_and_respects_fixed_titles
    headings = [heading('設定', parent: 1), heading('設定', parent: 2), heading('参考文献'), heading('参考文献')]
    assert_empty AsciidocPubkit::HeadingRules.scan(headings, settings)
    headings << heading('設定', parent: 1, id: 'other')
    findings = AsciidocPubkit::HeadingRules.scan(headings, settings)
    assert_equal 2, findings.count { |f| f['rule'] == 'heading-duplicate' }
  end

  def test_book_style_preferences_are_advisory_in_mecab_and_literal_modes
    config = settings
    config['heading_rules']['style'] = 'nominal'
    targets = [heading('モデルを選ぶ'), heading('モデルの選択')]
    literal = AsciidocPubkit::HeadingRules.scan(targets, config)
    assert_equal ['モデルを選ぶ'], literal.map { |f| f['match'] }
    config['tokenizer'] = 'mecab'
    mecab = AsciidocPubkit::HeadingRules.scan(targets, config)
    assert_equal ['モデルを選ぶ'], mecab.map { |f| f['match'] }
    assert mecab.all? { |f| f['severity'] == 'hint' }
    config['heading_rules']['style'] = 'action'
    assert_equal ['モデルの選択'], AsciidocPubkit::HeadingRules.scan(targets, config).map { |f| f['match'] }
  end

  def test_mecab_is_required_unless_literal_is_explicit
    config = settings
    config['tokenizer'] = 'mecab'
    config['mecab_command'] = '/nonexistent/pubkit-mecab'
    assert_raises(AsciidocPubkit::Error) { AsciidocPubkit::HeadingRules.scan([heading('入力')], config) }
  end

  def test_rule_schema_rejects_unknown_keys_and_invalid_types
    mutations = [
      ->(r) { r['unknown'] = true },
      ->(r) { r['schema_version'] = true },
      ->(r) { r['schema_version'] = 1.0 },
      ->(r) { r['style'] = 'desu-masu' },
      ->(r) { r['duplicate_siblings'] = 'true' },
      ->(r) { r['fixed_titles'] = ['まとめ', 'まとめ'] },
      ->(r) { r['terms'] = [] },
      ->(r) { r['terms']['empty'] = { 'terms' => [''], 'question' => 'Check.' } },
      ->(r) { r['terms']['empty'] = { 'terms' => [], 'question' => ' ' } },
      ->(r) { r['terms']['empty'] = { 'terms' => [], 'question' => 'Check.', 'extra' => true } }
    ]
    mutations.each do |mutate|
      custom = rules
      mutate.call(custom)
      assert_raises(AsciidocPubkit::Error) { AsciidocPubkit::HeadingRuleSet.validate(custom) }
    end
  end
end
