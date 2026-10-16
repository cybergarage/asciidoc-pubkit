# frozen_string_literal: true

require 'minitest/autorun'
require 'asciidoc_pubkit'
require 'tmpdir'
require 'stringio'

class OperationWordingTest < Minitest::Test
  def settings(mode)
    { 'tokenizer' => mode, 'allows' => [], 'glossary' => {}, 'style' => 'preserve',
      'rules' => AsciidocPubkit::RuleSet.load }
  end

  def cues(text, mode, config = settings(mode))
    paragraph = { 'id' => 'operation', 'file' => '/sample.adoc', 'line' => 1, 'text' => text }
    AsciidocPubkit::Rules.scan([paragraph], config).select do |finding|
      finding['rule'] == 'weak-predicate' && finding['match'].start_with?('行')
    end
  end

  %w[mecab literal].each do |mode|
    define_method("test_inflections_positions_polarity_and_exclusions_in_#{mode}") do
      text = "😀検証を行います。\n停止後は生成を行いません。"
      findings = cues(text, mode)
      assert_equal ['行います', '行いません'], findings.map { |f| f['match'] }
      assert_equal [[1, 5], [2, 8]], findings.map { |f| f.values_at('line', 'column') }
      assert findings.all? { |f| f['severity'] == 'hint' }
      if mode == 'mecab'
        assert_equal ['行う', '行う'], findings.map { |f| f['lemma'] }
        assert_equal [false, true], findings.map { |f| f['negative'] }
        assert_empty cues(text, mode, settings(mode).merge('allows' => ['行う']))
      end
      assert_empty cues(text, mode, settings(mode).merge('allows' => ['行います', '行いません']))
      assert_empty cues('`行います`。「行います」。link:https://example.com[行います]。行列と行為。', mode)
      %w[行う 行います 行いました 行った 行って 行わない 行いません 行わなかった 行っていません 行えます 行えない].each do |surface|
        assert_equal [surface], cues("検証を#{surface}。", mode).map { |f| f['match'] }, surface
      end
      custom = settings(mode)
      custom['rules']['verbs'].delete('行う')
      custom['rules']['terms']['weak-predicate']['terms'].delete_if { |term| term.start_with?('行') }
      assert_empty cues(text, mode, custom)
    end

    define_method("test_operation_examples_find_originals_without_prescribing_their_alternatives_in_#{mode}") do
      cases = JSON.parse(File.read(File.join(__dir__, 'fixtures/operation_wording.ja.json')))
      cases.each do |item|
        refute_empty cues(item['original'], mode), item['id']
        assert_empty cues(item['alternative'], mode), item['id']
      end
    end
  end

  def test_saved_sessions_do_not_acquire_new_operation_candidates
    Dir.mktmpdir('pubkit-operation-saved-') do |directory|
      file = File.join(directory, 'book.adoc')
      rules_file = File.join(directory, 'rules.yml')
      session = File.join(directory, 'old')
      source = "= Sample\n\n入力の検証を行います。\n"
      File.write(file, source)
      old_rules = settings('mecab')['rules']
      old_rules['verbs'].delete('行う')
      old_rules['terms']['weak-predicate']['terms'].delete_if { |term| term.start_with?('行') }
      File.write(rules_file, YAML.dump(old_rules))
      assert_equal 0, cli('review', 'scan', file, '--rules', rules_file, '--output', session, '--no-input').first
      File.write(rules_file, YAML.dump(AsciidocPubkit::RuleSet.load))
      code, report, error = cli('review', 'verify', session)
      assert_equal 0, code, error
      refute_includes report, '行います'
      saved = JSON.parse(File.read(File.join(session, 'manifest.json')))
      refute saved['settings']['rules']['verbs'].key?('行う')
      fresh = File.join(directory, 'new')
      assert_equal 0, cli('review', 'scan', file, '--rules', rules_file, '--output', fresh, '--no-input').first
      findings = JSON.parse(File.read(File.join(fresh, 'findings.json')))
      assert_equal ['行います'], findings.select { |f| f['lemma'] == '行う' }.map { |f| f['match'] }
      assert_equal source, File.read(file)
    end
  end

  def cli(*args)
    output = StringIO.new
    error = StringIO.new
    code = AsciidocPubkit::CLI.run(args, out: output, err: error, input: StringIO.new)
    [code, output.string, error.string]
  end

  def test_prose_and_lists_save_rules_and_criteria_without_editing_protected_content
    Dir.mktmpdir('pubkit-operation-') do |directory|
      file = File.join(directory, 'book.adoc')
      source = "= Sample\n\n== 処理\n\n入力の検証を行います。\n\n* 次のコード生成を行います。\n\n[source,ruby]\n----\n行います\n----\n\n|===\n|表で行います。\n|===\n"
      File.write(file, source)
      %w[prose lists].each do |scope|
        session = File.join(directory, scope)
        code, _, error = cli('review', 'scan', file, '--scope', scope, '--output', session, '--no-input')
        assert_equal 0, code, error
        manifest = JSON.parse(File.read(File.join(session, 'manifest.json')))
        assert_equal %w[行う 行える], manifest['settings']['rules']['verbs']['行う']
        findings = JSON.parse(File.read(File.join(session, 'findings.json'))).select { |f| f['lemma'] == '行う' }
        assert_equal [scope == 'prose' ? 5 : 7], findings.map { |f| f['line'] }
        assert_includes manifest['writing_criteria'], 'Distinguish operations from responsibility'
        code, prompt, error = cli('review', 'prompt', session)
        assert_equal 0, code, error
        assert_includes prompt, manifest['writing_criteria']
        code, report, error = cli('review', 'verify', session)
        assert_equal 0, code, error
        assert JSON.parse(report)['passed']
        refute JSON.parse(report)['meaning_verified']
        assert_equal source, File.read(file)
      end
    end
  end
end
