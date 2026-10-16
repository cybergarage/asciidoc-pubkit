# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require 'stringio'
require 'asciidoc_pubkit'
require_relative '../benchmark/prose'

class DistinctionWordingTest < Minitest::Test
  def cli(*args)
    out = StringIO.new
    err = StringIO.new
    code = AsciidocPubkit::CLI.run(args, out: out, err: err)
    [code, out.string, err.string]
  end

  def test_comparisons_reach_writing_and_saved_prompts_without_rewriting_sources
    expected = ['Distinguish identification from conceptual separation',
                '呼び出しIDで判別できます', '二つの作業を識別できません',
                '処理の成否を判定できます', '書き込み完了を個別に確認できます',
                'Both stages may occur', 'Retain `区別`',
                'Do not turn `判別できます` into asserted automatic identification']
    %w[criteria prompt].each do |command|
      code, output, error = cli('writing', command, '--lang', 'ja')
      assert_equal 0, code, error
      expected.each { |text| assert_includes output, text }
    end
    Dir.mktmpdir('pubkit-distinction-') do |directory|
      manuscript = File.join(directory, 'book.adoc')
      source = "= Example\n\n== 対象の判別\n\n呼び出しIDで要求を区別できます。\n\n* 受付と完了を区別できます。\n"
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

  def test_calibration_covers_supported_comparisons_and_unsupported_changes
    calibration = JSON.parse(File.read(ProseBenchmark::CALIBRATION)).fetch('manual_revision_cases')
    selected = calibration.select { |item| item.fetch('id').start_with?('distinction-') }
    expected = {
      'distinction-id-evidence' => 'accept', 'distinction-identity' => 'accept',
      'distinction-outcome' => 'accept', 'distinction-stage-checks' => 'accept',
      'distinction-concept-kept' => 'accept', 'distinction-capability-made-behavior' => 'reject',
      'distinction-automatic-check-invented' => 'needs-evidence',
      'distinction-concept-made-identity' => 'reject'
    }
    assert_equal expected.keys.sort, selected.map { |item| item.fetch('id') }.sort
    selected.each do |item|
      assert_equal expected.fetch(item.fetch('id')), item.fetch('expected_disposition')
      %w[source revision reason review_axes].each { |key| refute_empty item.fetch(key) }
    end
    assert_includes ProseBenchmark::RUBRIC, 'Distinguish identification from conceptual separation'
    assert_includes ProseBenchmark::RUBRIC, 'Retain conceptual or causal separation'
    assert_includes ProseBenchmark::RUBRIC, 'do not invent automatic inspection'
  end
end
