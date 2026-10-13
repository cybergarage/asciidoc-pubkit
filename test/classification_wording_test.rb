# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require 'stringio'
require 'asciidoc_pubkit'
require_relative '../benchmark/prose'

class ClassificationWordingTest < Minitest::Test
  GUIDANCE = ['Distinguish classification, responsibility sharing, branching, and partitioning',
              '用途に応じて検索、読み込み、変更、コマンド実行に分類できます',
              '次の担当が分担します', '処理が二つの工程へ分岐します',
              'ターンの区切りで分割します', 'no detector or automatic replacement rule'].freeze

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
    historical = 'Historical comparisons without classification guidance'
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
    cases = JSON.parse(File.read(File.join(__dir__, 'fixtures/classification_wording.ja.json')))
    assert_equal 14, cases.length
    assert_equal cases.length, cases.map { |item| item.fetch('id') }.uniq.length
    assert_equal 7, cases.count { |item| item.fetch('expected_disposition') == 'accept' }
    assert_equal 7, cases.count { |item| item.fetch('expected_disposition') == 'reject' }
    cases.each do |item|
      %w[source revision reason].each { |key| refute_empty item.fetch(key), item['id'] }
    end
    # Manual labels are calibration examples, not measured editorial accuracy.
    assert_includes ProseBenchmark::RUBRIC, GUIDANCE.first
    assert_includes ProseBenchmark::RUBRIC, 'branching does not establish parallel execution'
    assert_includes ProseBenchmark::RUBRIC, 'preserve whether'
  end

  private

  def with_manuscript
    Dir.mktmpdir('pubkit-classification-') do |directory|
      file = File.join(directory, 'book.adoc')
      source = "= Example\n\n== 用途の分類\n\nツールは用途に応じて分かれます。\n\n* 判定処理が両方を返すと、二つの工程へ処理が分かれます。\n"
      File.write(file, source)
      yield directory, file, source
    end
  end
end
