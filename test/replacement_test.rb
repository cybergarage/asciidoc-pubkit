# frozen_string_literal: true

require 'minitest/autorun'
require 'asciidoc_pubkit'
require 'tmpdir'
require 'stringio'

class ReplacementTest < Minitest::Test
  def setup
    @dir = File.realpath(Dir.mktmpdir('pubkit-replace-test-'))
    @book = File.join(@dir, 'book.adoc')
    @rules = File.join(@dir, 'rules.yml')
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  def rules(entries)
    File.write(@rules, { 'version' => 1, 'rules' => entries }.to_yaml)
  end

  def plan(**options)
    AsciidocPubkit::Replacement.new(@book, { rules: @rules }.merge(options))
  end

  def test_only_prose_is_replaced_and_original_bytes_are_preserved
    original = "= 題名／\r\n\r\n😀本文／と`コード／`、https://example.com／と「引用／」。\r\n次／。\r\n\r\n[source]\r\n----\r\n  code／\r\n----\r\n\r\n....\r\n  literal／\r\n....\r\n\r\n++++\r\npass／\r\n++++\r\n\r\n* list／\r\n\r\n|===\r\n|table／\r\n|===\r\n\r\n[quote]\r\n____\r\nquote／\r\n____\r\n"
    File.binwrite(@book, original)
    rules([{ 'expected' => '/', 'pattern' => '／' }])
    replacement = plan
    assert_equal 2, replacement.candidates.length
    assert_equal [3, 4], replacement.candidates.first.values_at(:line, :column)
    assert_equal original.b, File.binread(@book)
    assert_includes replacement.diff, '+😀本文/'
    replacement.apply
    assert_equal original.sub('😀本文／', '😀本文/').sub('次／', '次/').b, File.binread(@book)
  end

  def test_captures_specs_and_protected_overlap
    File.write(@book, "本文（任意）と（`code`）です。\n")
    rules([{ 'expected' => '($1)', 'pattern' => '/（([^（）\r\n]+)）/',
             'specs' => [{ 'from' => '設定（任意）', 'to' => '設定(任意)' }] }])
    replacement = plan
    assert_equal 1, replacement.candidates.length
    replacement.apply
    assert_equal "本文(任意)と（`code`）です。\n", File.read(@book)
  end

  def test_empty_result_literal_patterns_and_no_chaining
    File.write(@book, "本文AとCです。\n")
    rules([{ 'expected' => 'C', 'patterns' => ['A', 'B'] }, { 'expected' => '', 'pattern' => 'C' }])
    plan.apply
    assert_equal "本文Cとです。\n", File.read(@book)
  end

  def test_overlap_and_structure_changes_are_rejected_without_writes
    File.write(@book, "通常本文です。\n")
    original = File.read(@book)
    rules([{ 'expected' => '別', 'pattern' => '通常' }, { 'expected' => '別', 'pattern' => '常' }])
    assert_raises(AsciidocPubkit::Error) { plan }
    rules([{ 'expected' => '== ', 'pattern' => '通常' }])
    assert_raises(AsciidocPubkit::Error) { plan }
    rules([{ 'expected' => '`通常`', 'pattern' => '通常' }])
    assert_raises(AsciidocPubkit::Error) { plan }
    assert_equal original, File.read(@book)
  end

  def test_stale_sources_are_rejected
    File.write(@book, "本文／です。\n")
    rules([{ 'expected' => '/', 'pattern' => '／' }])
    replacement = plan
    File.write(@book, "新本文／です。\n")
    assert_raises(AsciidocPubkit::Error) { replacement.apply }
    assert_equal "新本文／です。\n", File.read(@book)
  end

  def test_relative_includes_and_only
    chapter = File.join(@dir, 'chapter.adoc')
    File.write(@book, "= Book\n\n本文／。\n\ninclude::chapter.adoc[]\n")
    File.write(chapter, "章本文／。\n")
    rules([{ 'expected' => '/', 'pattern' => '／' }])
    plan(only: chapter).apply
    assert_includes File.read(@book), '本文／'
    assert_equal "章本文/。\n", File.read(chapter)
  end

  def test_strict_rules_and_specs
    File.write(@book, "本文です。\n")
    invalid = [
      { 'expected' => 'X' },
      { 'expected' => 'X', 'pattern' => 'Y', 'options' => {} },
      { 'expected' => 'X', 'pattern' => '/Y/i' },
      { 'expected' => 'X', 'pattern' => '/(?=文)/' },
      { 'expected' => '$2', 'pattern' => '/(文)/' },
      { 'expected' => 'X', 'pattern' => '文', 'specs' => [{ 'from' => '文', 'to' => 'wrong' }] },
      { 'expected' => 'X', 'pattern' => '/\\p{Han}/' }
    ]
    invalid.each do |entry|
      rules([entry])
      assert_raises(AsciidocPubkit::Error, entry.inspect) { plan }
    end
  end

  def test_configuration_excludes_files_without_loading_review_rules_or_mecab
    chapter = File.join(@dir, 'chapter.adoc')
    File.write(@book, "= Book\n\n本文／。\n\ninclude::chapter.adoc[]\n")
    File.write(chapter, "章本文／。\n")
    config = File.join(@dir, '.asciidoc-pubkit.yml')
    File.write(config, { 'review' => { 'exclude' => ['chapter.adoc'], 'rules' => 'missing.yml',
                                     'mecab_command' => '/missing/mecab' } }.to_yaml)
    rules([{ 'expected' => '/', 'pattern' => '／' }])
    plan.apply
    assert_includes File.read(@book), '本文/'
    assert_equal "章本文／。\n", File.read(chapter)
  end

  def test_failed_second_install_restores_first_source
    chapter = File.join(@dir, 'chapter.adoc')
    File.write(@book, "= Book\n\n本文／。\n\ninclude::chapter.adoc[]\n")
    File.write(chapter, "章本文／。\n")
    rules([{ 'expected' => '/', 'pattern' => '／' }])
    originals = [@book, chapter].to_h { |path| [path, File.binread(path)] }
    replacement = plan
    rename = File.method(:rename)
    calls = 0
    failing_rename = lambda do |from, to|
      calls += 1
      raise Errno::EIO if calls == 2
      rename.call(from, to)
    end
    begin
      File.define_singleton_method(:rename, failing_rename)
      assert_raises(Errno::EIO) { replacement.apply }
    ensure
      File.define_singleton_method(:rename, rename)
    end
    originals.each { |path, raw| assert_equal raw, File.binread(path) }
    assert_empty Dir.glob(File.join(@dir, '.pubkit-replace-*'))
  end

  def test_line_breaks_and_symlink_entry_are_rejected
    File.write(@book, "本文／。\n次。\n")
    rules([{ 'expected' => "a\nb", 'pattern' => '／' }])
    assert_raises(AsciidocPubkit::Error) { plan }
    rules([{ 'expected' => '/', 'pattern' => '／' }])
    link = File.join(@dir, 'linked.adoc')
    File.symlink(@book, link)
    assert_raises(AsciidocPubkit::Error) { AsciidocPubkit::Replacement.new(link, rules: @rules) }
  end

  def test_cli_exit_codes_and_no_overwrite
    File.write(@book, "本文／。\n")
    rules([{ 'expected' => '/', 'pattern' => '／' }])
    out = StringIO.new
    err = StringIO.new
    assert_equal 1, AsciidocPubkit::CLI.run(['replace', 'check', @book, '--rules', @rules], out: out, err: err)
    assert_equal 0, AsciidocPubkit::CLI.run(['replace', 'diff', @book, '--rules', @rules], out: out, err: err)
    assert_includes File.read(@book), '／'
    assert_equal 2, AsciidocPubkit::CLI.run(['replace', 'diff', @book, '--rules', @rules, '-o', @book], out: out, err: err)
    assert_equal 0, AsciidocPubkit::CLI.run(['replace', 'apply', @book, '--rules', @rules], out: out, err: err)
    assert_equal 0, AsciidocPubkit::CLI.run(['replace', 'check', @book, '--rules', @rules], out: out, err: err)
    assert_equal 2, AsciidocPubkit::CLI.run(['replace', 'check', @book], out: out, err: err)
  end
end
