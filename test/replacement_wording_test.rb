# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require 'stringio'
require 'asciidoc_pubkit'
require_relative '../benchmark/prose'

class ReplacementWordingTest < Minitest::Test
  def cli(*args)
    out = StringIO.new
    err = StringIO.new
    code = AsciidocPubkit::CLI.run(args, out: out, err: err)
    [code, out.string, err.string]
  end

  def test_comparisons_reach_writing_and_saved_scopes_without_rewriting
    expected = ['Distinguish replacement from interpretation and permitted use',
                '利用者の承認とはみなしません', '終了したことの確認としては扱えません',
                '使用量がゼロだったかは判断できません',
                'Do not change inability into a choice not to act']
    %w[criteria prompt].each do |command|
      code, output, error = cli('writing', command, '--lang', 'ja')
      assert_equal 0, code, error
      expected.each { |text| assert_includes output, text }
    end
    Dir.mktmpdir('pubkit-replacement-wording-') do |directory|
      manuscript = File.join(directory, 'book.adoc')
      source = "= Example\n\n== 終了確認\n\n進捗通知は終了確認を置き換えません。\n\n* 欠測を0へ置き換えません。\n"
      File.write(manuscript, source)
      %w[headings prose lists].each do |scope|
        session = File.join(directory, scope)
        code, _, error = cli('review', 'scan', manuscript, '--scope', scope,
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
        assert_equal false, JSON.parse(report)['meaning_verified']
        assert_equal source, File.read(manuscript)
      end
    end
  end

  def test_existing_mecab_rules_detect_negative_replacement_without_new_rules
    settings = { 'tokenizer' => 'mecab', 'allows' => [], 'glossary' => {}, 'style' => 'preserve' }
    tokenizer = AsciidocPubkit::Morphology.new(settings)
    text = "進捗通知は終了確認を置き換えません。\n要約だけで会話全体を置き換えず、原文を保持します。"
    paragraph = { 'id' => 'sample', 'file' => '/example.adoc', 'line' => 1, 'text' => text }
    findings = AsciidocPubkit::Rules.scan([paragraph], settings, tokenizer: tokenizer)
    replacements = findings.select { |f| f['rule'] == 'weak-predicate' && f['lemma'] == '置き換える' }
    assert_equal ['置き換えません', '置き換えず'], replacements.map { |f| f['match'] }
    assert replacements.all? { |f| f['negative'] }
  end

  def test_calibration_covers_use_limits_and_retained_actual_replacement
    pairs = JSON.parse(File.read(ProseBenchmark::CALIBRATION)).fetch('manual_revision_cases')
    expected = { 'approval' => 'accept', 'progress-use' => 'accept',
                 'fixed-response' => 'accept', 'missing-usage' => 'accept',
                 'impression-use' => 'accept', 'actual-history-kept' => 'accept',
                 'actual-history-made-interpretation' => 'reject',
                 'missing-made-failure' => 'reject', 'use-limit-made-choice' => 'reject' }
    expected.each do |name, disposition|
      pair = pairs.find { |entry| entry['id'] == "replacement-#{name}" }
      refute_nil pair, name
      assert_equal disposition, pair.fetch('expected_disposition'), name
      %w[source revision reason].each { |key| refute_empty pair.fetch(key), name }
      refute_empty pair.fetch('review_axes'), name
    end
    assert_includes ProseBenchmark::RUBRIC, 'actual replacement from interpretation and permitted use'
    assert_includes ProseBenchmark::RUBRIC, 'Missing evidence does not imply failure or zero usage'
  end
end
