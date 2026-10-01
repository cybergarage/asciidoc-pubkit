# frozen_string_literal: true

require 'minitest/autorun'
require 'asciidoc_pubkit'

class RulesTest < Minitest::Test
  def endings(text)
    paragraph = { 'id' => 'sample', 'file' => '/example.adoc', 'line' => 10, 'text' => text }
    settings = { 'tokenizer' => 'literal', 'allows' => [], 'glossary' => {}, 'style' => 'preserve' }
    AsciidocPubkit::Rules.scan([paragraph], settings).select { |finding| finding['rule'] == 'repeated-ending' }
  end

  def test_repeated_ending_points_to_third_sentence_in_first_run
    text = '最初に設定を検証します。完了後に続行できます。受信側はIDを検証します。送信側もIDを検証します。中継側もIDを検証します。次も検証します。'
    finding = endings(text).fetch(0)
    assert_equal 1, endings(text).length
    assert_equal '検証します', finding['match']
    assert_equal text.index('検証します', text.index('中継側')) + 1, finding['column']
    assert_equal 'info', finding['severity']
  end

  def test_multiline_unicode_positions_and_trailing_whitespace
    text = "😀 検証します！\n  検証します？\n　検証します  。"
    finding = endings(text).fetch(0)
    assert_equal [12, 2], finding.values_at('line', 'column')
  end

  def test_internal_occurrences_and_masked_examples_do_not_replace_ending_position
    text = '例は`検証します`です。検証しますという操作を説明します。入力を説明します。出力を説明します。'
    finding = endings(text).fetch(0)
    assert_equal '説明します', finding['match']
    assert_equal text.rindex('説明します') + 1, finding['column']
  end

  def test_nonmatching_sentence_interrupts_run_and_two_sentences_are_insufficient
    assert_empty endings('検証します。検証します。値を読み込む。検証します。')
    assert_empty endings('検証します。検証します。')
    assert_empty endings('`検証します`。「検証します」。検証します。')
  end
end
