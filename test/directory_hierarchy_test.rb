# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require 'stringio'
require 'asciidoc_pubkit'

class DirectoryHierarchyTest < Minitest::Test
  def cli(*args)
    out = StringIO.new
    err = StringIO.new
    code = AsciidocPubkit::CLI.run(args, out: out, err: err)
    [code, out.string, err.string]
  end

  def test_comparisons_are_saved_in_each_scope_and_never_rewrite_sources
    expected = ['Compare directory hierarchy terms with concrete locations',
                '2階層下のディレクトリだけを対象にします',
                '下位ディレクトリの設定で省略した値',
                'Do not broaden direct children to all descendants',
                'Do not mechanically change `子プロセス`']
    %w[criteria prompt].each do |command|
      code, output, error = cli('writing', command, '--lang', 'ja')
      assert_equal 0, code, error
      expected.each { |text| assert_includes output, text }
    end
    Dir.mktmpdir('pubkit-directory-hierarchy-') do |directory|
      manuscript = File.join(directory, 'book.adoc')
      source = "= Example\n\n== 祖先からの探索\n\n孫ディレクトリだけを対象にします。\n\n* 子孫ディレクトリを再帰的に探索します。\n"
      File.write(manuscript, source)
      %w[headings prose lists].each do |scope|
        session = File.join(directory, scope)
        code, _, error = cli('review', 'scan', manuscript, '--scope', scope,
                             '--tokenizer', 'literal', '--output', session, '--no-input')
        assert_equal 0, code, error
        saved = JSON.parse(File.read(File.join(session, 'manifest.json')))['writing_criteria']
        expected.each { |text| assert_includes saved, text }
        original = AsciidocPubkit::Writing.method(:criteria)
        begin
          AsciidocPubkit::Writing.define_singleton_method(:criteria) { |_lang| 'Later criteria' }
          code, prompt, error = cli('review', 'prompt', session)
          assert_equal 0, code, error
          assert_includes prompt, saved
          refute_includes prompt, 'Later criteria'
        ensure
          AsciidocPubkit::Writing.define_singleton_method(:criteria, original)
        end
        code, report, error = cli('review', 'verify', session)
        assert_equal 0, code, error
        assert JSON.parse(report)['passed']
        assert_equal false, JSON.parse(report)['meaning_verified']
        assert_equal source, File.read(manuscript)
      end
    end
  end

  %w[mecab literal].each do |mode|
    define_method("test_grandchild_directory_is_advisory_and_respects_protection_in_#{mode}") do
      settings = { 'tokenizer' => mode, 'allows' => [], 'glossary' => {}, 'style' => 'preserve' }
      tokenizer = mode == 'mecab' ? AsciidocPubkit::Morphology.new(settings) : nil
      scan = lambda do |text, allows = []|
        paragraph = { 'id' => 'sample', 'file' => '/example.adoc', 'line' => 1, 'text' => text }
        AsciidocPubkit::Rules.scan([paragraph], settings.merge('allows' => allows), tokenizer: tokenizer)
                           .select { |f| f['match'] == '孫ディレクトリ' }
      end
      findings = scan.call('😀孫ディレクトリだけを対象にします。')
      assert_equal 1, findings.length
      assert_equal 'contextual-phrase', findings.first['rule']
      assert_equal 'hint', findings.first['severity']
      assert_equal 2, findings.first['column']
      assert_empty scan.call('孫ディレクトリだけを対象にします。', ['孫ディレクトリ'])
      assert_empty scan.call('`孫ディレクトリ`。「孫ディレクトリ」。link:https://example.com[孫ディレクトリ]。')
      paragraph = { 'id' => 'precise', 'file' => '/example.adoc', 'line' => 1,
                    'text' => '親ディレクトリ。子プロセス。子エージェント。孫。' }
      matches = AsciidocPubkit::Rules.scan([paragraph], settings, tokenizer: tokenizer)
                                   .select { |f| f['rule'] == 'abstract-reference' }.map { |f| f['match'] }
      assert_empty matches & %w[親 子 孫 親ディレクトリ 子プロセス 子エージェント]
    end
  end

  def test_manual_comparison_fixture_preserves_depth_and_non_directory_relationships
    cases = JSON.parse(File.read(File.join(__dir__, 'fixtures/directory_hierarchy.ja.json')))
    assert_equal 10, cases.length
    assert_equal cases.length, cases.map { |c| c.fetch('id') }.uniq.length
    assert_equal %w[accept reject], cases.map { |c| c.fetch('expected_disposition') }.uniq.sort
    cases.each do |item|
      %w[source revision reason].each { |key| refute_empty item.fetch(key) }
    end
    # Fixture integrity only: these labels are manual judgments, not model-quality measurements.
    assert_equal 'reject', cases.find { |c| c['id'] == 'grandchild-broadened' }['expected_disposition']
    assert_equal 'reject', cases.find { |c| c['id'] == 'direct-child-broadened' }['expected_disposition']
    %w[process-kept tree-kept].each do |id|
      item = cases.find { |c| c['id'] == id }
      assert_equal item['source'], item['revision']
    end
  end
end
