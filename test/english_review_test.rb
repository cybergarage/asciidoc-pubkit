# frozen_string_literal: true
require 'minitest/autorun'
require 'tmpdir'
require 'stringio'
require 'asciidoc_pubkit'

class EnglishReviewTest < Minitest::Test
  def with_stub(object, name, implementation)
    own = object.singleton_class.instance_methods(false).include?(name)
    original = object.method(name)
    object.define_singleton_method(name, implementation)
    yield
  ensure
    object.singleton_class.remove_method(name)
    object.define_singleton_method(name, original) if own
  end

  def setup
    @dir = File.realpath(Dir.mktmpdir('pubkit-en-'))
    @book = File.join(@dir, 'book.adoc')
    @source = "= Test\n:lang: en\n\n== Cache behavior\n\nIt is important to note that the worker clears the cache after commit.\n\nThe key remains unavailable.\n\n* In order to retry, open the queue.\n* Keep `api_key` unchanged.\n"
    File.write(@book, @source)
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  def cli(*args)
    out, err = StringIO.new, StringIO.new
    [AsciidocPubkit::CLI.run(args, out: out, err: err, input: StringIO.new), out.string, err.string]
  end

  def scan(scope = 'prose', *args)
    path = File.join(@dir, "session-#{scope}")
    result = cli('review', 'scan', @book, '--lang', 'en', '--scope', scope, '--output', path, '--no-input', *args)
    assert_equal 0, result.first, result.inspect
    [AsciidocPubkit::Session.new(path), path]
  end

  def test_all_scopes_remain_local_with_complete_english_prompts_and_frozen_baselines
    with_stub(Open3, :capture3, ->(*) { flunk 'Default English review must not launch a process' }) do
      %w[prose headings lists].each do |scope|
        session, path = scan(scope)
        prompt = session.prompt('diagnose', view: scope == 'headings' ? 'outline' : 'full')
        refute_includes prompt, 'Japanese'
        assert_includes prompt, 'English'
        assert_includes prompt, 'Do not edit files'
        assert_includes prompt, 'The key remains unavailable.' if scope == 'prose'
        before = Dir.glob("#{path}/**/*").select { |f| File.file?(f) }.to_h { |f| [f, File.binread(f)] }
        assert session.verify['passed']
        refute session.verify['meaning_verified']
        before.each { |f, bytes| assert_equal bytes, File.binread(f) }
      end
      report = AsciidocPubkit::Score.run(@book, language: 'en')
      assert_equal 'english-lexical', report['analysis']['engine']
      refute report.key?('evaluator')
    end
  end

  def test_heading_anchor_and_scope_protection
    session, path = scan('headings')
    heading = JSON.parse(File.read("#{path}/document.json"))['headings'].first
    File.write(@book, @source.sub('== Cache behavior', "#{heading.fetch('permitted_id_anchor')}\n== Clearing the cache"))
    assert session.verify['passed']
    File.write(@book, File.read(@book).sub('The key remains unavailable.', 'The key is available.'))
    refute session.verify['passed']
  end

  def test_prose_edits_verify_but_protected_changes_and_stale_prompts_fail
    session, = scan
    File.write(@book, @source.sub('It is important to note that the worker', 'The worker'))
    assert session.verify['passed']
    assert_raises(AsciidocPubkit::Error) { session.prompt('revise') }
    File.write(@book, File.read(@book).sub('api_key', 'api_secret'))
    refute session.verify['passed']
  end

  def test_invalid_language_backend_style_rules_and_replacement_are_explicit
    [['--lang', 'en-US'], ['--lang', 'en-GB'], ['--lang', 'en', '--tokenizer', 'mecab'],
     ['--lang', 'ja', '--tokenizer', 'english-lexical'], ['--lang', 'en', '--style', 'dearu'],
     ['--lang', 'ja']].each do |args|
      assert_equal 2, cli('review', 'scan', @book, '--output', "#{@dir}/bad", *args).first, args.inspect
    end
    assert_raises(AsciidocPubkit::Error) { AsciidocPubkit::Settings.new(@book, language: 'en', replacement: true) }
    japanese = File.expand_path('../data/review-rules.ja.yml', __dir__)
    assert_raises(AsciidocPubkit::Error) { AsciidocPubkit::Settings.new(@book, language: 'en', rules: japanese) }
    session, path = scan
    assert_equal 2, cli('review', 'prompt', path, '--lang', 'ja').first
    assert_equal 2, cli('review', 'scan', @book, '--lang', 'en', '--output', path, '--no-input').first
    assert session.verify['passed']
  end

  def test_saved_custom_rules_and_criteria_do_not_follow_resource_changes
    rules = AsciidocPubkit::RuleSet.load(AsciidocPubkit::RuleSet.default_path('en'))
    rules['rules'] = []
    file = File.join(@dir, 'rules.yml'); File.write(file, rules.to_yaml)
    session, path = scan('prose', '--rules', file)
    File.write(file, 'invalid: yaml')
    assert_empty session.verify['findings']
    with_stub(AsciidocPubkit::Writing, :prompt_criteria, ->(*) { raise 'must use saved criteria' }) do
      assert_includes session.prompt('revise'), 'Preserve facts and modal force'
    end
    with_stub(AsciidocPubkit::Analysis, :build, ->(*) { raise 'prompt needs no analyzer' }) do
      assert_includes session.prompt('revise'), 'The key remains unavailable.'
    end
    manifest = JSON.parse(File.read("#{path}/manifest.json"))
    manifest['analysis']['version'] = 'old'
    File.write("#{path}/manifest.json", JSON.pretty_generate(manifest))
    report = AsciidocPubkit::Session.new(path).verify
    assert_includes report['issues'].map { |i| i['kind'] }, 'analyzer-changed'
  end

  def test_scoring_formula_literal_parity_and_empty_input
    report = AsciidocPubkit::Score.run(@book, language: 'en')
    assert_equal 1, report['candidate_count']
    expected = [0, 100 - 5 * 1000.0 / report['characters']].max.round(3)
    assert_equal expected, report['score']
    assert_equal 'candidate-density-v1', report['score_type']
    refute report['calibrated_quality_score']
    literal = AsciidocPubkit::Score.run(@book, language: 'en', tokenizer: 'literal')
    assert_equal report['findings'], literal['findings']
    assert_equal expected, literal['score']
    assert_equal 'literal', literal['analysis']['engine']
    File.write(@book, "= Book\n:lang: en\n\n[source]\n----\ncode\n----\n")
    assert_nil AsciidocPubkit::Score.run(@book, language: 'en')['score']
  end

  def test_explicit_evaluator_receives_english_rubric_and_keeps_density_separate
    evaluator = Object.new
    evaluator.define_singleton_method(:call) do |prompt, *_args|
      raise 'Japanese rubric' if prompt.include?('Japanese')
      entries = JSON.parse(prompt.split("Paragraph data:\n").last)
      { 'paragraphs' => entries.map { |p| { 'id' => p['id'], 'sentence_clarity' => 3, 'paragraph_coherence' => 2, 'reason' => 'Connected explanation.' } } }
    end
    evaluator.define_singleton_method(:metadata) { { 'agent' => 'stub' } }
    with_stub(AsciidocPubkit::LocalEvaluator, :new, ->(*) { evaluator }) do
      report = AsciidocPubkit::Score.run(@book, language: 'en', agent: 'codex')
      assert_equal 'llm-readability-v1', report['score_type']
      assert_equal 75.0, report['score']
      refute_equal report['score'], report['candidate_density_score']
      refute report['meaning_verified']
    end
  end

  def test_include_mapping_and_list_marker_preservation
    chapter = File.join(@dir, 'chapter.adoc')
    File.write(chapter, "== Retry\n\nIn order to retry, open the queue.\n\n* The the worker retries.\n")
    File.write(@book, "= Book\n:lang: en\n\ninclude::chapter.adoc[]\n")
    session, = scan('lists')
    assert_equal chapter, session.verify['findings'].first['file']
    File.write(chapter, File.read(chapter).sub('The the', 'The'))
    assert session.verify['passed']
    File.write(chapter, File.read(chapter).sub('* The', '. The'))
    refute session.verify['passed']
  end
end
