# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require 'stringio'
require 'asciidoc_pubkit'
require_relative '../benchmark/prose'

class InterpretationWordingTest < Minitest::Test
  EXPRESSIONS = %w[とはみなしません とみなしません].freeze
  GUIDANCE = ['Compare `とはみなしません` and `とみなしません` with direct wording',
              '操作の実行結果は確認できません', '証拠にはなりません',
              '使用量がゼロだったかは判断できません',
              'Retain `だけでは`', 'discretionary interpretation rule'].freeze

  def cli(*args)
    out = StringIO.new
    err = StringIO.new
    code = AsciidocPubkit::CLI.run(args, out: out, err: err)
    [code, out.string, err.string]
  end

  %w[mecab literal].each do |mode|
    define_method("test_candidates_positions_masking_allows_and_custom_rules_in_#{mode}") do
      rules = AsciidocPubkit::RuleSet.load
      scan = lambda do |text, allows = [], configured = rules|
        settings = { 'tokenizer' => mode, 'allows' => allows, 'glossary' => {},
                     'style' => 'preserve', 'rules' => configured }
        paragraph = { 'id' => 'sample', 'file' => '/example.adoc', 'line' => 10, 'text' => text }
        AsciidocPubkit::Rules.scan([paragraph], settings)
                           .select { |f| f['rule'] == 'contextual-phrase' && EXPRESSIONS.include?(f['match']) }
      end
      text = "😀とはみなしません。\n証拠とみなしません。"
      found = scan.call(text)
      assert_equal EXPRESSIONS, found.map { |f| f['match'] }
      assert_equal [[10, 2], [11, 3]], found.map { |f| f.values_at('line', 'column') }
      assert found.all? { |f| f['severity'] == 'hint' }
      assert_empty scan.call('判断できません。評価できません。承認とみなします。')
      assert_empty scan.call(EXPRESSIONS.map { |s| "`#{s}`。「#{s}」。link:https://example.test[#{s}]" }.join('。'))
      assert_equal ['とみなしません'], scan.call(text, ['とはみなしません']).map { |f| f['match'] }
      assert_empty scan.call(text, EXPRESSIONS)
      custom = AsciidocPubkit::RuleSet.load
      custom['terms']['contextual-phrase']['terms'] -= EXPRESSIONS
      assert_empty scan.call(text, [], custom)
      # A broader overlapping configured phrase must not duplicate the cue.
      custom['terms']['contextual-phrase']['terms'] += EXPRESSIONS + ['みなしません']
      assert_equal ['とはみなしません'], scan.call('とはみなしません。', [], custom).map { |f| f['match'] }
      assert_empty scan.call('とはみなしません。', ['とはみなしません'], custom)
    end
  end

  def test_criteria_delivery_and_historical_sessions
    %w[criteria prompt].each do |command|
      code, text, error = cli('writing', command, '--lang', 'ja')
      assert_equal 0, code, error
      GUIDANCE.each { |item| assert_includes text, item }
    end
    Dir.mktmpdir('pubkit-interpretation-') do |dir|
      file = File.join(dir, 'book.adoc')
      source = "= Example\n\n== 判断条件\n\nゼロだったとはみなしません。\n\n* 不実行の証拠とみなしません。\n"
      File.write(file, source)
      historical = AsciidocPubkit::RuleSet.load
      historical['terms']['contextual-phrase']['terms'] -= EXPRESSIONS
      rule_file = File.join(dir, 'historical.yml')
      File.write(rule_file, YAML.dump(historical))
      %w[headings prose lists].each do |scope|
        old = File.join(dir, "old-#{scope}")
        rule_args = scope == 'headings' ? [] : ['--rules', rule_file]
        code, _, error = cli('review', 'scan', file, '--scope', scope, *rule_args,
                             '--tokenizer', 'literal', '--output', old, '--no-input')
        assert_equal 0, code, error
        manifest = File.binread(File.join(old, 'manifest.json'))
        saved = JSON.parse(manifest).fetch('writing_criteria')
        GUIDANCE.each { |item| assert_includes saved, item }
        original = AsciidocPubkit::Writing.method(:criteria)
        begin
          AsciidocPubkit::Writing.define_singleton_method(:criteria) { |_lang| 'Later criteria' }
          code, prompt, error = cli('review', 'prompt', old)
          assert_equal 0, code, error
          assert_includes prompt, saved
          refute_includes prompt, 'Later criteria'
        ensure
          AsciidocPubkit::Writing.define_singleton_method(:criteria, original)
        end
        code, report, error = cli('review', 'verify', old)
        assert_equal 0, code, error
        assert JSON.parse(report)['passed']
        assert_equal false, JSON.parse(report)['meaning_verified']
        assert_equal manifest, File.binread(File.join(old, 'manifest.json'))
        refute JSON.parse(File.read(File.join(old, 'findings.json'))).any? { |f| EXPRESSIONS.include?(f['match']) }
        fresh = File.join(dir, "new-#{scope}")
        code, _, error = cli('review', 'scan', file, '--scope', scope,
                             '--tokenizer', 'literal', '--output', fresh, '--no-input')
        assert_equal 0, code, error
        if scope != 'headings'
          assert JSON.parse(File.read(File.join(fresh, 'findings.json'))).any? { |f| EXPRESSIONS.include?(f['match']) }
        end
        assert_equal source, File.read(file)
      end
    end
  end

  def test_calibration_preserves_evidence_limits_policies_and_author_preferences
    pairs = JSON.parse(File.read(ProseBenchmark::CALIBRATION)).fetch('manual_revision_cases')
    expected = { 'summary-direct' => 'accept', 'observation-direct' => 'accept',
                 'evaluation-direct' => 'accept', 'usage-direct' => 'accept',
                 'usage-made-nonzero' => 'reject', 'evaluation-made-unconditional' => 'reject',
                 'observation-made-nonexecution' => 'reject', 'policy-retained' => 'accept',
                 'policy-made-uncertainty' => 'reject', 'author-preference-ignored' => 'reject' }
    expected.each do |id, disposition|
      pair = pairs.find { |item| item['id'] == "interpretation-#{id}" }
      refute_nil pair, id
      assert_equal disposition, pair.fetch('expected_disposition'), id
      %w[source revision reason review_axes].each { |key| refute_empty pair.fetch(key), "#{id}: #{key}" }
    end
    assert_includes ProseBenchmark::RUBRIC, 'preserve explicit'
    assert_includes ProseBenchmark::RUBRIC, 'Do not infer nonzero usage from missing counts'
  end
end
