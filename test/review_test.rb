# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require 'stringio'
require 'asciidoc_pubkit'

class ReviewTest < Minitest::Test
  def setup
    @dir = File.realpath(Dir.mktmpdir('pubkit-test-'))
    @book = File.join(@dir, 'book.adoc')
    @chapter = File.join(@dir, 'chapter.adoc')
    @session = File.join(@dir, 'session')
    File.write(@book, "= Test Book\n:lang: ja\n\ninclude::chapter.adoc[]\n")
    File.write(@chapter, <<~ADOC)
      == Introduction

      重要なのは、境界を整理することです。
      コストを確認します。

      [source,ruby]
      ----
      puts "境界"
      ----

      `契約`とlink:https://example.com[境界]を参照します。

      == Next Section

      入力を読み込み、結果を保存します。
    ADOC
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  def cli(*args)
    out = StringIO.new
    err = StringIO.new
    code = AsciidocPubkit::CLI.run(args, out: out, err: err)
    [code, out.string, err.string]
  end

  def scan(*args)
    result = cli('review', 'scan', @book, '--output', @session, *args)
    assert_equal 0, result[0], result.inspect
    result
  end

  def json(name)
    JSON.parse(File.read(File.join(@session, name)))
  end

  def verify
    result = cli('review', 'verify', @session)
    [result[0], JSON.parse(result[1])]
  end

  def test_scan_resolves_include_sources_and_masks_protected_inline_content
    scan
    findings = json('findings.json')
    assert_equal 3, findings.length
    assert findings.all? { |f| f['file'] == @chapter }
    boundary = findings.find { |f| f['match'] == '境界' }
    assert_equal 3, boundary['line']
    assert_equal 7, boundary['column']
    assert_equal [@book, @chapter].sort, json('manifest.json')['sources'].map { |s| s['path'] }.sort
  end

  def test_include_end_location_is_recovered_by_matching_source
    File.write(@chapter, "== Chapter\n\n境界を確認します。\n")
    scan
    assert_equal @chapter, json('findings.json').first['file']
    assert_equal 3, json('findings.json').first['line']
  end

  def test_prompt_contains_context_instructions_and_dispositions
    scan
    code, output, error = cli('review', 'prompt', @session, '--mode', 'diagnose')
    assert_equal 0, code, error
    assert_includes output, 'Do not edit files.'
    assert_includes output, 'needs-evidence'
    assert_includes output, 'previous_paragraph'
    assert_includes output, '重要なのは'
  end

  def test_prompt_rejects_stale_sources_and_modified_artifacts
    scan
    File.open(@chapter, 'a') { |f| f.puts 'Additional prose.' }
    code, _, error = cli('review', 'prompt', @session)
    assert_equal 2, code
    assert_includes error, 'Sources have changed'
    File.write(File.join(@session, 'findings.json'), '[]')
    code, _, error = cli('review', 'prompt', @session)
    assert_equal 2, code
    assert_includes error, 'artifact has changed'
  end

  def test_prose_edit_passes_and_candidates_do_not_fail_verification
    scan
    assert_equal 0, verify.first
    content = File.read(@chapter).sub('重要なのは、境界を整理することです。', '関数は入力値を検査します。')
    File.write(@chapter, content)
    code, report = verify
    assert_equal 0, code, report.inspect
    refute report['meaning_verified']
    assert_equal [@chapter], report['changed_files']
    refute_empty report['findings']
  end

  def test_code_change_fails_verification
    scan
    File.write(@chapter, File.read(@chapter).sub('puts "境界"', 'puts "changed"'))
    code, report = verify
    assert_equal 1, code
    assert report['issues'].any? { |i| i['kind'] == 'protected-content-changed' }
  end

  def test_inline_reference_change_fails_verification
    scan
    File.write(@chapter, File.read(@chapter).sub('https://example.com', 'https://example.org'))
    assert_equal 1, verify.first
  end

  def test_heading_change_fails_verification
    scan
    File.write(@chapter, File.read(@chapter).sub('== Introduction', '== Changed'))
    assert_equal 1, verify.first
  end

  def test_missing_source_is_a_failed_verification
    scan
    File.unlink(@chapter)
    code, report = verify
    assert_equal 1, code
    refute_empty report['issues']
  end

  def test_config_glossary_allows_exclusion_and_cli_override
    File.write(File.join(@dir, 'glossary.yml'), "goroutine:\n  - ゴルーチン\n")
    File.write(File.join(@dir, '.asciidoc-pubkit.yml'), <<~YAML)
      review:
        style: dearu
        glossary: glossary.yml
        allows: [境界]
    YAML
    File.open(@chapter, 'a') { |f| f.puts "\nゴルーチンを起動します。\n" }
    scan('--style', 'preserve')
    findings = json('findings.json')
    refute findings.any? { |f| f['match'] == '境界' }
    assert findings.any? { |f| f['rule'] == 'glossary-variant' }
    refute findings.any? { |f| f['rule'] == 'style-candidate' }
  end

  def test_only_keeps_book_attributes_and_rejects_unincluded_files
    File.write(@book, "= Book\n:reviewed:\n\nifdef::reviewed[]\ninclude::chapter.adoc[]\nendif::[]\n\ninclude::other.adoc[]\n")
    other = File.join(@dir, 'other.adoc')
    File.write(other, "== Other\n\nコストを整理します。\n")
    scan('--only', @chapter)
    assert json('findings.json').all? { |f| f['file'] == @chapter }
    File.write(other, "== Other\n\n変更しました。\n")
    assert_equal 1, verify.first
  end

  def test_scan_never_overwrites_an_existing_session
    scan
    code, _, error = cli('review', 'scan', @book, '--output', @session)
    assert_equal 2, code
    assert_includes error, 'already exists'
  end

  def test_missing_include_is_not_a_successful_scan
    File.unlink(@chapter)
    code, _, error = cli('review', 'scan', @book, '--output', @session)
    assert_equal 2, code
    assert_includes error, 'diagnostics'
    refute File.exist?(@session)
  end

  def test_numeric_change_requires_manual_semantic_review
    File.write(@chapter, "== Chapter\n\n10件を処理します。\n")
    scan
    File.write(@chapter, "== Chapter\n\n20件を処理します。\n")
    code, report = verify
    assert_equal 0, code
    assert_equal 'numbers-changed', report['notices'].first['kind']
  end

  def test_invalid_config_is_a_user_facing_error
    File.write(File.join(@dir, '.asciidoc-pubkit.yml'), "review:\n  attributes: []\n")
    code, _, error = cli('review', 'scan', @book, '--output', @session)
    assert_equal 2, code
    assert_includes error, 'attributes must be a mapping'
  end

  def test_excluded_paragraphs_are_not_scanned
    File.write(File.join(@dir, '.asciidoc-pubkit.yml'), "review:\n  exclude: [chapter.adoc]\n")
    scan
    assert_empty json('findings.json')
    assert_empty json('document.json')['paragraphs']
  end

  def test_cli_help_version_and_invalid_command
    assert_equal 0, cli('--help').first
    assert_equal 0, cli('review', 'scan', '--help').first
    assert_equal "#{AsciidocPubkit::VERSION}\n", cli('--version')[1]
    assert_equal 2, cli('review', 'unknown').first
  end

  def test_repeated_predicates_are_detected_without_identical_sentences
    File.write(@chapter, "== Chapter\n\n入力を確認します。出力を確認します。結果を確認します。\n")
    scan
    assert json('findings.json').any? { |f| f['rule'] == 'repeated-ending' }
  end

  def test_list_continuations_and_quoted_spans_are_excluded
    File.write(@chapter, <<~ADOC)
      == Chapter

      * 境界を確認します。
      +
      コストを整理します。

      「境界」と『契約』を参照します。
    ADOC
    scan
    assert_empty json('findings.json')
  end

  def test_only_rejects_an_existing_but_unincluded_file
    unused = File.join(@dir, 'unused.adoc')
    File.write(unused, 'Unused.')
    code, _, error = cli('review', 'scan', @book, '--only', unused, '--output', @session)
    assert_equal 2, code
    assert_includes error, 'included in the parsed document'
  end

  def test_attribute_only_include_is_captured_and_checked_for_staleness
    attributes = File.join(@dir, 'attributes.adoc')
    File.write(attributes, ":edition: print\n")
    File.write(@book, "= Book\ninclude::attributes.adoc[]\n\ninclude::chapter.adoc[]\n")
    scan
    assert_includes json('manifest.json')['sources'].map { |s| s['path'] }, attributes
    File.write(attributes, ":edition: digital\n")
    assert_equal 2, cli('review', 'prompt', @session).first
  end

  def test_code_whitespace_is_preserved
    scan
    File.write(@chapter, File.read(@chapter).sub('puts "境界"', "puts \"境界\"  \n"))
    assert_equal 1, verify.first
  end

  def test_output_file_cannot_overwrite_manuscript
    scan
    before = File.binread(@book)
    code, = cli('review', 'prompt', @session, '--output', @book)
    assert_equal 2, code
    assert_equal before, File.binread(@book)
  end

  def test_added_include_fails_verification
    scan
    extra = File.join(@dir, 'extra.adoc')
    File.write(extra, "== Extra\n\n追加の説明です。\n")
    File.open(@book, 'a') { |file| file.puts "\ninclude::extra.adoc[]" }
    code, report = verify
    assert_equal 1, code
    assert report['issues'].any? { |issue| issue['kind'] == 'source-set-changed' }
  end

  def test_ambiguous_include_boundary_is_reported_instead_of_guessed
    File.write(@chapter, "== Chapter\n\n境界を確認します。\n")
    other = File.join(@dir, 'other.adoc')
    File.write(other, "== Other\n\n境界を確認します。\n")
    File.open(@book, 'a') { |file| file.puts "\ninclude::other.adoc[]" }
    scan
    assert json('document.json')['coverage'].any? { |notice| notice['reason'].include?('unambiguously') }
  end
end
