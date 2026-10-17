# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require 'stringio'
require 'asciidoc_pubkit'

class JapaneseVerificationTest < Minitest::Test
  def setup
    @dir = File.realpath(Dir.mktmpdir('pubkit-ja-verification-'))
    @book = File.join(@dir, 'book.adoc')
    @session = File.join(@dir, 'session')
    @report = File.join(@dir, 'checked.json')
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  def cli(*args)
    out, err = StringIO.new, StringIO.new
    code = AsciidocPubkit::CLI.run(args, out: out, err: err, input: StringIO.new)
    [code, out.string, err.string]
  end

  def scan(text, *options)
    File.write(@book, text)
    result = cli('review', 'scan', @book, '--output', @session, *options)
    assert_equal 0, result[0], result.inspect
  end

  def verify(*options)
    result = cli('review', 'verify', @session, *options)
    [result[0], result[1].empty? ? nil : JSON.parse(result[1]), result[2]]
  end

  def test_real_mecab_changes_are_advisory_and_all_selected_text_is_available
    scan("= Book\n\n管理者の場合だけ、利用者は削除できません。\n\n保存できるかもしれません。\n")
    File.write(@book, "= Book\n\n管理者は削除できます。\n\n保存できます。\n")
    code, report = verify
    assert_equal 0, code
    assert_equal false, report['meaning_verified']
    change = report['japanese_change_review']['changes'].fetch(0)
    assert_equal @book, change['file']
    assert_equal 2, change['before'].length
    assert_equal 2, change['after'].length
    assert_equal 3, change['before'][0]['line']
    kinds = change['review_candidates'].map { |c| c['kind'] }
    %w[negation condition certainty capability actor-topic].each { |kind| assert_includes kinds, kind }
    assert report['passed']
  end

  def test_plain_revision_and_split_without_markers_still_appear
    scan("= Book\n\n入力を読み込み、結果を保存します。\n", '--tokenizer', 'literal')
    File.write(@book, "= Book\n\n入力を読み込みます。\n\n結果を保存します。\n")
    code, report = verify
    assert_equal 0, code
    change = report['japanese_change_review']['changes'].fetch(0)
    assert_empty change['review_candidates']
    assert_equal 1, change['before'].length
    assert_equal 2, change['after'].length
  end

  def test_inline_tokens_do_not_generate_marker_changes
    entries = [{ 'text' => '`できません`とlink:https://example.com[場合]を参照します。' }]
    AsciidocPubkit::JapaneseVerification::MARKERS.each_value do |pattern|
      assert_empty AsciidocPubkit::JapaneseVerification.inventory(entries, pattern)
    end
  end

  def test_record_matches_then_detects_a_later_edit_even_when_mechanical_checks_pass
    scan("= Book\n\n入力を読み込みます。\n", '--tokenizer', 'literal')
    result = cli('review', 'verify', @session, '--output', @report)
    assert_equal 0, result[0], result.inspect
    original_report = File.binread(@report)
    assert_equal 0, verify('--checked-report', @report)[0]
    File.write(@book, "= Book\n\n入力を取得します。\n")
    assert_equal 0, verify[0]
    code, report = verify('--checked-report', @report)
    assert_equal 1, code
    assert_includes report['issues'].map { |i| i['kind'] }, 'checked-report-stale'
    assert_equal original_report, File.binread(@report)
    assert_equal false, report['meaning_verified']
    assert_equal 2, cli('review', 'verify', @session, '--output', @report)[0]
  end

  def test_invalid_missing_and_failed_reports_are_input_errors
    scan("= Book\n\n入力を読み込みます。\n", '--tokenizer', 'literal')
    ['[]', '{}', '{', '{"passed":true}'].each do |content|
      File.write(@report, content)
      assert_equal 2, cli('review', 'verify', @session, '--checked-report', @report)[0]
    end
    assert_equal 2, cli('review', 'verify', @session, '--checked-report', File.join(@dir, 'missing'))[0]
    _, report = verify
    report['passed'] = false
    File.write(@report, JSON.generate(report))
    assert_equal 2, cli('review', 'verify', @session, '--checked-report', @report)[0]
  end

  def test_implementation_and_session_changes_invalidate_record
    scan("= Book\n\n入力を読み込みます。\n", '--tokenizer', 'literal')
    _, report = verify
    %w[implementation_sha256 manifest_sha256].each do |key|
      altered = Marshal.load(Marshal.dump(report))
      altered['verification_record'][key] = '0' * 64
      File.write(@report, JSON.generate(altered))
      assert_equal 1, verify('--checked-report', @report)[0]
    end
  end

  def test_protected_change_still_fails_and_baseline_is_immutable
    scan("= Book\n\n入力を読み込みます。\n\n[source]\n----\nできません\n----\n", '--tokenizer', 'literal')
    baseline = File.binread(File.join(@session, 'baseline/0.adoc'))
    File.write(@book, File.read(@book).sub('できません', 'できます'))
    code, report = verify
    assert_equal 1, code
    assert_empty report['japanese_change_review']['changes']
    assert_equal baseline, File.binread(File.join(@session, 'baseline/0.adoc'))
  end

  def test_heading_and_list_sessions_keep_their_separate_scopes
    { 'headings' => ['保存の条件', '保存の場合', 'body'],
      'lists' => ['保存の場合だけ実行します。', '保存を実行します。', 'heading'] }.each do |scope, (before, after, protected)|
      @session = File.join(@dir, scope)
      text = scope == 'headings' ? "= Book\n\n[[s]]\n== #{before}\n\nbody\n" : "= Book\n\n== heading\n\n* #{before}\n"
      scan(text, '--scope', scope, '--tokenizer', 'literal')
      File.write(@book, text.sub(before, after))
      code, report = verify
      assert_equal 0, code, report.inspect
      change = report['japanese_change_review']['changes'].fetch(0)
      assert_equal [before], change['before'].map { |e| e['text'] }
      refute_includes change['before'].map { |e| e['text'] }, protected
    end
  end

  def test_english_output_and_prompt_do_not_gain_japanese_features
    scan("= Book\n:lang: en\n\nThe worker saves the file.\n", '--lang', 'en')
    code, report = verify
    assert_equal 0, code
    refute report.key?('verification_record')
    refute report.key?('japanese_change_review')
    assert_equal 2, cli('review', 'verify', @session, '--checked-report', @report)[0]
    prompt = cli('review', 'prompt', @session)[1]
    refute_includes prompt, '--checked-report'
    assert AsciidocPubkit::Session.new(@session).send(:review_process, 'paragraph', 'revise').end_with?("Do not claim semantic correctness from those checks.\n")
  end

  def test_japanese_criteria_are_saved_and_revision_prompts_route_all_scopes
    shared = AsciidocPubkit::Writing.criteria('ja')
    assert_includes shared, 'actor and recipient, scope and conditions'
    assert_includes shared, 'procedures may repeat imperative endings'
    %w[prose headings lists].each do |scope|
      @session = File.join(@dir, scope)
      scan("= Book\n\n[[s]]\n== 保存\n\n入力を読み込みます。\n\n* 保存してください。\n", '--scope', scope, '--tokenizer', 'literal')
      prompt = cli('review', 'prompt', @session)[1]
      assert_includes prompt, 'actor and recipient, scope and conditions'
      assert_includes prompt, '--checked-report'
      refute_includes cli('review', 'prompt', @session, '--mode', 'diagnose')[1], '--checked-report'
    end
  end

  def test_equal_inventories_do_not_claim_semantic_success
    scan("= Book\n\n保存しません。削除します。\n", '--tokenizer', 'literal')
    File.write(@book, "= Book\n\n保存します。削除しません。\n")
    code, report = verify
    assert_equal 0, code
    change = report['japanese_change_review']['changes'].fetch(0)
    assert_empty change['review_candidates']
    assert_equal false, report['meaning_verified']
    assert_includes report['japanese_change_review']['limitations'], 'unchanged counts can hide changes'
  end

  def test_only_selection_excludes_other_sources_from_change_review_but_not_preservation
    included = File.join(@dir, 'included.adoc')
    File.write(included, "[[s]]\n== 保存\n\n保存しません。\n")
    scan("= Book\n\n入口を確認します。\n\ninclude::included.adoc[]\n", '--only', included, '--tokenizer', 'literal')
    File.write(included, "[[s]]\n== 保存\n\n保存します。\n")
    code, report = verify
    assert_equal 0, code
    assert_equal [included], report['japanese_change_review']['changes'].map { |c| c['file'] }
    assert_equal [@book, included].sort, report['verification_record']['sources'].keys.sort
    File.write(@book, File.read(@book).sub('入口を確認します。', '入口を調べます。'))
    code, report = verify
    assert_equal 1, code
    assert_includes report['issues'].map { |i| i['kind'] }, 'protected-content-changed'
    assert_equal [included], report['japanese_change_review']['changes'].map { |c| c['file'] }
  end

  def test_unchanged_source_has_no_change_candidates_and_current_content_hash
    scan("= Book\n\n入力を読み込みます。\n", '--tokenizer', 'literal')
    _, report = verify
    assert_empty report['japanese_change_review']['changes']
    assert_equal Digest::SHA256.file(@book).hexdigest, report['verification_record']['sources'][@book]
  end
end
