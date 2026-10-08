# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require 'stringio'
require 'asciidoc_pubkit'

class ReviewScopesTest < Minitest::Test
  def setup
    @dir = File.realpath(Dir.mktmpdir('pubkit-scopes-'))
    @book = File.join(@dir, 'book.adoc')
    @session = File.join(@dir, 'session')
    @source = "= Book\n:lang: ja\n\n== 手動圧縮の入口\n\n本文の入口です。\n\n* link:https://example.com[資料]: 入口を説明します。\n* 通知を確認します。\n"
    File.write(@book, @source)
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  def cli(*args)
    out, err = StringIO.new, StringIO.new
    code = AsciidocPubkit::CLI.run(args, out: out, err: err, input: StringIO.new)
    [code, out.string, err.string]
  end

  def scan(scope, *args)
    result = cli('review', 'scan', @book, '--scope', scope, '--tokenizer', 'literal', '--output', @session, *args)
    assert_equal 0, result[0], result.inspect
  end

  def verify
    code, out, err = cli('review', 'verify', @session)
    assert_empty err
    [code, JSON.parse(out)]
  end

  def test_default_heading_anchor_permission_preserves_ids_and_baseline
    scan('headings')
    manifest = JSON.parse(File.read(File.join(@session, 'manifest.json')))
    assert_equal true, manifest['settings']['preserve_heading_ids']
    session = AsciidocPubkit::Session.new(@session)
    prompt = session.prompt('revise')
    assert_includes prompt, 'that exact anchor'
    assert_includes prompt, '[#_手動圧縮の入口]'
    before = Dir.glob(File.join(@session, '**', '*')).select { |f| File.file?(f) }.to_h { |f| [f, File.binread(f)] }
    File.write(@book, @source.sub('== 手動圧縮の入口', "[#_手動圧縮の入口]\n== 手動圧縮と拡張からの起動"))
    code, report = verify
    assert_equal 0, code, report.inspect
    assert_equal false, report['meaning_verified']
    before.each { |f, bytes| assert_equal bytes, File.binread(f) }
  end

  def test_heading_rename_without_preserving_id_is_rejected
    scan('headings')
    File.write(@book, @source.sub('== 手動圧縮の入口', '== 起動方法'))
    assert_equal 1, verify.first
  end

  def test_wrong_ids_unrelated_anchors_and_body_edits_are_rejected
    scan('headings')
    [
      @source.sub('== 手動圧縮の入口', "[#wrong]\n== 起動方法"),
      @source.sub('本文の入口です。', "[#_手動圧縮の入口]\n本文の入口です。"),
      @source.sub('== 手動圧縮の入口', "[#_手動圧縮の入口]\n== 起動方法").sub('本文の入口です。', '本文を変更しました。'),
      @source.sub('== 手動圧縮の入口', "[#_手動圧縮の入口]\n[#_手動圧縮の入口]\n== 起動方法")
    ].each do |changed|
      File.write(@book, changed)
      assert_equal 1, verify.first
    end
  end

  def test_existing_explicit_anchor_is_not_editable
    File.write(@book, @source.sub('== 手動圧縮の入口', "[#fixed]\n== 手動圧縮の入口"))
    scan('headings')
    heading = JSON.parse(File.read(File.join(@session, 'document.json')))['headings'].first
    assert_nil heading['permitted_id_anchor']
    File.write(@book, @source.sub('== 手動圧縮の入口', "[#changed]\n== 起動方法"))
    assert_equal 1, verify.first
  end

  def test_removed_anchor_flag_is_rejected
    %w[prose headings lists].each do |scope|
      code, _, err = cli('review', 'scan', @book, '--scope', scope, '--preserve-heading-ids')
      assert_equal 2, code
      assert_includes err, 'invalid option: --preserve-heading-ids'
    end
  end

  def test_heading_depth_is_saved_and_protects_deeper_titles
    File.write(@book, "= Book\n:lang: ja\n\n== 設定\n\n紹介文です。\n\n=== 読み込み\n\n詳細な本文です。\n")
    scan('headings', '--depth', '1')
    doc = JSON.parse(File.read(File.join(@session, 'document.json')))
    manifest = JSON.parse(File.read(File.join(@session, 'manifest.json')))
    assert_equal 1, manifest['settings']['heading_depth']
    assert_equal ['設定'], doc['headings'].map { |h| h['text'] }
    assert_equal %w[設定 読み込み], doc['outline'].map { |h| h['text'] }
    assert doc['coverage'].any? { |c| c['reason'] == 'Outside the saved heading depth.' }
    assert_equal 2, doc['paragraphs'].length
    original = File.read(@book)
    File.write(@book, original.sub('== 設定', "[#_設定]\n== 設定の基本"))
    assert_equal 0, verify.first
    File.write(@book, original.sub('=== 読み込み', '=== 読み込みの手順'))
    assert_equal 1, verify.first
  end

  def test_heading_depth_cannot_hide_reuse_at_a_deeper_level
    shared = File.join(@dir, 'shared.adoc')
    File.write(shared, "== 共通\n\n説明です。\n")
    File.write(@book, "= Book\n:lang: ja\n\n== 親\n\ninclude::shared.adoc[leveloffset=+1]\n\ninclude::shared.adoc[leveloffset=+2]\n")
    scan('headings', '--depth', '2')
    doc = JSON.parse(File.read(File.join(@session, 'document.json')))
    refute doc['headings'].any? { |h| h['file'] == shared }
    assert doc['coverage'].any? { |c| c['reason'].include?('reused') }
    File.write(shared, File.read(shared).sub('共通', '変更'))
    assert_equal 1, verify.first
  end

  def test_heading_depth_configuration_precedence_and_validation
    config = File.join(@dir, 'config.yml')
    File.write(@book, "= Book\n:lang: ja\n\n== 親\n\n=== 子\n")
    File.write(config, { 'review' => { 'heading_depth' => 1 } }.to_yaml)
    scan('headings', '--config', config, '--depth', '2')
    manifest = JSON.parse(File.read(File.join(@session, 'manifest.json')))
    assert_equal 2, manifest['settings']['heading_depth']
    assert_equal 2, JSON.parse(File.read(File.join(@session, 'document.json')))['headings'].length
    scan('headings', '--config', config, '--yes')
    assert_equal 1, JSON.parse(File.read(File.join(@session, 'manifest.json')))['settings']['heading_depth']
    %w[0 -1 1.5 2abc +1].each do |depth|
      assert_equal 2, cli('review', 'scan', @book, '--scope', 'headings', '--depth', depth).first
    end
    assert_equal 2, cli('review', 'scan', @book, '--depth', '1').first
    assert_equal 2, cli('review', 'scan', @book, '--scope', 'lists', '--depth', '1').first
    [0, -1, 1.5, '1', nil].each do |depth|
      File.write(config, { 'review' => { 'heading_depth' => depth } }.to_yaml)
      assert_equal 2, cli('review', 'scan', @book, '--scope', 'headings', '--config', config).first
    end
    File.write(config, { 'review' => { 'heading_depth' => 1 } }.to_yaml)
    other = File.join(@dir, 'prose')
    assert_equal 0, cli('review', 'scan', @book, '--config', config, '--tokenizer', 'literal', '--output', other).first
    refute JSON.parse(File.read(File.join(other, 'manifest.json')))['settings'].key?('heading_depth')
  end

  def test_outline_view_preserves_evidence_and_does_not_expand_permissions
    File.write(@book, "= Book\n:lang: ja\n:chno: 1\n\n== 第{chno}章\n\n章の紹介です。\n\n=== 設定\n\n設定の本文です。\n\n==== 詳細\n\n詳細な本文です。\n")
    scan('headings', '--depth', '2')
    before = Dir.glob(File.join(@session, '**', '*')).select { |f| File.file?(f) }.to_h { |f| [f, File.binread(f)] }
    code, out, err = cli('review', 'prompt', @session, '--view', 'outline', '--mode', 'diagnose')
    assert_equal 0, code, err
    assert_includes out, '# Japanese outline review'
    assert_includes out, '## Whole-outline assessment'
    assert_includes out, '1. 第1章 [reference-only;'
    assert_includes out, '1-1. 設定 [editable;'
    assert_includes out, '1-1-1. 詳細 [reference-only;'
    assert_includes out, 'Selected heading depth: 2'
    assert_includes out, 'Do not edit files.'
    assert_includes out, 'structure proposals only'
    assert_includes out, 'meaning_verified: false'
    %w[章の紹介です。 設定の本文です。 詳細な本文です。].each { |text| assert_equal 1, out.scan(text).length }
    before.each { |file, bytes| assert_equal bytes, File.binread(file) }
    full = AsciidocPubkit::Session.new(@session).prompt('revise')
    assert_includes full, '# Japanese heading review'
    refute_includes full, '## Whole-outline assessment'
    assert_equal 0, verify.first
    File.write(@book, File.read(@book).sub('設定の本文です。', '変更しました。'))
    assert_equal 1, verify.first
    assert_equal 2, cli('review', 'prompt', @session, '--view', 'outline').first
  end

  def test_outline_view_rejects_other_scopes_and_unknown_views
    scan('prose')
    assert_equal 2, cli('review', 'prompt', @session, '--view', 'outline').first
    assert_equal 2, cli('review', 'prompt', @session, '--view', 'unknown').first
    assert_equal 0, cli('review', 'prompt', @session, '--view', 'full').first
    scan('lists', '--yes')
    assert_equal 2, cli('review', 'prompt', @session, '--view', 'outline').first
  end

  def test_outline_criteria_are_frozen_and_old_sessions_keep_full_view
    scan('headings')
    session = AsciidocPubkit::Session.new(@session)
    manifest_path = File.join(@session, 'manifest.json')
    manifest = JSON.parse(File.read(manifest_path))
    assert_includes manifest['outline_criteria'], '## Whole-outline assessment'
    original = AsciidocPubkit::Writing.method(:outline_criteria)
    begin
      AsciidocPubkit::Writing.define_singleton_method(:outline_criteria) { |_language| 'Changed runtime criteria.' }
      assert_includes session.prompt('diagnose', view: 'outline'), manifest['outline_criteria'].rstrip
      refute_includes session.prompt('diagnose', view: 'outline'), 'Changed runtime criteria.'
    ensure
      AsciidocPubkit::Writing.define_singleton_method(:outline_criteria, original)
    end
    # Model metadata from a session created before outline view existed.
    # Source snapshots and document/findings integrity hashes remain unchanged.
    manifest.delete('outline_criteria')
    File.write(manifest_path, JSON.generate(manifest))
    assert_equal 0, cli('review', 'prompt', @session).first
    assert_equal 0, verify.first
    code, _, err = cli('review', 'prompt', @session, '--view', 'outline')
    assert_equal 2, code
    assert_includes err, 'without replacing the existing baseline'
  end

  def test_list_scope_maps_original_link_text_and_columns
    scan('lists')
    doc = JSON.parse(File.read(File.join(@session, 'document.json')))
    assert_equal 2, doc['paragraphs'].length
    item = doc['paragraphs'].first
    assert_equal 'link:https://example.com[資料]: 入口を説明します。', item['text']
    assert_equal 3, item['column']
    assert_equal 'list-item', item['kind']
    findings = JSON.parse(File.read(File.join(@session, 'findings.json')))
    entry = findings.find { |f| f['match'] == '入口' }
    refute_nil entry
    assert_equal @source.lines[7].index('入口') + 1, entry['column']
    prompt = AsciidocPubkit::Session.new(@session).prompt('revise')
    assert_includes prompt, 'Preserve list markers'
    assert_includes prompt, 'single-line outline list item text'
    refute_includes prompt, '本文の入口です。'
    File.write(@book, @source.sub('入口を説明します。', '起動方法を説明します。'))
    assert_equal 0, verify.first
  end

  def test_list_scope_protects_links_markers_and_running_prose
    scan('lists')
    [
      @source.sub('https://example.com', 'https://other.example'),
      @source.sub('* link:', '. link:'),
      @source.sub('本文の入口です。', '本文を変更します。'),
      @source.sub('入口を説明します。', "起動方法を説明します。\n別の段落です。")
    ].each do |changed|
      File.write(@book, changed)
      assert_equal 1, verify.first
    end
  end

  def test_unsupported_list_content_has_coverage_and_is_protected
    File.write(@book, "= Book\n:lang: ja\n\n* 複数行の入口\n  続きです。\n\n用語:: 説明の入口です。\n")
    scan('lists')
    doc = JSON.parse(File.read(File.join(@session, 'document.json')))
    assert_empty doc['paragraphs']
    refute_empty doc['coverage']
    File.write(@book, File.read(@book).sub('続きです。', '変更です。'))
    assert_equal 1, verify.first
  end

  def test_ordered_and_nested_list_text
    File.write(@book, "= Book\n:lang: ja\n\n. 手順の入口です。\n.. 下位の入口です。\n. 次の手順です。\n")
    scan('lists')
    doc = JSON.parse(File.read(File.join(@session, 'document.json')))
    assert_equal ['. ', '.. ', '. '], doc['paragraphs'].map { |p| p['prefix'] }
    File.write(@book, File.read(@book).sub('下位の入口です。', '下位の起動方法です。'))
    assert_equal 0, verify.first
  end
  def test_list_scope_runs_with_default_mecab
    result = cli('review', 'scan', @book, '--scope', 'lists', '--output', @session)
    assert_equal 0, result[0], result.inspect
    manifest = JSON.parse(File.read(File.join(@session, 'manifest.json')))
    assert_equal 'mecab', manifest['analysis']['engine']
    assert_equal 0, verify.first
  end

  def test_checklists_and_compound_items_remain_protected
    File.write(@book, "= Book\n:lang: ja\n\n* [ ] 確認の入口です。\n* 複合項目です。\n+\n[source,ruby]\n----\nputs '入口'\n----\n")
    scan('lists')
    doc = JSON.parse(File.read(File.join(@session, 'document.json')))
    assert_empty doc['paragraphs']
    refute_empty doc['coverage']
  end

  def test_reused_source_items_cannot_be_edited_independently
    part = File.join(@dir, 'part.adoc')
    File.write(part, "* 入口を説明します。\n")
    File.write(@book, "= Book\n:lang: ja\n\ninclude::part.adoc[]\n\n別の段落です。\n\ninclude::part.adoc[]\n")
    scan('lists')
    doc = JSON.parse(File.read(File.join(@session, 'document.json')))
    assert_empty doc['paragraphs']
    assert doc['coverage'].any? { |c| c['reason'].include?('reused') }
  end

  def test_include_boundary_mapping_honors_only_and_exclude
    part = File.join(@dir, 'part.adoc')
    File.write(part, "* リストの入口です。\n")
    File.write(@book, "= Book\n:lang: ja\n\ninclude::part.adoc[]\n")
    scan('lists', '--only', part)
    doc = JSON.parse(File.read(File.join(@session, 'document.json')))
    assert_equal [part], doc['paragraphs'].map { |p| p['file'] }
    File.write(part, "* リストの起動方法です。\n")
    assert_equal 0, verify.first
    File.write(File.join(@dir, '.asciidoc-pubkit.yml'), "review:\n  exclude: [part.adoc]\n")
    scan('lists', '--yes')
    doc = JSON.parse(File.read(File.join(@session, 'document.json')))
    assert_empty doc['paragraphs']
  end

  def test_ambiguous_include_boundary_mapping_is_not_guessed
    File.write(File.join(@dir, 'part.adoc'), "* 入口です。\n")
    File.write(File.join(@dir, 'other.adoc'), "* 入口です。\n")
    File.write(@book, "= Book\n:lang: ja\n\ninclude::part.adoc[]\n\n本文です。\n\ninclude::other.adoc[]\n")
    scan('lists')
    doc = JSON.parse(File.read(File.join(@session, 'document.json')))
    assert_empty doc['paragraphs']
    refute_empty doc['coverage']
  end

  def test_other_scopes_do_not_authorize_heading_anchors
    %w[prose lists].each do |scope|
      settings = AsciidocPubkit::Settings.new(@book, scope: scope, tokenizer: 'literal')
      assert_equal false, settings.data['preserve_heading_ids']
    end
  end

  def test_saved_disabled_setting_is_not_reinterpreted
    settings = AsciidocPubkit::Settings.new(@book, scope: 'headings', tokenizer: 'literal')
    saved_settings = settings.data.merge('preserve_heading_ids' => false)
    document = AsciidocPubkit::Document.new(@book, saved_settings)
    assert_nil document.headings.first['permitted_id_anchor']
  end

  def test_prose_scan_and_prompt_direct_reviewers_to_separate_list_review
    code, out, err = cli('review', 'scan', @book, '--scope', 'prose', '--tokenizer', 'literal', '--output', @session)
    assert_equal 0, code, err
    assert_includes out, 'List text is excluded.'
    assert_includes out, '--scope lists'
    prompt = AsciidocPubkit::Session.new(@session).prompt('revise')
    assert_includes prompt, 'List text requires a separate review scan with --scope lists.'
    assert_includes prompt, 'Preserve this baseline and use a different session directory'
    refute_includes prompt, 'link:https://example.com[資料]'
  end

end
