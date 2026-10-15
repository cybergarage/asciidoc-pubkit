# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require 'stringio'
require 'asciidoc_pubkit'

class WritingTest < Minitest::Test
  def test_arrival_guidance_is_saved_in_all_review_scopes_without_rewriting_sources
    expected = ['Distinguish arrival wording by the actual operation',
                '進捗通知を受信しない', '外部から入力されるJSON', 'parseで入力値を検査する',
                '停止後に取得したモデル応答', '遅れて確定する結果', '対応する試行の報告がない枠',
                'Do not replace every arrival with `受信する`']
    %w[criteria prompt].each do |command|
      code, output, error = cli('writing', command, '--lang', 'ja')
      assert_equal 0, code, error
      expected.each { |text| assert_includes output, text }
    end
    Dir.mktmpdir('pubkit-arrival-') do |directory|
      manuscript = File.join(directory, 'book.adoc')
      source = "= Example\n\n== 通知\n\n応答が届きます。\n\n* 報告が届かない場合も集計します。\n"
      File.write(manuscript, source)
      %w[headings prose lists].each do |scope|
        session = File.join(directory, scope)
        code, _, error = cli('review', 'scan', manuscript, '--scope', scope,
                             '--tokenizer', 'literal', '--output', session, '--no-input')
        assert_equal 0, code, error
        saved = JSON.parse(File.read(File.join(session, 'manifest.json')))['writing_criteria']
        expected.each { |text| assert_includes saved, text }
        code, prompt, error = cli('review', 'prompt', session)
        assert_equal 0, code, error
        assert_includes prompt, saved
        unless scope == 'headings'
          findings = JSON.parse(File.read(File.join(session, 'findings.json')))
          assert findings.any? { |f| f['rule'] == 'weak-predicate' && f['match'].start_with?('届') }
        end
        code, _, error = cli('review', 'verify', session)
        assert_equal 0, code, error
        assert_equal source, File.read(manuscript)
      end
    end
  end

  def cli(*args)
    out = StringIO.new
    err = StringIO.new
    code = AsciidocPubkit::CLI.run(args, out: out, err: err)
    [code, out.string, err.string]
  end

  def test_communication_response_guidance_reaches_writing_and_saved_review_prompts
    expected = [
      'Distinguish communication responses from function returns',
      'HTTPでは、受付結果をステータスコード202で応答します',
      '停止理由を含む応答を元の要求に対して送信します',
      'MCPの接続先が処理を実行し、その結果を応答として送信します',
      'preserve missing values as unmeasured',
      'returning `Message`, `ToolResult`, `RunHandle` or `Promise` are different stages',
      'never infer throw, rejection or a received error response from the word error alone'
    ]
    %w[criteria prompt].each do |command|
      code, output, error = cli('writing', command, '--lang', 'ja')
      assert_equal 0, code, error
      expected.each { |text| assert_includes output, text }
    end

    Dir.mktmpdir('pubkit-response-') do |directory|
      manuscript = File.join(directory, 'book.adoc')
      source = "= Example\n\n== 呼び出し\n\nHTTPは受付の結果を202で返します。\n\n* 関数はPromiseを返します。\n"
      File.write(manuscript, source)
      %w[headings prose lists].each do |scope|
        session = File.join(directory, scope)
        code, _, error = cli('review', 'scan', manuscript, '--scope', scope,
                             '--tokenizer', 'literal', '--output', session, '--no-input')
        assert_equal 0, code, error
        saved = JSON.parse(File.read(File.join(session, 'manifest.json')))['writing_criteria']
        expected.each { |text| assert_includes saved, text }
        code, prompt, error = cli('review', 'prompt', session)
        assert_equal 0, code, error
        assert_includes prompt, saved
        assert_equal source, File.read(manuscript)
      end
    end
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
    assert_includes prompt, 'Distinguish receiving, returning, and their actual operations'
    assert_includes prompt, 'Keep `値を返す`, `Promiseを返す`'
    assert_includes prompt, 'A service returning a display message does not necessarily display it'
    assert_includes prompt, 'throw/catch or equivalent behavior is established'
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
