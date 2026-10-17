# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require 'stringio'
require 'asciidoc_pubkit'

class ActorClarityTest < Minitest::Test
  def cli(*args)
    out = StringIO.new
    err = StringIO.new
    code = AsciidocPubkit::CLI.run(args, out: out, err: err)
    [code, out.string, err.string]
  end

  %w[mecab literal].each do |mode|
    define_method("test_candidate_free_actor_review_and_frozen_criteria_in_#{mode}") do
      Dir.mktmpdir('pubkit-actor-') do |dir|
        book = File.join(dir, 'book.adoc')
        session = File.join(dir, 'session')
        passage = 'モデルが変更を要求しても、許可されるまではファイルを変更しません。'
        source = "= Example\n\n== 操作\n\n#{passage}\n"
        File.write(book, source)
        code, _, error = cli('review', 'scan', book, '--tokenizer', mode,
                             '--output', session, '--no-input')
        assert_equal 0, code, error
        assert_empty JSON.parse(File.read(File.join(session, 'findings.json')))
        document = JSON.parse(File.read(File.join(session, 'document.json')))
        assert_equal [passage], document.fetch('paragraphs').map { |p| p.fetch('text') }
        manifest_path = File.join(session, 'manifest.json')
        manifest_bytes = File.binread(manifest_path)
        saved = JSON.parse(manifest_bytes.dup).fetch('writing_criteria')
        code, prompt, error = cli('review', 'prompt', session)
        assert_equal 0, code, error
        assert_includes prompt, saved
        assert_includes prompt, passage
        assert_equal source, File.read(book)
        # Criteria changes after scanning must not change the saved instructions.
        original = AsciidocPubkit::Writing.method(:criteria)
        begin
          AsciidocPubkit::Writing.define_singleton_method(:criteria) { |_language| 'Later criteria' }
          code, later, error = cli('review', 'prompt', session)
          assert_equal 0, code, error
          assert_equal prompt, later
        ensure
          AsciidocPubkit::Writing.define_singleton_method(:criteria, original)
        end
        assert_equal manifest_bytes, File.binread(manifest_path)
        # The verifier can preserve scope but cannot validate a newly named actor.
        %w[エージェント モデル].each do |actor|
          File.write(book, source.sub('許可されるまでは', "#{actor}は許可されるまでは"))
          code, report, error = cli('review', 'verify', session)
          assert_equal 0, code, error
          result = JSON.parse(report)
          assert result.fetch('passed')
          assert_equal false, result.fetch('meaning_verified')
        end
      end
    end
  end
  def test_explicit_actor_criteria_reach_all_scopes_without_changing_sources
    criteria = AsciidocPubkit::Writing.prompt_criteria('ja')
    assert_includes criteria, 'Compare explicit actor names with the actual responsibility'
    %w[criteria prompt].each do |command|
      code, output, error = cli('writing', command, '--lang', 'ja')
      assert_equal 0, code, error
      assert_includes output, 'Compare explicit actor names with the actual responsibility'
    end
    Dir.mktmpdir('pubkit-explicit-actor-') do |dir|
      file = File.join(dir, 'book.adoc')
      source = "= Example\n\n== 操作の担当\n\n実行側は入力を検査します。\n\n* 処理側へ要求を引き渡します。\n"
      File.write(file, source)
      %w[headings prose lists].each do |scope|
        session = File.join(dir, scope)
        code, _, error = cli('review', 'scan', file, '--scope', scope,
                             '--tokenizer', 'literal', '--output', session, '--no-input')
        assert_equal 0, code, error
        manifest_file = File.join(session, 'manifest.json')
        manifest = File.binread(manifest_file)
        assert_equal criteria, JSON.parse(manifest.dup).fetch('writing_criteria')
        code, prompt, error = cli('review', 'prompt', session)
        assert_equal 0, code, error
        assert_includes prompt, criteria.rstrip
        original = AsciidocPubkit::Writing.method(:criteria)
        begin
          AsciidocPubkit::Writing.define_singleton_method(:criteria) { |_lang| 'Later actor criteria' }
          code, frozen_prompt, error = cli('review', 'prompt', session)
          assert_equal 0, code, error
          assert_equal prompt, frozen_prompt
        ensure
          AsciidocPubkit::Writing.define_singleton_method(:criteria, original)
        end
        assert_equal manifest, File.binread(manifest_file)
        assert_equal source, File.read(file)
      end
    end
  end

  def test_explicit_actor_calibration_preserves_levels_and_unknown_owners
    pairs = JSON.parse(File.read(File.join(__dir__, 'fixtures/prose_evaluation.ja.json')))
                .fetch('manual_revision_cases').select { |item| item.fetch('id').start_with?('explicit-actor-') }
    assert_equal 10, pairs.length
    assert_equal pairs.length, pairs.map { |item| item.fetch('id') }.uniq.length
    assert_equal %w[accept needs-evidence reject], pairs.map { |item| item.fetch('expected_disposition') }.uniq.sort
    %w[recipient environment communication-peer defined-role configuration-owner].each do |axis|
      assert pairs.any? { |item| item.fetch('review_axes').include?(axis) }, axis
    end
    pairs.each do |item|
      %w[source revision reason review_axes].each { |key| refute_empty item.fetch(key), item['id'] }
    end
    kept = pairs.find { |item| item['id'] == 'explicit-actor-defined-role-kept' }
    assert_equal kept.fetch('source'), kept.fetch('revision')
    refined = pairs.find { |item| item['id'] == 'explicit-actor-actor-changed-verb-kept' }
    assert_equal refined.fetch('source').sub('実行側は', 'エージェントは'), refined.fetch('revision')
  end

end
