# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../benchmark/prose'

class ProseBenchmarkTest < Minitest::Test
  def event(id, kind, offset)
    { 'case_id' => id, 'kind' => kind, 'offset' => offset }
  end

  def test_scores_distinguish_detection_from_position_and_false_positives
    expected = [event('a', 'repeated-ending', 30), event('b', 'metaphor-operation', 5)]
    found = [event('a', 'repeated-ending', 2), event('c', 'metaphor-operation', 7)]
    result = ProseBenchmark.score(expected, found)
    assert_equal 1, result['true_positives']
    assert_equal 1, result['false_positives']
    assert_equal 1, result['false_negatives']
    assert_equal 50.0, result['precision']
    assert_equal 50.0, result['recall']
    assert_equal 50.0, result['f1']
    assert_equal 0.0, result['location_accuracy']
    assert_equal expected.last, result['misses'].first
    assert_equal 30, result['mislocated'].first['expected']['offset']
  end

  def test_duplicate_findings_do_not_inflate_recall_and_empty_denominators_are_null
    expected = [event('a', 'generic-framing', 0)]
    result = ProseBenchmark.score(expected, [expected.first, expected.first])
    assert_equal 50.0, result['precision']
    assert_equal 100.0, result['recall']
    empty = ProseBenchmark.score([], [])
    %w[precision recall f1 location_accuracy].each { |key| assert_nil empty[key] }
  end

  def test_corpus_targets_are_valid_and_both_analyzers_run_without_an_ai_cli
    %w[mecab literal].each do |mode|
      report, cases = ProseBenchmark.snapshot(mode)
      assert_equal 21, cases.length
      assert_equal mode, report['analysis']['engine']
      assert_equal false, report['meaning_verified']
      assert_equal ProseBenchmark::KINDS, report['by_kind'].keys
      assert_equal 11, report['detection'].values_at('true_positives', 'false_negatives').sum
      assert_equal [], report['detection']['unexpected']
      assert_equal 100.0, report['detection']['precision']
      assert_equal(mode == 'mecab' ? 100.0 : 81.818, report['detection']['recall'])
      assert_equal 100.0, report['detection']['location_accuracy']
      refute_includes JSON.generate(report), ProseBenchmark::ROOT
    end
  end

  def test_compare_rejects_changed_corpus_or_analyzer
    before, = ProseBenchmark.snapshot('literal')
    after = Marshal.load(Marshal.dump(before))
    after['detection']['recall'] += 10
    assert_equal 10.0, ProseBenchmark.compare(before, after)['recall']
    %w[corpus_sha256 document_sha256 config_sha256 scoring_version analysis].each do |key|
      changed = after.merge(key => 'different')
      assert_raises(AsciidocPubkit::Error) { ProseBenchmark.compare(before, changed) }
    end
  end

  def test_structural_cases_have_evidence_and_calibration_without_numeric_shortcuts
    cases = ProseBenchmark.corpus.fetch('cases')
    assert_equal 'technical-prose-v2', ProseBenchmark.corpus.fetch('id')
    assert_equal cases.length, cases.map { |item| item.fetch('id') }.uniq.length
    %w[per-worker-quantity ordered-recovery modifier-target conditional-scope
       parallel-checks advice-and-behavior plain-style-control punctuation-and-purpose].each do |id|
      item = cases.find { |entry| entry['id'] == id }
      refute_nil item, id
      refute_empty item.fetch('facts'), id
      assert_empty item.fetch('targets'), id
    end
    pairs = JSON.parse(File.read(ProseBenchmark::CALIBRATION)).fetch('manual_revision_cases')
    assert_equal 31, pairs.length
    assert_equal pairs.length, pairs.map { |item| item.fetch('id') }.uniq.length
    quantity = pairs.find { |item| item['id'] == 'quantity-target-changed' }
    assert_equal quantity.fetch('source').scan(/\d+/), quantity.fetch('revision').scan(/\d+/)
    assert_equal 'reject', quantity.fetch('expected_disposition')
    %w[quantity-target order modifier-target condition-scope parallelism sentence-function
       register purpose-scope].each do |axis|
      assert pairs.any? { |item| item.fetch('review_axes').include?(axis) }, axis
    end
  end

  def test_operation_revision_calibration_has_errors_uncertainty_and_valid_controls
    pairs = JSON.parse(File.read(ProseBenchmark::CALIBRATION)).fetch('manual_revision_cases')
    expected = {
      'path-length-made-performance' => 'reject', 'capability-made-reuse' => 'reject',
      'summary-made-shortening' => 'reject', 'separate-operations-made-independent' => 'needs-evidence',
      'reference-made-content-loading' => 'reject', 'optional-inheritance-made-requirement' => 'reject',
      'user-side-made-local' => 'needs-evidence', 'policy-definition-made-enforcement' => 'needs-evidence',
      'comparison-made-direct' => 'accept', 'precise-everyday-verb-kept' => 'accept',
      'event-trigger-made-direct' => 'accept'
    }
    expected.each do |id, disposition|
      item = pairs.find { |pair| pair['id'] == id }
      refute_nil item, id
      assert_equal disposition, item.fetch('expected_disposition'), id
      %w[source revision reason].each { |key| refute_empty item.fetch(key), "#{id}: #{key}" }
      refute_empty item.fetch('review_axes'), id
    end
  end

  def test_revision_validation_rejects_duplicates_missing_ids_and_new_paragraphs
    cases = [{ 'id' => 'a' }, { 'id' => 'b' }]
    correct = { 'paragraphs' => [{ 'id' => 'a', 'text' => '元の文章です。' }, { 'id' => 'b', 'text' => '次の文章です。' }] }
    assert_equal %w[a b], ProseBenchmark.validate_revisions(correct, cases).keys
    assert_raises(AsciidocPubkit::Error) { ProseBenchmark.validate_revisions({ 'paragraphs' => [correct['paragraphs'].first] }, cases) }
    duplicate = { 'paragraphs' => [correct['paragraphs'].first, correct['paragraphs'].first] }
    assert_raises(AsciidocPubkit::Error) { ProseBenchmark.validate_revisions(duplicate, cases) }
    correct['paragraphs'].first['text'] = "段落です。\n新しい段落です。"
    assert_raises(AsciidocPubkit::Error) { ProseBenchmark.validate_revisions(correct, cases) }
  end

  def judgment_item(c)
    { 'id' => c['id'], 'sentence_clarity' => 3, 'paragraph_coherence' => 2,
      'retained' => c['facts'].map { true }, 'unsupported_additions' => [],
      'substitutions' => [], 'reason' => 'The original facts remain unchanged.' }
  end

  def test_judge_scores_keep_preservation_independent_from_readability
    items = [judgment_item({ 'id' => 'a', 'facts' => %w[one two] }), judgment_item({ 'id' => 'b', 'facts' => ['three'] })]
    items.first['retained'] = [false, true]
    items.first['unsupported_additions'] = ['The text invents a log message.']
    summary = ProseBenchmark.judge_summary('paragraphs' => items)
    assert_equal 100.0, summary['sentence_clarity']
    assert_equal 50.0, summary['paragraph_coherence']
    assert_equal 66.667, summary['fact_retention']
    assert_equal 50.0, summary['addition_free_paragraphs']
    assert_equal 100.0, summary['substitution_free_paragraphs']
  end

  def test_judge_validation_checks_score_ranges_and_fact_counts
    cases = [{ 'id' => 'a', 'facts' => %w[one two] }]
    value = { 'documents' => %w[A B].map { |id| { 'id' => id, 'paragraphs' => [judgment_item(cases.first)] } }, 'calibration' => [] }
    ProseBenchmark.validate_judgment(value, cases, [])
    value['documents'].first['paragraphs'].first['sentence_clarity'] = 4
    assert_raises(AsciidocPubkit::Error) { ProseBenchmark.validate_judgment(value, cases, []) }
    value['documents'].first['paragraphs'].first['sentence_clarity'] = 3
    value['documents'].first['paragraphs'].first['retained'] = [true]
    assert_raises(AsciidocPubkit::Error) { ProseBenchmark.validate_judgment(value, cases, []) }
  end

  def test_calibration_uses_balanced_accuracy
    gold = [
      { 'id' => 'a', 'expected_disposition' => 'accept' },
      { 'id' => 'b', 'expected_disposition' => 'accept' },
      { 'id' => 'c', 'expected_disposition' => 'reject' }
    ]
    results = %w[a b c].map { |id| { 'id' => id, 'disposition' => 'accept' } }
    scores = ProseBenchmark.calibration_score(results, gold)
    assert_equal 66.667, scores['accuracy']
    assert_equal 50.0, scores['balanced_accuracy']
  end

  def test_actual_session_and_verifier_are_used_in_a_trial_without_network
    cases = ProseBenchmark.corpus.fetch('cases')
    calibration = JSON.parse(File.read(ProseBenchmark::CALIBRATION)).fetch('manual_revision_cases')
    captured = []
    agent = Object.new
    build_item = method(:judgment_item)
    agent.define_singleton_method(:call) do |prompt, directory, stem|
      captured << [prompt, directory, stem]
      if stem == 'rewrite'
        { 'paragraphs' => cases.map { |c| c.slice('id', 'text') } }
      else
        { 'documents' => %w[A B].map { |id| { 'id' => id, 'paragraphs' => cases.map { |c| build_item.call(c) } } },
          'calibration' => calibration.map { |c| { 'id' => c['id'], 'disposition' => c['expected_disposition'], 'reason' => 'Calibration fixture.' } } }
      end
    end
    Dir.mktmpdir('pubkit-evaluation-') do |directory|
      result = ProseBenchmark.ai_trial(agent, cases, directory, 1)
      assert_equal true, result['mechanical_verification_passed']
      assert_equal false, result['meaning_verified']
      assert_equal 100.0, result['calibration']['balanced_accuracy']
      assert result['delta'].values.all?(&:zero?)
      assert File.file?(File.join(directory, 'trial-1/session/manifest.json'))
      assert_includes captured.first.first, 'Japanese manuscript review'
      assert_includes captured.first.first, 'Explain metaphorical operations from evidence'
      assert_includes captured.first.first, 'Compare structure before and after revision'
      assert_includes captured.first.first, 'Preserve plain or polite style'
      assert_includes captured.last.first, 'targets, required order'
      refute_includes captured.last.first, 'expected_disposition'
      refute_includes captured.last.first, 'candidate_count'
    end
  end

  def test_runner_refuses_existing_output_and_does_not_invoke_agents_by_default
    Dir.mktmpdir('pubkit-runner-') do |directory|
      output = File.join(directory, 'results')
      runner = File.join(ProseBenchmark::ROOT, 'script/evaluate-prose')
      _, error, status = Open3.capture3(RbConfig.ruby, runner, '--tokenizer', 'literal', '--output', output)
      assert status.success?, error
      report = JSON.parse(File.read(File.join(output, 'report.json')))
      refute report.key?('ai')
      File.write(File.join(output, 'keep'), 'keep')
      _, error, status = Open3.capture3(RbConfig.ruby, runner, '--output', output)
      assert_equal 2, status.exitstatus
      assert_includes error, 'Output already exists'
      assert_equal 'keep', File.read(File.join(output, 'keep'))
    end
  end

  def test_ai_comparison_requires_compatible_models_and_rubrics
    trial = { 'original' => { 'sentence_clarity' => 50.0 }, 'revision' => { 'sentence_clarity' => 75.0 },
              'delta' => { 'sentence_clarity' => 25.0 }, 'calibration' => { 'accuracy' => 100.0 },
              'mechanical_verification_passed' => true }
    agent = { 'agent' => 'codex', 'cli_version' => 'test', 'actual_model' => 'test-model' }
    before = { 'ai' => { 'rubric_sha256' => 'rubric', 'calibration_sha256' => 'gold',
                        'writer' => agent.dup, 'judge' => agent.dup,
                        'trials' => [trial],
                        'summary' => ProseBenchmark.trial_summary([trial]) } }
    after = Marshal.load(Marshal.dump(before))
    assert_equal 0.0, ProseBenchmark.compare_ai(before, after)['delta']['sentence_clarity']
    after['ai']['writer']['actual_model'] = 'changed-model'
    assert_raises(AsciidocPubkit::Error) { ProseBenchmark.compare_ai(before, after) }
    after['ai']['writer']['actual_model'] = 'test-model'
    after['ai']['rubric_sha256'] = 'changed-rubric'
    assert_raises(AsciidocPubkit::Error) { ProseBenchmark.compare_ai(before, after) }
    summary = ProseBenchmark.trial_summary([trial, trial.merge('delta' => { 'sentence_clarity' => 35.0 })])
    assert_equal 30.0, summary['delta']['sentence_clarity']['mean']
    assert_equal 5.0, summary['delta']['sentence_clarity']['stddev']
    assert_equal 50.0, ProseBenchmark.mechanical_pass_rate([trial, trial.merge('mechanical_verification_passed' => false)])
  end

  def fake_cli(directory, body)
    path = File.join(directory, 'codex')
    File.write(path, "#!#{RbConfig.ruby}\nif ARGV == ['--version']\n  puts 'fake-codex 1'\n  exit\nend\n" + body)
    File.chmod(0o755, path)
    { 'PATH' => "#{directory}#{File::PATH_SEPARATOR}#{ENV.fetch('PATH')}" }
  end

  def test_local_cli_failure_and_timeout_preserve_diagnostics
    Dir.mktmpdir('pubkit-fake-cli-') do |directory|
      runner = File.join(ProseBenchmark::ROOT, 'script/evaluate-prose')
      env = fake_cli(directory, "File.write(ARGV[ARGV.index('--output-last-message') + 1], 'not JSON')\n")
      invalid = File.join(directory, 'invalid')
      _, error, status = Open3.capture3(env, RbConfig.ruby, runner, '--agent', 'codex', '--output', invalid)
      assert_equal 2, status.exitstatus
      assert_includes error, 'Evaluation failed'
      assert File.file?(File.join(invalid, 'detection.json'))
      assert File.file?(File.join(invalid, 'trial-1/rewrite-response.json'))
      env = fake_cli(directory, "sleep 30\n")
      timeout = File.join(directory, 'timeout')
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      _, error, status = Open3.capture3(env, RbConfig.ruby, runner, '--agent', 'codex', '--timeout', '1', '--output', timeout)
      assert_equal 2, status.exitstatus
      assert_includes error, 'timed out'
      assert_operator Process.clock_gettime(Process::CLOCK_MONOTONIC) - started, :<, 10
      assert File.file?(File.join(timeout, 'trial-1/rewrite-prompt.txt'))
    end
  end
end
