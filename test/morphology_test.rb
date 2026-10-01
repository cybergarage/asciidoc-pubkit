# frozen_string_literal: true

require 'minitest/autorun'
require 'asciidoc_pubkit'

class MorphologyTest < Minitest::Test
  def setup
    @settings = { 'tokenizer' => 'mecab', 'allows' => [], 'glossary' => {}, 'style' => 'preserve' }
    @tokenizer = AsciidocPubkit::Morphology.new(@settings)
  end

  def scan(text, settings = @settings)
    paragraph = { 'id' => 'sample', 'file' => '/example.adoc', 'line' => 10, 'text' => text }
    AsciidocPubkit::Rules.scan([paragraph], settings, tokenizer: settings['tokenizer'] == 'mecab' ? @tokenizer : nil)
  end

  def test_all_requested_expressions_are_candidates
    text = '入口。記述。場所。意図。浅い。深い。変わります。把握します。分けられます。そろえます。まとまっています。加えます。探します。到達しません。扱いません。そろいます。'
    findings = scan(text).select { |finding| finding['detector'] == 'mecab-ipadic' }
    expected = %w[入口 記述 場所 意図 浅い 深い 変わります 把握します 分けられます そろえます まとまっています 加えます 探します 到達しません 扱いません そろいます]
    expected.each { |surface| assert_equal 1, findings.count { |f| f['match'] == surface }, surface }
  end

  def test_contextual_predicates_keep_complete_inflections_and_polarity
    surfaces = %w[地味に効かなかった 静かに壊れていた 時間を溶かしてしまった 側に倒しました]
    findings = scan(surfaces.join('。') + '。').select { |f| f['rule'] == 'contextual-phrase' }
    assert_equal surfaces, findings.map { |f| f['match'] }
    assert_equal %w[地味に効く 静かに壊れる 時間を溶かす 側に倒す], findings.map { |f| f['lemma'] }
    assert_equal [true, false, false, false], findings.map { |f| f['negative'] }
    assert findings.all? { |f| f['detector'] == 'mecab-ipadic' && f['part_of_speech'] == '動詞' }
    negative = scan('静かに壊れませんでした。時間を溶かさずに調査した。側に倒さない。')
               .select { |f| f['rule'] == 'contextual-phrase' }
    assert_equal %w[静かに壊れませんでした 時間を溶かさず 側に倒さない], negative.map { |f| f['match'] }
    assert negative.all? { |f| f['negative'] }
  end

  def test_contextual_predicates_preserve_positions_and_do_not_duplicate_literals
    text = "😀 地味に効きます。\n　静かに壊れていた。"
    findings = scan(text).select { |f| f['rule'] == 'contextual-phrase' }
    assert_equal %w[地味に効きます 静かに壊れていた], findings.map { |f| f['match'] }
    assert_equal [[10, 3], [11, 2]], findings.map { |f| f.values_at('line', 'column') }
    assert_empty scan('地味に効かなかった。', @settings.merge('tokenizer' => 'literal'))
  end

  def test_contextual_predicate_allow_lists_and_custom_rule_replacement
    assert_empty scan('地味に効かなかった。', @settings.merge('allows' => ['地味に効く']))
    assert_empty scan('地味に効かなかった。', @settings.merge('allows' => ['地味に効かなかった']))
    findings = scan('地味に効きます。地味に効かなかった。', @settings.merge('allows' => ['地味に効きます']))
    assert_equal ['地味に効かなかった'], findings.map { |f| f['match'] }
    rules = AsciidocPubkit::RuleSet.load
    rules['terms']['contextual-phrase']['terms'] = []
    assert_empty scan('地味に効かなかった。静かに壊れていた。時間を溶かした。側に倒した。', @settings.merge('rules' => rules))
    rules['terms']['contextual-phrase']['terms'] = ['地味に効く', '設定は地味に効きます']
    findings = scan('設定は地味に効きます。', @settings.merge('rules' => rules))
    assert_equal ['設定は地味に効きます'], findings.map { |f| f['match'] }
    assert_empty scan('設定は地味に効きます。', @settings.merge('rules' => rules, 'allows' => ['設定は地味に効きます']))
  end

  def test_contextual_predicates_require_adjacent_unmasked_known_tokens
    text = '薬が効きます。氷を溶かしました。装置を倒した。地味に効き目がある。静かに壊れ物を運ぶ。'
    assert_empty scan(text).select { |f| f['rule'] == 'contextual-phrase' }
    assert_empty scan('`地味に効かなかった`。「静かに壊れていた」。地味に`例`効かなかった。時間を「例」溶かした。側に、倒した。')
    paragraphs = ['地味に', '効かなかった。'].map.with_index do |text, i|
      { 'id' => i.to_s, 'file' => '/example.adoc', 'line' => i + 1, 'text' => text }
    end
    assert_empty AsciidocPubkit::Rules.scan(paragraphs, @settings, tokenizer: @tokenizer)
  end

  def test_additional_requested_expressions_in_both_modes
    expressions = %w[これらを であることだけでは 役割 一続き 根拠 部品 開発者 選べます 扱います あるものとします わけではありません 成り立たせています 確かめます 書き換える 絞れます 渡します あります 別です 概念 意味しません]
    %w[mecab literal].each do |mode|
      findings = scan(expressions.join('。') + '。', @settings.merge('tokenizer' => mode))
      expressions.each { |surface| assert_equal 1, findings.count { |f| f['match'] == surface }, "#{mode}: #{surface}" }
      assert_equal expressions.length, findings.count { |f| %w[abstract-reference weak-predicate contextual-phrase].include?(f['rule']) }
    end
  end

  def test_additional_inflections_and_compound_boundaries
    findings = scan('選べなかった。成り立たせていた。確かめた。書き換えない。絞れた。渡した。あった。')
    assert_equal %w[選ぶ 成り立つ 確かめる 書き換える 絞る 渡す ある], findings.map { |f| f['lemma'] }
    assert findings.first['negative']
    assert_equal '成り立たせていた', findings[1]['match']
    assert_empty scan('開発 者。一`code`続き。「開発者」。`これらを`。')
    assert_empty scan('開発者。一続き。わけではありません。', @settings.merge('allows' => %w[開発者 一続き わけではありません]))
  end

  def test_inflected_verbs_are_matched_by_dictionary_form
    findings = scan('結果が変わった。動作を把握した。役割を分けられた。表記をそろえた。説明がまとまっていた。条件を加えない。項目を探せば、値がそろった。')
    expected = %w[変わる 把握する 分ける そろえる まとまる 加える 探す そろう]
    expected.each { |lemma| assert findings.any? { |f| f['lemma'] == lemma }, lemma }
    assert_equal 'まとまっていた', findings.find { |f| f['lemma'] == 'まとまる' }['match']
  end

  def test_adjective_inflections_and_negation
    findings = scan('説明が浅かった。深くない。')
    assert_equal %w[浅い 深い], findings.map { |f| f['lemma'] }
    assert_equal %w[浅かった 深くない], findings.map { |f| f['match'] }
    refute findings.first['negative']
    assert findings.last['negative']
  end

  def test_negative_reach_rule_preserves_polarity_and_ignores_positive_forms
    findings = scan('目的地に到達した。目的地に到達します。到達しません。到達しなかった。到達せずに戻る。')
    negative = findings.select { |f| f['lemma'] == '到達する' }
    assert_equal 3, negative.length
    assert negative.all? { |f| f['negative'] }
    assert_equal ['到達しません', '到達しなかった', '到達せず'], negative.map { |f| f['match'] }
  end

  def test_custom_morphological_rules_use_configured_lemmas_and_polarity
    rules = AsciidocPubkit::RuleSet.load
    rules['verbs']['読む'] = ['読む']
    rules['negative_only'] << '読む'
    findings = scan('読んだ。読まなかった。', @settings.merge('rules' => rules))
    assert_equal ['読まなかった'], findings.map { |f| f['match'] }
    assert_equal '読む', findings.first['lemma']
    assert findings.first['negative']
  end

  def test_negative_meaning_rule_preserves_polarity
    findings = scan('意味する。意味します。意味した。意味しません。意味しなかった。意味せずに終わる。').select { |f| f['rule'] == 'weak-predicate' }
    assert_equal %w[意味しません 意味しなかった 意味せず], findings.map { |f| f['match'] }
    assert findings.all? { |f| f['lemma'] == '意味する' && f['negative'] }
    assert_empty scan('意味しません。', @settings.merge('allows' => ['意味する']))
    assert_empty scan('「概念」と`意味しません`。')
  end

  def test_existing_rules_cover_past_and_negative_forms_without_duplicates
    findings = scan('結果を利用した。項目を整理しない。例を扱いません。数値を示した。')
    assert_equal %w[利用する 整理する 扱う 示す], findings.map { |f| f['lemma'] }
    assert findings.find { |f| f['lemma'] == '扱う' }['negative']
  end

  def test_sahen_nouns_require_a_following_suru_verb
    assert_empty scan('利用者と整理券を把握。到達点を確認する。')
  end

  def test_kanji_variants_and_allow_list_use_the_same_canonical_form
    findings = scan('値を揃えた。値が揃った。')
    assert_equal %w[そろえる そろう], findings.map { |f| f['lemma'] }
    assert_empty scan('値を揃えた。値をそろえます。', @settings.merge('allows' => ['そろえる']))
  end

  def test_exact_surface_allow_list_does_not_suppress_other_inflections
    findings = scan('例を扱います。例を扱った。', @settings.merge('allows' => ['扱います']))
    assert_equal ['扱った'], findings.map { |f| f['match'] }
  end

  def test_original_unicode_columns_and_line_numbers_are_preserved
    text = "😀 変わった。\n  深くない。"
    findings = scan(text)
    assert_equal [10, 3], findings.first.values_at('line', 'column')
    assert_equal [11, 3], findings.last.values_at('line', 'column')
  end

  def test_masked_code_and_quotations_do_not_generate_morphological_candidates
    findings = scan('`深かった`と「変わります」とlink:https://example.com[浅い]を参照する。')
    assert_empty findings
  end

  def test_predicates_do_not_join_across_masked_inline_content
    assert_empty scan('到達`identifier`しません。')
  end

  def test_paragraph_boundaries_do_not_join_sahen_compounds
    paragraphs = [
      { 'id' => 'a', 'file' => '/example.adoc', 'line' => 1, 'text' => '把握' },
      { 'id' => 'b', 'file' => '/example.adoc', 'line' => 3, 'text' => 'します。' }
    ]
    assert_empty AsciidocPubkit::Rules.scan(paragraphs, @settings, tokenizer: @tokenizer)
  end

  def test_long_lines_are_not_truncated_by_mecab_default_buffer
    findings = scan(('入力を確認する。' * 1500) + '深かった。')
    assert_equal '深かった', findings.last['match']
    assert_equal 12_001, findings.last['column']
  end

  def test_explicit_literal_mode_keeps_requested_surface_forms_without_mecab
    findings = scan('把握します。深かった。', @settings.merge('tokenizer' => 'literal', 'mecab_command' => '/not-installed'))
    assert_equal ['把握します'], findings.map { |f| f['match'] }
    refute findings.first.key?('lemma')
  end

  def test_missing_mecab_has_actionable_error_and_no_implicit_fallback
    error = assert_raises(AsciidocPubkit::Error) do
      AsciidocPubkit::Morphology.new('mecab_command' => '/not-installed/pubkit-mecab')
    end
    assert_includes error.message, 'brew install mecab mecab-ipadic'
  end

  def test_backend_identity_records_dictionary_fingerprints
    assert_equal 'mecab', @tokenizer.identity['engine']
    assert_equal 'ipadic', @tokenizer.identity['feature_schema']
    assert @tokenizer.identity['dictionary_files'].keys.any? { |path| path.end_with?('/sys.dic') }
  end
end
