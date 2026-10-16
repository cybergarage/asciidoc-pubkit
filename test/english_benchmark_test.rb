# frozen_string_literal: true
require 'minitest/autorun'
require_relative '../benchmark/english'

class EnglishBenchmarkTest < Minitest::Test
  def test_corpus_has_document_disjoint_partitions_and_original_span_labels
    corpus = EnglishBenchmark.load_corpus
    rows = corpus['paragraphs']
    assert_equal 120, rows.length
    assert_equal rows.length, rows.map { |r| r['text'] }.uniq.length
    assert_equal [60, 60], %w[development held_out].map { |s| rows.count { |r| r['split'] == s } }
    refute_empty rows.select { |r| r['expected'].empty? }
    documents = rows.group_by { |r| r['split'] }.transform_values { |items| items.map { |i| i['document'] }.uniq }
    assert_empty documents['development'] & documents['held_out']
  end

  def test_detection_quality_and_candidate_density_match_the_reviewed_baseline
    baseline = JSON.parse(File.read(File.expand_path('../benchmark/baseline-english.json', __dir__)))
    report = EnglishBenchmark.evaluate
    assert report['passed'], report.inspect
    assert EnglishBenchmark.compare(report, baseline)['passed']
    assert_equal baseline['metrics'], report['metrics']
    assert_equal baseline['by_rule'], report['by_rule']
    assert_equal baseline['score'], report['score']
    assert_equal 'not_run', report['semantic_evaluation']
    %w[development held_out].each do |split|
      partition = EnglishBenchmark.evaluate(split: split)
      assert partition['passed'], partition.inspect
      assert_equal 60, partition['paragraphs']
    end
  end

  def test_disabled_detector_fails_quality_even_when_fewer_candidates_look_better
    empty_scanner = Object.new
    empty_scanner.define_singleton_method(:scan) { |*| [] }
    baseline = EnglishBenchmark.evaluate
    report = EnglishBenchmark.evaluate(scanner: empty_scanner)
    refute report['passed']
    assert_equal 0, report['metrics']['recall']
    comparison = EnglishBenchmark.compare(report, baseline)
    refute comparison['passed']
    refute comparison['density_change_is_quality_evidence']
    assert_includes comparison['regressions'], 'recall'
  end

  def test_incorrect_offsets_and_duplicate_findings_are_regressions
    scanner = Object.new
    scanner.define_singleton_method(:scan) do |entries, settings|
      findings = AsciidocPubkit::EnglishRules.scan(entries, settings)
      findings.map { |f| f.merge('column' => f['column'] + 1) }
    end
    report = EnglishBenchmark.evaluate(scanner: scanner)
    refute report['passed']
    assert_operator report['metrics']['false_positives'], :>, 0
    assert_operator report['metrics']['location_accuracy'], :<, 1
    assert_equal 0.5, EnglishBenchmark.metrics([['span']], [['span'], ['span']])['precision']
    assert_raises(RuntimeError) { EnglishBenchmark.compare(report, report.merge('corpus_sha256' => 'different')) }
  end

  def calibration
    JSON.parse(File.read(EnglishBenchmark::CALIBRATION))['pairs']
  end

  # Synthetic responses verify the evaluator harness; they are not model trials.
  def synthetic_judgments
    { 'evaluator' => 'synthetic-test-fixture', 'judgments' => calibration.map do |pair|
      { 'id' => pair['id'], 'decision' => pair['expected_decision'],
        'sentence_clarity' => 3, 'paragraph_coherence' => 2,
        'retained_facts' => pair['expected_retained_facts'], 'reason' => 'Synthetic response for harness testing.' }
    end }
  end

  def test_calibration_includes_readable_but_wrong_revisions_and_hides_labels
    assert_equal 24, calibration.length
    assert_equal 12, calibration.count { |p| p['expected_decision'] == 'reject' }
    calibration.each do |pair|
      assert_equal pair['facts'].length, pair['expected_retained_facts'].length
      assert_equal(pair['expected_decision'] == 'accept', pair['expected_retained_facts'].all?)
    end
    prompt = EnglishBenchmark.judge_prompt
    refute_includes prompt, 'expected_decision'
    refute_includes prompt, 'expected_retained_facts'
    result = EnglishBenchmark.evaluate_judgments(synthetic_judgments)
    assert result['passed']
    refute result['meaning_verified']
    assert_equal 100, result['sentence_clarity']
    assert_equal 50, result['paragraph_coherence']
  end

  def test_judge_that_accepts_fluent_wrong_revisions_fails_despite_high_ratings
    judgments = synthetic_judgments
    judgments['judgments'].each do |row|
      row['decision'] = 'accept'
      row['retained_facts'] = row['retained_facts'].map { true }
      row['paragraph_coherence'] = 3
    end
    report = EnglishBenchmark.evaluate_judgments(judgments)
    assert_equal 100, report['sentence_clarity']
    assert_equal 100, report['paragraph_coherence']
    assert_equal 12, report['false_accepts']
    refute report['passed']
  end

  def test_malformed_or_inconsistent_judgments_cannot_count_as_quality_evidence
    bad = synthetic_judgments
    bad['judgments'].pop
    assert_raises(RuntimeError) { EnglishBenchmark.evaluate_judgments(bad) }
    bad = synthetic_judgments
    bad['judgments'][0]['retained_facts'][0] = false
    assert_raises(RuntimeError) { EnglishBenchmark.evaluate_judgments(bad) }
    bad = synthetic_judgments
    bad['judgments'][0]['sentence_clarity'] = 4
    assert_raises(RuntimeError) { EnglishBenchmark.evaluate_judgments(bad) }
    bad = synthetic_judgments
    bad['judgments'][0] = bad['judgments'][1]
    assert_raises(RuntimeError) { EnglishBenchmark.evaluate_judgments(bad) }
  end

  def test_higher_density_score_does_not_rescue_a_meaning_changing_revision
    pair = calibration.find { |p| p['category'] == 'framing' && p['expected_decision'] == 'reject' }
    scores = Dir.mktmpdir('pubkit-en-score-proof-') do |dir|
      %w[source revision].map do |key|
        book = File.join(dir, "#{key}.adoc")
        File.write(book, "= Test\n:lang: en\n\n#{pair[key]}\n")
        AsciidocPubkit::Score.run(book, language: 'en')['score']
      end
    end
    assert_operator scores[1], :>, scores[0]
    assert_equal 'reject', pair['expected_decision']
  end
end
