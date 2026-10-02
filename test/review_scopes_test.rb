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

  def test_heading_anchor_permission_preserves_ids_and_baseline
    scan('headings', '--preserve-heading-ids')
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

  def test_default_heading_scope_still_rejects_anchor_additions
    scan('headings')
    File.write(@book, @source.sub('== 手動圧縮の入口', "[#_手動圧縮の入口]\n== 起動方法"))
    assert_equal 1, verify.first
  end

  def test_wrong_ids_unrelated_anchors_and_body_edits_are_rejected
    scan('headings', '--preserve-heading-ids')
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
    scan('headings', '--preserve-heading-ids')
    heading = JSON.parse(File.read(File.join(@session, 'document.json')))['headings'].first
    assert_nil heading['permitted_id_anchor']
    File.write(@book, @source.sub('== 手動圧縮の入口', "[#changed]\n== 起動方法"))
    assert_equal 1, verify.first
  end

  def test_anchor_flag_requires_heading_scope
    %w[prose lists].each do |scope|
      code, _, err = cli('review', 'scan', @book, '--scope', scope, '--preserve-heading-ids')
      assert_equal 2, code
      assert_includes err, '--preserve-heading-ids requires --scope headings'
    end
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

end
