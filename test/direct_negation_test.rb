# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require 'stringio'
require 'asciidoc_pubkit'
require_relative '../benchmark/prose'

class DirectNegationTest < Minitest::Test
  EXPRESSIONS = %w[わけではありません わけではなく わけではない].freeze
  GUIDANCE = ['Distinguish direct negation, partial negation, and inference limits',
              '実行関数のコードはモデル側へ送信されません', '根拠として使えません',
              '必ずしも一致せず', '作業環境のすべては復元されません',
              'never turn partial negation into total denial',
              'missing evidence into a claim of', 'record the actual alternative'].freeze

  def cli(*args)
    out = StringIO.new
    err = StringIO.new
    code = AsciidocPubkit::CLI.run(args, out: out, err: err)
    [code, out.string, err.string]
  end

  def candidates(text, mode, rules: AsciidocPubkit::RuleSet.load, allows: [])
    settings = { 'tokenizer' => mode, 'allows' => allows, 'glossary' => {},
                 'style' => 'preserve', 'rules' => rules }
    tokenizer = mode == 'mecab' ? AsciidocPubkit::Morphology.new(settings) : nil
    paragraphs = [{ 'id' => 'sample', 'file' => '/example.adoc', 'line' => 10, 'text' => text }]
    AsciidocPubkit::Rules.scan(paragraphs, settings, tokenizer: tokenizer)
                       .select { |f| f['rule'] == 'contextual-phrase' && EXPRESSIONS.include?(f['match']) }
  end

  %w[mecab literal].each do |mode|
    define_method("test_negation_variants_positions_masking_and_rules_in_#{mode}") do
      text = "😀わけではありません。\nわけではなく、条件があります。わけではない。"
      findings = candidates(text, mode)
      assert_equal EXPRESSIONS, findings.map { |f| f['match'] }
      assert_equal [[10, 2], [11, 1], [11, 16]], findings.map { |f| f.values_at('line', 'column') }
      assert findings.all? { |f| f['severity'] == 'hint' }
      assert_empty candidates('送信されません。必ずしも一致しません。終了したとは判断できません。', mode)
      assert_empty candidates(EXPRESSIONS.map { |t| "`#{t}`。「#{t}」。link:https://example.test[#{t}]" }.join('。'), mode)
      assert_equal ['わけではありません'], candidates(text, mode, allows: EXPRESSIONS.drop(1)).map { |f| f['match'] }
      assert_empty candidates(text, mode, allows: EXPRESSIONS)
      custom = AsciidocPubkit::RuleSet.load
      custom['terms']['contextual-phrase']['terms'] -= EXPRESSIONS
      assert_empty candidates(text, mode, rules: custom)
      # A broader overlapping cue must not produce a duplicate candidate.
      specific = AsciidocPubkit::RuleSet.load
      specific['terms']['contextual-phrase']['terms'] << 'ではない'
      all = candidates('わけではない。', mode, rules: specific)
      assert_equal ['わけではない'], all.map { |f| f['match'] }
      assert_empty candidates('わけではない。', mode, rules: specific, allows: ['わけではない'])
    end
  end

  def test_criteria_delivery_and_saved_sessions_in_all_scopes
    %w[criteria prompt].each do |command|
      code, text, error = cli('writing', command, '--lang', 'ja')
      assert_equal 0, code, error
      GUIDANCE.each { |item| assert_includes text, item }
    end
    Dir.mktmpdir('pubkit-negation-') do |dir|
      source = "= Example\n\n== 条件\n\nツール定義だけで実装が送信されるわけではありません。\n\n* 必ず一致するわけではなく、条件によります。\n"
      file = File.join(dir, 'book.adoc')
      File.write(file, source)
      %w[headings prose lists].each do |scope|
        session = File.join(dir, scope)
        code, _, error = cli('review', 'scan', file, '--scope', scope,
                             '--tokenizer', 'literal', '--output', session, '--no-input')
        assert_equal 0, code, error
        saved = JSON.parse(File.read(File.join(session, 'manifest.json')))['writing_criteria']
        GUIDANCE.each { |item| assert_includes saved, item }
        # Later global defaults must not alter a saved session's prompt.
        original = AsciidocPubkit::Writing.method(:criteria)
        begin
          AsciidocPubkit::Writing.define_singleton_method(:criteria) { |_lang| 'Later unrelated criteria' }
          code, prompt, error = cli('review', 'prompt', session)
          assert_equal 0, code, error
          assert_includes prompt, saved
          refute_includes prompt, 'Later unrelated criteria'
        ensure
          AsciidocPubkit::Writing.define_singleton_method(:criteria, original)
        end
        code, report, error = cli('review', 'verify', session)
        assert_equal 0, code, error
        assert JSON.parse(report)['passed']
        assert_equal false, JSON.parse(report)['meaning_verified']
        assert_equal source, File.read(file)
      end
    end
  end

  def test_historical_rules_remain_saved_while_new_scans_use_new_defaults
    Dir.mktmpdir('pubkit-negation-history-') do |dir|
      file = File.join(dir, 'book.adoc')
      source = "= Example\n\n== 条件\n\n一致するわけではなく、条件によります。\n\n* 終了するわけではない。\n"
      File.write(file, source)
      historical = AsciidocPubkit::RuleSet.load
      historical['terms']['contextual-phrase']['terms'] -= EXPRESSIONS.drop(1)
      rules = File.join(dir, 'old-rules.yml')
      File.write(rules, YAML.dump(historical))
      %w[prose lists].each do |scope|
        old = File.join(dir, "old-#{scope}")
        code, _, error = cli('review', 'scan', file, '--scope', scope, '--rules', rules,
                             '--tokenizer', 'literal', '--output', old, '--no-input')
        assert_equal 0, code, error
        manifest = File.binread(File.join(old, 'manifest.json'))
        File.write(rules, YAML.dump(AsciidocPubkit::RuleSet.load))
        code, _, error = cli('review', 'prompt', old)
        assert_equal 0, code, error
        code, report, error = cli('review', 'verify', old)
        assert_equal 0, code, error
        assert JSON.parse(report)['passed']
        assert_equal manifest, File.binread(File.join(old, 'manifest.json'))
        old_findings = JSON.parse(File.read(File.join(old, 'findings.json')))
        refute old_findings.any? { |f| EXPRESSIONS.drop(1).include?(f['match']) }
        fresh = File.join(dir, "new-#{scope}")
        code, _, error = cli('review', 'scan', file, '--scope', scope,
                             '--tokenizer', 'literal', '--output', fresh, '--no-input')
        assert_equal 0, code, error
        findings = JSON.parse(File.read(File.join(fresh, 'findings.json')))
        assert findings.any? { |f| EXPRESSIONS.drop(1).include?(f['match']) }
        File.write(rules, YAML.dump(historical))
        assert_equal source, File.read(file)
      end
    end
  end

  def test_calibration_covers_direct_denial_partial_negation_and_inference_limits
    pairs = JSON.parse(File.read(ProseBenchmark::CALIBRATION)).fetch('manual_revision_cases')
    expected = { 'negation-direct-operation' => 'accept', 'negation-capability' => 'accept',
                 'negation-insufficient-condition' => 'accept', 'negation-partial-token' => 'accept',
                 'negation-partial-restoration' => 'accept', 'negation-partial-made-total' => 'reject',
                 'negation-inference-made-absence' => 'reject', 'negation-capability-made-choice' => 'reject',
                 'negation-inference-retained' => 'accept', 'negation-added-enforcement' => 'needs-evidence' }
    expected.each do |id, disposition|
      pair = pairs.find { |item| item['id'] == id }
      refute_nil pair, id
      assert_equal disposition, pair.fetch('expected_disposition'), id
      %w[source revision reason review_axes].each { |key| refute_empty pair.fetch(key), "#{id}: #{key}" }
    end
    assert_equal pairs.length, pairs.map { |p| p.fetch('id') }.uniq.length
    assert_includes ProseBenchmark::RUBRIC, 'never turn partial negation into total denial'
    assert_includes ProseBenchmark::RUBRIC, 'Missing observation'
  end
end
