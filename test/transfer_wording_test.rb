# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require 'stringio'
require 'asciidoc_pubkit'
require_relative '../benchmark/prose'

class TransferWordingTest < Minitest::Test
  GUIDANCE = ['Distinguish input, transmission, delegation, inheritance, and handoff',
              '取消シグナルを引数として指定します', '会話履歴を引き継ぎます',
              '成果物を後続の担当へ引き渡します',
              'no detector or automatic replacement rule'].freeze

  def cli(*args)
    out = StringIO.new
    err = StringIO.new
    code = AsciidocPubkit::CLI.run(args, out: out, err: err)
    [code, out.string, err.string]
  end

  def test_writing_commands_and_new_sessions_receive_contextual_comparisons
    %w[criteria prompt].each do |command|
      code, output, error = cli('writing', command, '--lang', 'ja')
      assert_equal 0, code, error
      GUIDANCE.each { |text| assert_includes output, text }
    end
    with_manuscript do |directory, file, source|
      %w[headings prose lists].each do |scope|
        session = File.join(directory, scope)
        code, _, error = cli('review', 'scan', file, '--scope', scope,
                             '--tokenizer', 'literal', '--output', session, '--no-input')
        assert_equal 0, code, error
        manifest = File.binread(File.join(session, 'manifest.json'))
        saved = JSON.parse(manifest).fetch('writing_criteria')
        GUIDANCE.each { |text| assert_includes saved, text }
        code, prompt, error = cli('review', 'prompt', session)
        assert_equal 0, code, error
        assert_includes prompt, saved
        code, report, error = cli('review', 'verify', session)
        assert_equal 0, code, error
        assert JSON.parse(report)['passed']
        assert_equal false, JSON.parse(report)['meaning_verified']
        assert_equal manifest, File.binread(File.join(session, 'manifest.json'))
        assert_equal source, File.read(file)
      end
    end
  end

  def test_historical_sessions_keep_their_original_criteria
    original = AsciidocPubkit::Writing.method(:criteria)
    historical = 'Historical comparisons without transfer guidance'
    with_manuscript do |directory, file, source|
      %w[headings prose lists].each do |scope|
        session = File.join(directory, scope)
        begin
          AsciidocPubkit::Writing.define_singleton_method(:criteria) { |_lang| historical }
          code, _, error = cli('review', 'scan', file, '--scope', scope,
                               '--tokenizer', 'literal', '--output', session, '--no-input')
          assert_equal 0, code, error
        ensure
          AsciidocPubkit::Writing.define_singleton_method(:criteria, original)
        end
        manifest = File.binread(File.join(session, 'manifest.json'))
        code, prompt, error = cli('review', 'prompt', session)
        assert_equal 0, code, error
        assert_includes prompt, historical
        refute_includes prompt, GUIDANCE.first
        code, report, error = cli('review', 'verify', session)
        assert_equal 0, code, error
        assert JSON.parse(report)['passed']
        assert_equal false, JSON.parse(report)['meaning_verified']
        assert_equal manifest, File.binread(File.join(session, 'manifest.json'))
        assert_equal source, File.read(file)
      end
    end
  end

  def test_manual_comparison_fixture_and_judge_guidance
    cases = JSON.parse(File.read(File.join(__dir__, 'fixtures/transfer_wording.ja.json')))
    assert_equal 18, cases.length
    assert_equal cases.length, cases.map { |item| item.fetch('id') }.uniq.length
    assert_equal 9, cases.count { |item| item.fetch('expected_disposition') == 'accept' }
    assert_equal 1, cases.count { |item| item.fetch('expected_disposition') == 'needs-evidence' }
    assert_equal 8, cases.count { |item| item.fetch('expected_disposition') == 'reject' }
    cases.each do |item|
      %w[source revision reason].each { |key| refute_empty item.fetch(key), item['id'] }
    end
    # Manual labels are calibration examples, not measured editorial accuracy.
    assert_includes ProseBenchmark::RUBRIC, GUIDANCE.first
    assert_includes ProseBenchmark::RUBRIC, 'handoff does not prove acceptance'
    assert_includes ProseBenchmark::RUBRIC, 'function arguments are not later notifications'
  end

  private

  def with_manuscript
    Dir.mktmpdir('pubkit-transfer-') do |directory|
      file = File.join(directory, 'book.adoc')
      source = "= Example\n\n== 入力と引き継ぎ\n\n実行側はツール結果をモデル入力へ渡します。\n\n* 再開時は会話履歴を次の実行へ渡します。\n"
      File.write(file, source)
      yield directory, file, source
    end
  end
end
