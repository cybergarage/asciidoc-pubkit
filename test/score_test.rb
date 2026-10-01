# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require 'stringio'
require 'asciidoc_pubkit'

class ScoreTest < Minitest::Test
  def setup
    @dir = File.realpath(Dir.mktmpdir('pubkit-score-test-'))
    @book = File.join(@dir, 'book.adoc')
    File.write(@book, "= Score Test\n:lang: ja\n\n重要なのは、猫です。\n")
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  def cli(*args)
    out, err = StringIO.new, StringIO.new
    code = AsciidocPubkit::CLI.run(['review', 'score', *args], out: out, err: err)
    [code, out.string, err.string]
  end

  def with_evaluator(evaluator)
    singleton = AsciidocPubkit::LocalEvaluator.singleton_class
    singleton.define_method(:new) { |*args, **options| evaluator.is_a?(Proc) ? evaluator.call(*args, **options) : evaluator }
    yield
  ensure
    singleton.remove_method(:new)
  end

  def test_scores_any_adoc_without_a_session_or_agent
    original = File.binread(@book)
    %w[mecab literal].each do |mode|
      code, output, error = cli(@book, '--json', '--tokenizer', mode)
      assert_equal 0, code, error
      report = JSON.parse(output)
      assert_equal 'candidate-density-v1', report['score_type']
      assert_equal 1, report['candidate_count']
      assert_equal 10, report['characters']
      assert_equal 100.0, report['candidate_density_per_1000']
      assert_equal 0.0, report['score']
      assert_equal false, report['meaning_verified']
      refute report.key?('evaluator')
      assert_equal mode, report['analysis']['engine']
    end
    assert_equal original, File.binread(@book)
    assert_equal ['book.adoc'], Dir.children(@dir)
    code, output, error = cli(@book, '--tokenizer', 'literal')
    assert_equal 0, code, error
    assert_includes output, 'Score: 0.0/100'
    assert_includes output, 'Method: candidate-density-v1'
  end

  def test_no_candidates_and_no_prose_are_distinct
    File.write(@book, "= Test\n\n猫が眠る。\n")
    assert_equal 100.0, JSON.parse(cli(@book, '--json').last(2).first)['score']
    File.write(@book, "= Test\n\n[source,ruby]\n----\nputs '重要なのは'\n----\n\n`重要なのは`\n")
    code, output, error = cli(@book, '--json')
    assert_equal 0, code, error
    report = JSON.parse(output)
    assert_nil report['score']
    assert_equal 0, report['characters']
    assert_equal 0, report['scored_paragraphs']
    refute_empty report['coverage']
    with_evaluator(->(*) { flunk 'No prose must not invoke an agent.' }) do
      code, output, error = cli(@book, '--agent', 'codex', '--json')
      assert_equal 0, code, error
      assert_nil JSON.parse(output)['score']
    end
  end

  def test_inline_masking_and_include_selection
    chapter = File.join(@dir, 'chapter.adoc')
    File.write(chapter, "== Chapter\n\n猫が眠る。\n")
    File.write(@book, "= Test\n\n重要なのは、猫です。\n\n`重要なのは`\n\ninclude::chapter.adoc[]\n")
    code, output, error = cli(@book, '--only', chapter, '--json')
    assert_equal 0, code, error
    report = JSON.parse(output)
    assert_equal 1, report['paragraphs']
    assert_equal 100.0, report['score']
    assert_empty report['findings']
  end

  def test_custom_rules_and_allows_affect_density
    File.write(File.join(@dir, '.asciidoc-pubkit.yml'), "review:\n  allows: [重要なのは]\n")
    code, output, error = cli(@book, '--json')
    assert_equal 0, code, error
    assert_equal 100.0, JSON.parse(output)['score']
    rules = AsciidocPubkit::RuleSet.load
    rules['terms'].each_value { |entry| entry['terms'] = [] }
    rules['verbs'] = {}
    rules['sahen'] = []
    rules['compound_nouns'] = []
    rules['negative_only'] = []
    path = File.join(@dir, 'empty.yml')
    File.write(path, rules.to_yaml)
    code, output, error = cli(@book, '--rules', path, '--json')
    assert_equal 0, code, error
    assert_equal 100.0, JSON.parse(output)['score']
  end

  def test_score_output_never_replaces_files_or_manuscripts
    output = File.join(@dir, 'score.json')
    assert_equal 0, cli(@book, '--json', '--output', output).first
    before = File.read(output)
    with_evaluator(->(*) { flunk 'Existing output must fail before invoking an agent.' }) do
      assert_equal 2, cli(@book, '--agent', 'codex', '--output', output).first
    end
    assert_equal before, File.read(output)
    original = File.read(@book)
    assert_equal 2, cli(@book, '--output', @book).first
    assert_equal original, File.read(@book)
  end

  def test_invalid_inputs_languages_and_agent_options
    [[], [@book, @book], ['missing.adoc'], [@book, '--lang', 'en'],
     [@book, '--model', 'example'], [@book, '--agent', 'unknown'],
     [@book, '--agent', 'codex', '--timeout', '0'], [@book, '--yes']].each do |args|
      code, _, error = cli(*args)
      assert_equal 2, code, error
      refute_empty error
    end
    File.write(@book, "= Test\n:lang: en\n\n猫が眠る。\n")
    assert_equal 2, cli(@book).first
    code, help, error = cli('--help')
    assert_equal 0, code, error
    assert_includes help, 'FILE'
    assert_includes help, '--agent'
  end

  def test_optional_readability_scoring_validates_and_orders_evaluator_output
    File.write(@book, "= Test\n\n重要なのは、猫です。\n\n猫が眠る。\n")
    calls = []
    evaluator = Object.new
    evaluator.define_singleton_method(:metadata) { { 'agent' => 'codex', 'actual_model' => 'test-model' } }
    evaluator.define_singleton_method(:call) do |prompt, directory, stem|
      calls << [prompt, directory, stem]
      paragraphs = JSON.parse(prompt.split("\nParagraph data:\n").last)
      { 'paragraphs' => paragraphs.map.with_index { |p, i| { 'id' => p['id'], 'sentence_clarity' => i.zero? ? 3 : 1,
         'paragraph_coherence' => i.zero? ? 2 : 3, 'reason' => 'Test readability assessment.' } }.reverse }
    end
    with_evaluator(evaluator) do
      code, output, error = cli(@book, '--agent', 'codex', '--json')
      assert_equal 0, code, error
      report = JSON.parse(output)
      assert_equal 'llm-readability-v1', report['score_type']
      assert_equal 62.5, report['score']
      assert_equal 50.0, report['readability']['sentence_clarity']
      assert_equal 75.0, report['readability']['paragraph_coherence']
      assert_equal [3, 1], report['readability']['paragraphs'].map { |p| p['sentence_clarity'] }
      assert_equal false, report['meaning_verified']
    end
    assert_equal 1, calls.length
    refute File.exist?(calls.first[1]), 'Temporary scoring data must be removed.'
    refute_includes calls.first[0], @book
    refute_includes calls.first[0], 'findings'
  end

  def test_malformed_evaluator_output_fails_explicitly
    paragraph = { 'id' => 'a', 'file' => @book, 'line' => 3 }
    item = { 'id' => 'a', 'sentence_clarity' => 3, 'paragraph_coherence' => 2, 'reason' => 'Clear.' }
    assert_raises(AsciidocPubkit::Error) { AsciidocPubkit::Score.readability({ 'paragraphs' => [item, item] }, [paragraph]) }
    item['sentence_clarity'] = 4
    assert_raises(AsciidocPubkit::Error) { AsciidocPubkit::Score.readability({ 'paragraphs' => [item] }, [paragraph]) }
    evaluator = Object.new
    evaluator.define_singleton_method(:call) { |*| { 'unexpected' => true } }
    with_evaluator(evaluator) do
      code, _, error = cli(@book, '--agent', 'codex')
      assert_equal 2, code
      assert_includes error, 'Invalid local evaluator response'
    end
  end
end
