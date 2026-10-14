# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require 'stringio'
require 'asciidoc_pubkit'

class HeadingComparisonTest < Minitest::Test
  GUIDE = 'Distinguish comparison subjects from distinguishing actions'

  def cli(*args)
    out = StringIO.new
    err = StringIO.new
    code = AsciidocPubkit::CLI.run(args, out: out, err: err)
    [code, out.string, err.string]
  end

  def cases
    JSON.parse(File.read(File.join(__dir__, 'fixtures/heading_comparison.ja.json')))
  end

  def scan(source, session, tokenizer = 'literal')
    code, _, error = cli('review', 'scan', source, '--scope', 'headings',
                         '--tokenizer', tokenizer, '--output', session, '--no-input')
    assert_equal 0, code, error
  end

  def test_new_sessions_save_heading_guidance_and_old_sessions_do_not_reload_it
    Dir.mktmpdir('heading-comparison-snapshot-') do |dir|
      source = File.join(dir, 'book.adoc')
      File.write(source, "= Example\n\n[[comparison]]\n== 修正案の提示と編集実行の区別\n\n本文です。\n")
      historical = File.join(dir, 'historical')
      current = File.join(dir, 'current')
      original = AsciidocPubkit::Writing.method(:heading_criteria)
      begin
        AsciidocPubkit::Writing.define_singleton_method(:heading_criteria) { |*_args| 'Historical heading criteria' }
        scan(source, historical)
      ensure
        AsciidocPubkit::Writing.define_singleton_method(:heading_criteria, original)
      end
      scan(source, current)
      saved = JSON.parse(File.read(File.join(current, 'manifest.json'))).fetch('heading_criteria')
      assert_includes saved, GUIDE
      assert_includes saved, '違い'
      assert_includes saved, '相違'
      manifests = [historical, current].to_h do |session|
        [session, File.binread(File.join(session, 'manifest.json'))]
      end
      begin
        AsciidocPubkit::Writing.define_singleton_method(:heading_criteria) { |*_args| raise 'Must use saved heading criteria' }
        %w[full outline].each do |view|
          code, prompt, error = cli('review', 'prompt', historical, '--view', view)
          assert_equal 0, code, error
          assert_includes prompt, 'Historical heading criteria'
          refute_includes prompt, GUIDE
          code, prompt, error = cli('review', 'prompt', current, '--view', view)
          assert_equal 0, code, error
          assert_includes prompt, saved
        end
      ensure
        AsciidocPubkit::Writing.define_singleton_method(:heading_criteria, original)
      end
      manifests.each { |session, contents| assert_equal contents, File.binread(File.join(session, 'manifest.json')) }
    end
  end

  %w[literal mecab].each do |tokenizer|
    define_method("test_manual_examples_preserve_title_scope_and_ids_in_#{tokenizer}") do
      Dir.mktmpdir('heading-comparison-edits-') do |dir|
        source = File.join(dir, 'book.adoc')
        session = File.join(dir, 'session')
        accepted = cases.select { |item| item.fetch('expected_disposition') == 'accept' }
        original = "= Example\n\n" + accepted.map do |item|
          "[[#{item.fetch('id')}]]\n== #{item.fetch('source')}\n\n#{item.fetch('body')}\n\n"
        end.join
        File.write(source, original)
        scan(source, session, tokenizer)
        assert_equal original, File.read(source), 'Scanning must not rewrite examples'
        assert_empty JSON.parse(File.read(File.join(session, 'findings.json'))), 'No new detector rule'
        snapshots = Dir.glob(File.join(session, '**', '*')).select { |path| File.file?(path) }
                       .to_h { |path| [path, File.binread(path)] }
        revised = original.dup
        accepted.each { |item| revised.sub!("== #{item.fetch('source')}\n", "== #{item.fetch('revision')}\n") }
        File.write(source, revised)
        code, output, error = cli('review', 'verify', session)
        assert_equal 0, code, error
        report = JSON.parse(output)
        assert report.fetch('passed')
        assert_equal false, report.fetch('meaning_verified')
        accepted.each do |item|
          assert_includes File.read(source), "[[#{item.fetch('id')}]]\n== #{item.fetch('revision')}\n"
          assert_includes File.read(source), item.fetch('body')
        end
        # A body edit remains outside the heading session's permissions.
        File.write(source, revised.sub(accepted.first.fetch('body'), '本文を変更しました。'))
        code, output, = cli('review', 'verify', session)
        assert_equal 1, code
        refute JSON.parse(output).fetch('passed')
        snapshots.each { |path, contents| assert_equal contents, File.binread(path) }
      end
    end
  end

  def test_mechanical_verification_does_not_judge_the_rejected_guarantee_example
    item = cases.find { |example| example.fetch('expected_disposition') == 'reject' }
    Dir.mktmpdir('heading-comparison-limits-') do |dir|
      source = File.join(dir, 'book.adoc')
      session = File.join(dir, 'session')
      original = "= Example\n\n[[limits]]\n== #{item.fetch('source')}\n\n#{item.fetch('body')}\n"
      File.write(source, original)
      scan(source, session)
      File.write(source, original.sub("== #{item.fetch('source')}", "== #{item.fetch('revision')}"))
      code, output, error = cli('review', 'verify', session)
      assert_equal 0, code, error
      report = JSON.parse(output)
      assert report.fetch('passed'), 'Title preservation cannot detect unsupported promises'
      assert_equal false, report.fetch('meaning_verified')
      assert_includes File.read(source), item.fetch('body')
    end
  end
end
