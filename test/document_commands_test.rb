# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require 'stringio'
require 'asciidoc_pubkit'

class DocumentCommandsTest < Minitest::Test
  def setup
    @dir = File.realpath(Dir.mktmpdir('pubkit-document-'))
    @book = File.join(@dir, 'book.adoc')
    File.write(@book, "= Test Book\n:lang: en\n\n== First\n\n=== Detail\n")
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  def cli(command, *args)
    out, err = StringIO.new, StringIO.new
    code = AsciidocPubkit::CLI.run(['document', command, *args], out: out, err: err)
    [code, out.string, err.string]
  end

  def test_toc_include_conditions_numbers_and_depth
    File.write(@book, "= Test\n:lang: en\n\ninclude::chapter.adoc[]\n\nifdef::extra[]\n== Extra\nendif::[]\n")
    File.write(File.join(@dir, 'chapter.adoc'), "== First\n\n=== Detail\n\n==== Deep\n")
    assert_equal [0, "First\n  Detail\n    Deep\n", ''], cli('toc', @book)
    assert_equal [0, "1. First\n1-1. Detail\n2. Extra\n", ''], cli('toc', @book, '--numbered', '--depth', '2', '-a', 'extra')
    %w[0 -1 2abc 1.5].each { |depth| assert_equal 2, cli('toc', @book, '--depth', depth)[0] }
  end

  def test_toc_parts_and_code_headings
    File.write(@book, "= Test\n:doctype: book\n\n= Part\n\n== Chapter\n\n=== Section\n\n----\n== Code\n----\n")
    assert_equal [0, "Part\n  Chapter\n    Section\n", ''], cli('toc', @book)
    assert_equal [0, "1. Part\n1-1. Chapter\n", ''], cli('toc', @book, '-n', '--depth', '1')
  end

  def test_info_metadata_without_language_gate
    File.write(@book, "= Book\nJane Doe\n:lang: en\n:subtitle: Sub\n:description: Text, with commas\n:uuid: 123\n\n== Intro\n")
    code, out, err = cli('info', @book, '--json')
    assert_equal 0, code, err
    metadata = JSON.parse(out)
    assert_equal 'Book', metadata['doctitle']
    assert_equal 'Jane Doe', metadata['author']
    assert_equal 'en', metadata['lang']
    assert_equal 'Text, with commas', metadata['description']
    assert_equal '', metadata['producer']
  end

  def test_xrefs_ids_includes_attributes_lists_and_protected_code
    chapter = File.join(@dir, 'chapter.adoc')
    File.write(@book, "= Book\n:target: missing\n\ninclude::chapter.adoc[]\n")
    File.write(chapter, <<~ADOC)
      [[known]]
      == Known

      <<known>> and xref:_generated[] and xref:chapter.adoc#known[].
      <<{target},Label>> and xref:missing[].
      xref:other.adoc#external[] and xref:https://example.com/#remote[].
      \\xref:escaped[]

      * xref:list-missing[]

      // xref:comment[]
      ----
      xref:code[]
      ----

      == Generated
    ADOC
    code, out, err = cli('check-xrefs', @book, '--json')
    assert_equal 1, code, err
    missing = JSON.parse(out)
    assert_equal %w[list-missing missing], missing.map { |m| m['refid'] }.sort
    assert missing.all? { |m| m['file'] == chapter && m['line'].positive? }
    File.write(chapter, "== Known\n\n<<_known>>\n")
    assert_equal [0, '', ''], cli('check-xrefs', @book)
  end

  def test_index_sorting_normalization_and_duplicate_precedence
    File.write(@book, "[#z]\n= Zebra\n")
    File.write(File.join(@dir, 'alpha.adoc'), "[#a]\n= Alpha (アルファ): Subtitle\n")
    FileUtils.mkdir_p(File.join(@dir, 'nested'))
    File.write(File.join(@dir, 'nested', 'alpha.adoc'), "[#duplicate]\n= ALPHA\n")
    File.write(File.join(@dir, 'japanese.adoc'), "[#j]\n= 日本語\n")
    File.write(File.join(@dir, 'no-id.adoc'), "= Missing ID\n")
    FileUtils.mkdir_p(File.join(@dir, '.hidden'))
    File.write(File.join(@dir, '.hidden', 'bad.adoc'), "include::missing[]\n")
    code, out, err = cli('index', @dir, '--title', 'Index')
    assert_equal 0, code, err
    assert_equal "[#book-index]\n= Index\n\n[discrete]\n=== A\n* <<a,Alpha>>\n\n[discrete]\n=== Z\n* <<z,Zebra>>\n", out
  end

  def test_xrefs_in_tables_and_nested_include_paths
    FileUtils.mkdir_p(File.join(@dir, 'chapters'))
    chapter = File.join(@dir, 'chapters', 'one.adoc')
    File.write(@book, "= Book\n\ninclude::chapters/one.adoc[]\n")
    File.write(chapter, "[[known]]\n== Known\n\nxref:one.adoc#known[]\n\n|===\n|xref:table-missing[]\n|===\n")
    code, out, err = cli('check-xrefs', @book, '--json')
    assert_equal 1, code, err
    missing = JSON.parse(out)
    assert_equal ['table-missing'], missing.map { |m| m['refid'] }
    assert_equal chapter, missing.first['file']
    assert_equal 7, missing.first['line']
  end

  def test_remote_and_outside_includes_fail_before_output
    File.write(@book, "= Book\n:allow-uri-read:\n\ninclude::https://example.invalid/book.adoc[]\n")
    code, out, err = cli('toc', @book)
    assert_equal 2, code
    assert_empty out
    assert_includes err, 'Remote includes are not supported'
    File.write(@book, "= Book\n\ninclude::../outside.adoc[]\n")
    assert_equal 2, cli('toc', @book)[0]
    assert_equal 2, cli('toc', @book, '--base-dir', File.join(@dir, 'missing'))[0]
  end

  def test_index_boundary_output_and_failure_are_transactional
    FileUtils.mkdir_p(File.join(@dir, 'nested'))
    File.write(File.join(@dir, 'title.adoc'), "[#shared]\n= Shared\n")
    File.write(File.join(@dir, 'nested', 'entry.adoc'), "include::title.adoc[]\n")
    output = File.join(@dir, 'index.adoc')
    assert_equal 0, cli('index', @dir, '--output', output)[0]
    assert_equal 1, File.read(output).scan('<<shared,Shared>>').length
    File.delete(output)
    File.write(File.join(@dir, 'broken.adoc'), "include::missing.adoc[]\n")
    assert_equal 2, cli('index', @dir, '--output', output)[0]
    refute File.exist?(output)
    assert_equal 2, cli('index', @book)[0]
  end

  def test_output_preservation_and_input_errors
    output = File.join(@dir, 'outline.txt')
    before = File.binread(@book)
    assert_equal 0, cli('toc', @book, '--output', output)[0]
    assert_equal "First\n  Detail\n", File.read(output)
    assert_equal 2, cli('toc', @book, '--output', output)[0]
    assert_equal before, File.binread(@book)
    link = File.join(@dir, 'link')
    File.symlink(File.join(@dir, 'absent'), link)
    assert_equal 2, cli('info', @book, '--output', link)[0]
    assert_equal 2, cli('toc')[0]
    assert_equal 2, cli('toc', @book, @book)[0]
    assert_equal 2, cli('toc', @book, '--agent', 'codex')[0]
    assert_equal 2, cli('toc', @book, '-a', 'allow-uri-read')[0]
    assert_equal 0, cli('toc', '--help')[0]
  end

  def test_parse_errors_and_source_boundary
    File.write(@book, "= Book\n\ninclude::missing.adoc[]\n")
    code, out, err = cli('toc', @book)
    assert_equal 2, code
    assert_empty out
    assert_includes err, 'include file not found'
    Dir.mktmpdir do |outside|
      target = File.join(outside, 'secret.adoc')
      File.write(target, "== Outside\n")
      File.symlink(target, File.join(@dir, 'linked.adoc'))
      File.write(@book, "= Book\n\ninclude::linked.adoc[]\n")
      assert_equal 2, cli('toc', @book)[0]
    end
  end
end
