# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require 'stringio'
require 'asciidoc_pubkit'

class PhaseTerminologyTest < Minitest::Test
  def cli(*args)
    out = StringIO.new
    err = StringIO.new
    code = AsciidocPubkit::CLI.run(args, out: out, err: err)
    [code, out.string, err.string]
  end

  def test_contextual_criteria_reach_writing_and_saved_scoped_reviews
    expected = ['Compare processing phases with timing and progressive disclosure',
                'phaseは現在の実行フェーズです', '2つのフェーズ',
                '設定だけがある段階', 'progressive disclosure',
                'not a universal replacement', 'not invent a dedicated setup phase']
    %w[criteria prompt].each do |command|
      code, output, error = cli('writing', command, '--lang', 'ja')
      assert_equal 0, code, error
      expected.each { |text| assert_includes output, text }
    end
    Dir.mktmpdir('pubkit-phase-') do |directory|
      manuscript = File.join(directory, 'book.adoc')
      source = "= Example\n\n[#execution]\n== 実行段階\n\nphaseは現在の実行段階です。\n\n* 抽出と統合を別段階で実行します。\n"
      File.write(manuscript, source)
      revisions = { 'headings' => ['== 実行段階', '== 実行フェーズ'],
                    'prose' => ['phaseは現在の実行段階', 'phaseは現在の実行フェーズ'],
                    'lists' => ['別段階で', '別のフェーズで'] }
      revisions.each do |scope, (before, after)|
        session = File.join(directory, scope)
        code, _, error = cli('review', 'scan', manuscript, '--scope', scope,
                             '--tokenizer', 'literal', '--output', session, '--no-input')
        assert_equal 0, code, error
        manifest_path = File.join(session, 'manifest.json')
        original_manifest = File.read(manifest_path)
        saved = JSON.parse(original_manifest).fetch('writing_criteria')
        expected.each { |text| assert_includes saved, text }
        original = AsciidocPubkit::Writing.method(:criteria)
        begin
          AsciidocPubkit::Writing.define_singleton_method(:criteria) { |_lang| 'Later criteria' }
          code, prompt, error = cli('review', 'prompt', session)
          assert_equal 0, code, error
          assert_includes prompt, saved
          refute_includes prompt, 'Later criteria'
          assert_equal source, File.read(manuscript)
        ensure
          AsciidocPubkit::Writing.define_singleton_method(:criteria, original)
        end
        source = source.sub(before, after)
        File.write(manuscript, source)
        code, report, error = cli('review', 'verify', session)
        assert_equal 0, code, error
        result = JSON.parse(report)
        assert result.fetch('passed')
        assert_empty result.fetch('issues')
        assert_equal false, result.fetch('meaning_verified')
        assert_equal original_manifest, File.read(manifest_path)
        assert_equal source, File.read(manuscript)
      end
    end
  end

  def test_manual_examples_cover_counts_conditions_and_non_phase_uses
    cases = JSON.parse(File.read(File.join(__dir__, 'fixtures/phase_terminology.ja.json')))
    assert_equal 11, cases.length
    assert_equal cases.length, cases.map { |item| item.fetch('id') }.uniq.length
    cases.each do |item|
      %w[source revision reason].each { |key| refute_empty item.fetch(key) }
      assert_includes %w[accept reject], item.fetch('expected_disposition')
    end
    %w[state-kept progressive-kept study-scope-kept].each do |id|
      item = cases.find { |example| example.fetch('id') == id }
      assert_equal 'accept', item.fetch('expected_disposition')
      assert_equal item.fetch('source'), item.fetch('revision')
    end
    %w[count-changed condition-lost mandatory-loading independence-invented].each do |id|
      item = cases.find { |example| example.fetch('id') == id }
      assert_equal 'reject', item.fetch('expected_disposition')
    end
    # Manual labels validate fixture coverage, not AI editorial accuracy.
  end
end
