# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require 'stringio'
require 'asciidoc_pubkit'

class WritingTest < Minitest::Test
  def cli(*args)
    out = StringIO.new
    err = StringIO.new
    code = AsciidocPubkit::CLI.run(args, out: out, err: err)
    [code, out.string, err.string]
  end

  def test_writing_commands_share_the_packaged_criteria_without_an_input_file
    code, criteria, error = cli('writing', 'criteria', '--lang', 'ja')
    assert_equal 0, code, error
    assert_equal AsciidocPubkit::Writing.criteria('ja'), criteria

    code, prompt, error = cli('writing', 'prompt')
    assert_equal 0, code, error
    assert_includes prompt, 'Language: ja'
    assert_includes prompt, 'Keep claims within their evidence and purpose'
    assert_includes prompt, 'Headings and the relation to figures and code'
    %w[構築入口 エラーを回収する ツールを呼ぶ 提供することが前提です 設計の肝です 拡張点 積み重なります 追えます 見落とします 分かれて現れます 担保しなければなりません].each do |example|
      assert_includes criteria, example
      assert_includes prompt, example
    end
    assert_includes prompt, 'do not turn an assumption into an obligation'
    assert_includes prompt, 'Intended role of 入口'
    assert_includes prompt, 'naming its referent alone'
    assert_includes prompt, 'Distinguish a public option or return field from internal state'
    refute_includes prompt, 'Migrated OSS prose style profile'
  end

  def test_writing_rejects_unsupported_languages_and_input_files
    %w[criteria prompt].each do |command|
      code, _, error = cli('writing', command, '--lang', 'en')
      assert_equal 2, code
      assert_includes error, 'Unsupported writing language "en"; supported: ja.'
    end
    assert_equal 2, cli('writing', 'prompt', 'book.adoc').first
  end

  def test_writing_output_does_not_replace_existing_file
    Dir.mktmpdir('pubkit-writing-') do |directory|
      path = File.join(directory, 'prompt.md')
      assert_equal 0, cli('writing', 'prompt', '--output', path).first
      original = File.read(path)
      assert_equal 2, cli('writing', 'prompt', '--output', path).first
      assert_equal original, File.read(path)
    end
  end
end
