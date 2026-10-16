# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require 'stringio'
require 'asciidoc_pubkit'

class StopWordingTest < Minitest::Test
  def cli(*args)
    out = StringIO.new
    err = StringIO.new
    code = AsciidocPubkit::CLI.run(args, out: out, err: err)
    [code, out.string, err.string]
  end

  def test_stopping_criteria_reach_writing_and_frozen_review_prompts
    expected = ['Distinguish stopping, cancellation requests, and non-execution',
                'Runの取消を要求する場合は、取消APIを呼び出します',
                '失敗時は後続を開始しません',
                'Offでは、イベントの保持と通知を行いません',
                'an API call or signal notification does not establish actual termination',
                'these comparisons add no detector or replacement rule']
    %w[criteria prompt].each do |command|
      code, output, error = cli('writing', command, '--lang', 'ja')
      assert_equal 0, code, error
      expected.each { |text| assert_includes output, text }
    end
    Dir.mktmpdir('pubkit-stop-wording-') do |directory|
      file = File.join(directory, 'book.adoc')
      source = "= Sample\n\n== 処理を止める条件\n\n実行前フックは、実行を止められます。\n\n* 失敗時は後続を止めます。\n"
      File.write(file, source)
      %w[headings prose lists].each do |scope|
        session = File.join(directory, scope)
        code, _, error = cli('review', 'scan', file, '--scope', scope,
                             '--tokenizer', 'literal', '--output', session, '--no-input')
        assert_equal 0, code, error
        saved = JSON.parse(File.read(File.join(session, 'manifest.json')))['writing_criteria']
        expected.each { |text| assert_includes saved, text }
        original = AsciidocPubkit::Writing.method(:criteria)
        begin
          AsciidocPubkit::Writing.define_singleton_method(:criteria) { |_lang| 'Later criteria' }
          code, prompt, error = cli('review', 'prompt', session)
          assert_equal 0, code, error
          assert_includes prompt, saved
          refute_includes prompt, 'Later criteria'
        ensure
          AsciidocPubkit::Writing.define_singleton_method(:criteria, original)
        end
        code, report, error = cli('review', 'verify', session)
        assert_equal 0, code, error
        assert JSON.parse(report)['passed']
        refute JSON.parse(report)['meaning_verified']
        assert_equal source, File.read(file)
      end
    end
  end

  def test_manual_comparison_fixture_has_complete_unique_cases
    cases = JSON.parse(File.read(File.join(__dir__, 'fixtures/stop_wording.ja.json')))
    assert_equal 20, cases.length
    assert_equal cases.length, cases.map { |item| item.fetch('id') }.uniq.length
    assert_equal %w[accept reject], cases.map { |item| item.fetch('expected_disposition') }.uniq.sort
    cases.each do |item|
      %w[source revision reason].each { |key| refute_empty item.fetch(key), item['id'] }
    end
    # These manual labels are calibration data, not measured semantic correctness.
  end
end
