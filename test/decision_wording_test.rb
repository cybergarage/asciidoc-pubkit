# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require 'stringio'
require 'asciidoc_pubkit'

class DecisionWordingTest < Minitest::Test
  def cli(*args)
    out = StringIO.new
    err = StringIO.new
    code = AsciidocPubkit::CLI.run(args, out: out, err: err)
    [code, out.string, err.string]
  end

  def test_decision_comparisons_reach_writing_and_saved_review_prompts
    expected = ['Distinguish decisions by the actual operation',
                'Distinguish rules, definitions, and configured values',
                '工程と分岐を定義します', '上限や接続先を設定します',
                'RunLimitsは上限を指定する型です', '許可範囲を規定し、通知先を設定します',
                'a type declaration does not itself configure, enforce, or execute a limit',
                'Recommendations and plans do not',
                '呼び出すツールを選択します', '入力予算を算出します', '上限を設定します',
                '実行全体の状態を判定します', '証拠として利用できるかを判断します',
                '評価前に条件を規定します', '次の処理を決定します',
                '読み込んだファイルと値を反映する順序によって定まります',
                'do not add calculation, configuration, inspection, execution, or approval']
    %w[criteria prompt].each do |command|
      code, output, error = cli('writing', command, '--lang', 'ja')
      assert_equal 0, code, error
      expected.each { |text| assert_includes output, text }
    end
    Dir.mktmpdir('pubkit-decisions-') do |directory|
      manuscript = File.join(directory, 'book.adoc')
      source = "= Example\n\n== 条件\n\n次の処理を決めます。\n\n* 評価前に条件を決めます。\n"
      File.write(manuscript, source)
      %w[headings prose lists].each do |scope|
        session = File.join(directory, scope)
        code, _, error = cli('review', 'scan', manuscript, '--scope', scope,
                             '--tokenizer', 'literal', '--output', session, '--no-input')
        assert_equal 0, code, error
        saved = JSON.parse(File.read(File.join(session, 'manifest.json')))['writing_criteria']
        expected.each { |text| assert_includes saved, text }
        # A later criteria update must not alter a session's saved contract.
        original = AsciidocPubkit::Writing.method(:criteria)
        begin
          AsciidocPubkit::Writing.define_singleton_method(:criteria) do |_language|
            'Later criteria without these comparisons'
          end
          code, prompt, error = cli('review', 'prompt', session)
          assert_equal 0, code, error
          assert_includes prompt, saved
          refute_includes prompt, 'Later criteria without these comparisons'
        ensure
          AsciidocPubkit::Writing.define_singleton_method(:criteria, original)
        end
        code, report, error = cli('review', 'verify', session)
        assert_equal 0, code, error
        assert JSON.parse(report)['passed']
        assert_equal false, JSON.parse(report)['meaning_verified']
        assert_equal source, File.read(manuscript)
      end
    end
  end
  def test_existing_sessions_keep_historical_criteria_after_rule_wording_update
    current = AsciidocPubkit::Writing.method(:criteria)
    historical = "Historical rule wording: 評価前に条件を定めます"
    Dir.mktmpdir('pubkit-rule-wording-history-') do |directory|
      manuscript = File.join(directory, 'book.adoc')
      source = "= Example\n\n== 条件\n\n評価前に条件を定めます。\n\n* 上限を定めます。\n"
      File.write(manuscript, source)
      %w[headings prose lists].each do |scope|
        old_session = File.join(directory, "old-#{scope}")
        begin
          AsciidocPubkit::Writing.define_singleton_method(:criteria) { |_lang| historical }
          code, _, error = cli('review', 'scan', manuscript, '--scope', scope,
                               '--tokenizer', 'literal', '--output', old_session, '--no-input')
          assert_equal 0, code, error
        ensure
          AsciidocPubkit::Writing.define_singleton_method(:criteria, current)
        end
        original_manifest = File.binread(File.join(old_session, 'manifest.json'))
        code, prompt, error = cli('review', 'prompt', old_session)
        assert_equal 0, code, error
        assert_includes prompt, historical
        refute_includes prompt, 'Distinguish rules, definitions, and configured values'
        code, report, error = cli('review', 'verify', old_session)
        assert_equal 0, code, error
        assert JSON.parse(report)['passed']
        assert_equal false, JSON.parse(report)['meaning_verified']
        assert_equal original_manifest, File.binread(File.join(old_session, 'manifest.json'))
        new_session = File.join(directory, "new-#{scope}")
        code, _, error = cli('review', 'scan', manuscript, '--scope', scope,
                             '--tokenizer', 'literal', '--output', new_session, '--no-input')
        assert_equal 0, code, error
        code, prompt, error = cli('review', 'prompt', new_session)
        assert_equal 0, code, error
        assert_includes prompt, 'Distinguish rules, definitions, and configured values'
        assert_includes prompt, '許可範囲を規定し、通知先を設定します'
        assert_equal source, File.read(manuscript)
      end
    end
  end
end
