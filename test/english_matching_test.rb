# frozen_string_literal: true
require 'minitest/autorun'
require 'asciidoc_pubkit'

class EnglishMatchingTest < Minitest::Test
  def rule(terms: ['due to the fact that'], kind: 'phrase', exceptions: [])
    { 'id' => 'wordy-expression', 'match' => kind, 'terms' => terms, 'case' => 'insensitive',
      'boundary' => 'lexical', 'severity' => 'hint', 'question' => 'Compare a direct alternative.', 'exceptions' => exceptions }
  end

  def scan(text, item = rule)
    settings = { 'rules' => { 'schema_version' => 2, 'language' => 'en', 'rules' => [item] }, 'allows' => [], 'glossary' => {} }
    AsciidocPubkit::EnglishRules.scan([{ 'id' => 'p', 'file' => 'book.adoc', 'line' => 3, 'column' => 1, 'text' => text }], settings)
  end

  def test_wrapped_phrases_preserve_original_surfaces_and_unicode_columns
    text = "😀 e\u0301 日本語\nDUE to\nthe fact that the disk is full."
    f = scan(text).fetch(0)
    assert_equal "DUE to\nthe fact that", f['match']
    assert_equal [4, 1], f.values_at('line', 'column')
    f = scan("😀 e\u0301 due to the fact that it failed.").fetch(0)
    assert_equal 6, f['column']
  end

  def test_no_joining_across_protected_spans_or_punctuation
    ['due `code` to the fact that', 'due https://example.org to the fact that',
     'due {attr} to the fact that', 'due, to the fact that', 'due xref:x[label] to the fact that'].each do |text|
      assert_empty scan(text), text
    end
    assert_equal 1, scan('"due to the fact that"').length
  end

  def test_boundaries_keep_identifiers_compounds_contractions_and_mixed_scripts
    item = rule(terms: ['can'])
    ["can't", 'can’t', 'can-do', 'can_do', 'can1', 'can.method', '日本can', "can\u0301"].each { |text| assert_empty scan(text, item), text }
    assert_equal 1, scan('CAN.', item).length
  end

  def test_duplicate_word_exceptions_and_barriers
    item = rule(terms: [], kind: 'repeated-word', exceptions: ['had had', 'that that'])
    assert_equal ["the\nthe"], scan("the\nthe file", item).map { |f| f['match'] }
    ['had had', 'that that', 'the, the', 'the `x` the'].each { |t| assert_empty scan(t, item) }
  end

  def test_strict_schema_case_and_exceptions
    item = rule(terms: ['CAN']); item['case'] = 'sensitive'
    assert_empty scan('can', item)
    assert_equal 1, scan('CAN', item).length
    assert_empty scan('CAN', item.merge('exceptions' => ['CAN']))
    %w[unknown boundary match severity case].each do |key|
      assert_raises(AsciidocPubkit::Error) { scan('text', item.merge(key => 'invalid')) }
    end
  end
end
