# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require 'stringio'
require 'asciidoc_pubkit'

class RetentionRepresentationWordingTest < Minitest::Test
  def cli(*args)
    out = StringIO.new
    err = StringIO.new
    code = AsciidocPubkit::CLI.run(args, out: out, err: err)
    [code, out.string, err.string]
  end

  def test_current_guidance_is_delivered_and_historical_sessions_stay_frozen
    raw = AsciidocPubkit::Writing.criteria('ja')
    current = AsciidocPubkit::Writing.prompt_criteria('ja')
    historical = 'Historical criteria without retention or representation comparisons'
    %w[criteria prompt].each do |command|
      code, output, error = cli('writing', command, '--lang', 'ja')
      assert_equal 0, code, error
      assert_includes output, (command == 'criteria' ? raw : current).rstrip
    end
    assert_includes current, '### Distinguish retention from inclusion, storage, and assignment'
    assert_includes current, '### Distinguish representation from evidence and state indication'
    Dir.mktmpdir('pubkit-retention-representation-') do |directory|
      file = File.join(directory, 'book.adoc')
      source = "= Sample\n\n== 結果の表示\n\n失敗を表す結果を入力へ保持します。\n\n* 元の応答を保持します。\n"
      File.write(file, source)
      %w[headings prose lists].each do |scope|
        [historical, raw].each_with_index do |criteria, index|
          expected = index.zero? ? historical : current
          session = File.join(directory, "#{scope}-#{index}")
          original = AsciidocPubkit::Writing.method(:criteria)
          begin
            AsciidocPubkit::Writing.define_singleton_method(:criteria) { |_lang| criteria }
            code, _, error = cli('review', 'scan', file, '--scope', scope,
                                 '--tokenizer', 'literal', '--output', session, '--no-input')
            assert_equal 0, code, error
          ensure
            AsciidocPubkit::Writing.define_singleton_method(:criteria, original)
          end
          manifest_file = File.join(session, 'manifest.json')
          manifest = File.binread(manifest_file)
          assert_equal expected, JSON.parse(manifest.dup).fetch('writing_criteria')
          code, prompt, error = cli('review', 'prompt', session)
          assert_equal 0, code, error
          assert_includes prompt, expected.rstrip
          refute_includes prompt, current if index.zero?
          code, report, error = cli('review', 'verify', session)
          assert_equal 0, code, error
          result = JSON.parse(report)
          assert result['passed']
          assert_equal false, result['meaning_verified']
          assert_equal manifest, File.binread(manifest_file)
          assert_equal source, File.read(file)
        end
      end
    end
  end

  def test_manual_calibration_has_both_decisions_and_retained_examples_per_topic
    path = File.join(__dir__, 'fixtures/retention_representation_wording.ja.json')
    cases = JSON.parse(File.read(path))
    assert_equal cases.length, cases.map { |item| item.fetch('id') }.uniq.length
    assert_equal %w[representation retention], cases.map { |item| item.fetch('topic') }.uniq.sort
    cases.group_by { |item| item.fetch('topic') }.each_value do |topic|
      assert_equal %w[accept reject], topic.map { |item| item.fetch('expected_disposition') }.uniq.sort
      assert topic.any? { |item| item['expected_disposition'] == 'accept' && item['source'] == item['revision'] }
      assert topic.any? { |item| item['expected_disposition'] == 'accept' && item['source'] != item['revision'] }
    end
    cases.each do |item|
      %w[source revision reason].each { |key| refute_empty item.fetch(key), item['id'] }
    end
    # Manual labels and delivery tests do not measure semantic or AI editing quality.
  end
end
