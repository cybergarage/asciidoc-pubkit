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
    %w[criteria prompt].each do |command|
      code, output, error = cli('writing', command, '--lang', 'ja')
      assert_equal 0, code, error
      assert_includes output, 'Review sentence endings by their role'
      assert_includes output, 'Naming two objects alone does not explain their difference'
      assert_includes output, '短い案内を毎回の入力に含め'
      assert_includes output, '取消通知は要求IDで対象を指定し'
      assert_includes output, 'Frequency alone does not establish a defect'
      assert_includes output, 'Separate explanatory guidance from actual checks'
      assert_includes output, 'Do not mechanically convert `別です` to `とは限りません`'
      assert_includes output, 'noun-phrase heading policy does not authorize nominalizing body sentences'
      assert_includes output, '利用者は候補Aと候補Bから選べます'
    end
    assert_includes prompt, 'Treat `流れ` as a cue'
    assert_includes prompt, 'These terms are not interchangeable'
    assert_includes prompt, '検査に成功した後だけ、実行関数を呼び出す流れです'
    assert_includes prompt, 'Compare structure before and after revision'
    assert_includes prompt, 'Preserve plain or polite style'
    assert_includes prompt, 'Keep source uncertainty separate from editorial questions'
    assert_includes prompt, 'Keep completed changes, current behavior or policy, and future plans distinct'
    assert_includes prompt, '各ワーカーは最大3回再試行します'
    assert_includes prompt, 'Identify human actors by their supported roles'
    assert_includes prompt, '人の介入'
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
