# frozen_string_literal: true

require 'minitest/autorun'
require 'asciidoc_pubkit'
require 'tmpdir'
require 'stringio'

class ReplacementTest < Minitest::Test
  def setup
    @dir = File.realpath(Dir.mktmpdir('pubkit-replace-test-'))
    @book = File.join(@dir, 'book.adoc')
    @rules = File.join(@dir, 'rules.yml')
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  def rules(entries)
    File.write(@rules, { 'version' => 1, 'rules' => entries }.to_yaml)
  end

  def plan(**options)
    AsciidocPubkit::Replacement.new(@book, { rules: @rules }.merge(options))
  end

  def test_only_prose_is_replaced_and_original_bytes_are_preserved
    original = "= 題名／\r\n\r\n😀本文／と`コード／`、https://example.com／と「引用／」。\r\n次／。\r\n\r\n[source]\r\n----\r\n  code／\r\n----\r\n\r\n....\r\n  literal／\r\n....\r\n\r\n++++\r\npass／\r\n++++\r\n\r\n* list／\r\n\r\n|===\r\n|table／\r\n|===\r\n\r\n[quote]\r\n____\r\nquote／\r\n____\r\n"
    File.binwrite(@book, original)
    rules([{ 'expected' => '/', 'pattern' => '／' }])
    replacement = plan
    assert_equal 2, replacement.candidates.length
    assert_equal [3, 4], replacement.candidates.first.values_at(:line, :column)
    assert_equal original.b, File.binread(@book)
    assert_includes replacement.diff, '+😀本文/'
    replacement.apply
    assert_equal original.sub('😀本文／', '😀本文/').sub('次／', '次/').b, File.binread(@book)
  end

  def test_captures_specs_and_protected_overlap
    File.write(@book, "本文（任意）と（`code`）です。\n")
    rules([{ 'expected' => '($1)', 'pattern' => '/（([^（）\r\n]+)）/',
             'specs' => [{ 'from' => '設定（任意）', 'to' => '設定(任意)' }] }])
    replacement = plan
    assert_equal 1, replacement.candidates.length
    replacement.apply
    assert_equal "本文(任意)と（`code`）です。\n", File.read(@book)
  end

  def test_empty_result_literal_patterns_and_no_chaining
    File.write(@book, "本文AとCです。\n")
    rules([{ 'expected' => 'C', 'patterns' => ['A', 'B'] }, { 'expected' => '', 'pattern' => 'C' }])
    plan.apply
    assert_equal "本文Cとです。\n", File.read(@book)
  end

  def test_pattern_array_supports_captures_specs_and_inline_protection
    File.write(@book, "本文（任意）と[任意]、`[任意]`。\n")
    rules([{ 'expected' => '($1)',
             'pattern' => ['/（([^（）\r\n]+)）/', '/\[([^\]\r\n]+)\]/'],
             'specs' => [{ 'from' => '設定（任意）と[任意]', 'to' => '設定(任意)と(任意)' }] }])
    replacement = plan
    assert_equal 2, replacement.candidates.length
    replacement.apply
    assert_equal "本文(任意)と(任意)、`[任意]`。\n", File.read(@book)
  end

  def test_pattern_array_is_equivalent_to_patterns_and_conflicts_are_rejected
    File.write(@book, "本文AとBです。\n")
    rules([{ 'expected' => 'C', 'patterns' => ['A', 'B'] }])
    expected = plan.candidates
    rules([{ 'expected' => 'C', 'pattern' => ['A', 'B'] }])
    assert_equal expected, plan.candidates
    rules([{ 'expected' => 'C', 'pattern' => ['本文', '文'] }])
    assert_raises(AsciidocPubkit::Error) { plan }
  end

  def test_pattern_arrays_reject_invalid_elements_and_both_keys
    File.write(@book, "本文です。\n")
    [[], [''], [nil], [1], [['文']], ['文', nil]].each do |patterns|
      rules([{ 'expected' => 'X', 'pattern' => patterns }])
      assert_raises(AsciidocPubkit::Error, patterns.inspect) { plan }
    end
    rules([{ 'expected' => 'X', 'pattern' => ['文'], 'patterns' => ['文'] }])
    assert_raises(AsciidocPubkit::Error) { plan }
    rules([{ 'expected' => 'X', 'pattern' => ['/文/m'] }])
    error = assert_raises(AsciidocPubkit::Error) { plan }
    assert_includes error.message, 'Unsupported regex flags'
  end

  def test_ignore_case_flag_works_in_arrays_specs_and_protected_prose
    File.write(@book, "EARLY-EX群とearlyex群、`Early-EX群`。\n")
    rules([{ 'expected' => '早期運動群', 'pattern' => ['/Early-?EX群/i'],
             'specs' => [{ 'from' => 'EARLY-EX群とearlyex群', 'to' => '早期運動群と早期運動群' }] }])
    replacement = plan
    assert_equal 2, replacement.candidates.length
    replacement.apply
    assert_equal "早期運動群と早期運動群、`Early-EX群`。\n", File.read(@book)
  end

  def test_javascript_boundaries_match_ascii_terms_next_to_japanese
    File.write(@book, "前Tips後 Tips Tips2 _Tips Tips_ ATips、`Tips`。\n")
    rules([{ 'expected' => '実践', 'pattern' => '/\bTips\b/' }])
    replacement = plan
    assert_equal 2, replacement.candidates.length
    assert_equal [2, 8], replacement.candidates.map { |edit| edit[:column] }
    replacement.apply
    assert_equal "前実践後 実践 Tips2 _Tips Tips_ ATips、`Tips`。\n", File.read(@book)
  end

  def test_boundary_conversion_does_not_add_captures_or_change_match_offsets
    File.write(@book, "😀測定10 kg後と20kg。\n")
    rules([{ 'expected' => '$1$2', 'pattern' => '/\b(\d+)\s+([A-Za-z]+)\b/',
             'specs' => [{ 'from' => '前10 kg後', 'to' => '前10kg後' }] }])
    replacement = plan
    assert_equal [1, 4, '10 kg', '10kg'], replacement.candidates.first.values_at(:line, :column, :before, :after)
    replacement.apply
    assert_equal "😀測定10kg後と20kg。\n", File.read(@book)
  end

  def test_nonboundary_and_unicode_ignore_case_word_characters
    rules([{ 'expected' => 'X', 'pattern' => '/\BTips\B/',
             'specs' => [{ 'from' => 'ATips2 前Tips後', 'to' => 'AX2 前Tips後' }] }])
    AsciidocPubkit::ReplacementRules.load(@rules)
    rules([{ 'expected' => 'X', 'pattern' => '/\bTips\b/i',
             'specs' => [{ 'from' => 'ſTips TipsK 前tIpS後', 'to' => 'ſTips TipsK 前X後' }] }])
    AsciidocPubkit::ReplacementRules.load(@rules)
    rules([{ 'expected' => 'X', 'pattern' => '/\bTips\b/',
             'specs' => [{ 'from' => 'ſTips TipsK', 'to' => 'ſX XK' }] }])
    AsciidocPubkit::ReplacementRules.load(@rules)
  end

  def test_boundary_escapes_in_classes_and_literal_backslashes
    rules([{ 'expected' => 'X', 'pattern' => '/[\b]/',
             'specs' => [{ 'from' => "a\bb", 'to' => 'aXb' }] }])
    AsciidocPubkit::ReplacementRules.load(@rules)
    rules([{ 'expected' => 'X', 'pattern' => '/\\\\b/',
             'specs' => [{ 'from' => 'a\bb', 'to' => 'aXb' }] }])
    AsciidocPubkit::ReplacementRules.load(@rules)
    rules([{ 'expected' => 'X', 'pattern' => '/[\B]/' }])
    assert_raises(AsciidocPubkit::Error) { AsciidocPubkit::ReplacementRules.load(@rules) }
  end

  def test_overlap_and_structure_changes_are_rejected_without_writes
    File.write(@book, "通常本文です。\n")
    original = File.read(@book)
    rules([{ 'expected' => '別', 'pattern' => '通常' }, { 'expected' => '別', 'pattern' => '常' }])
    assert_raises(AsciidocPubkit::Error) { plan }
    rules([{ 'expected' => '== ', 'pattern' => '通常' }])
    assert_raises(AsciidocPubkit::Error) { plan }
    rules([{ 'expected' => '`通常`', 'pattern' => '通常' }])
    assert_raises(AsciidocPubkit::Error) { plan }
    assert_equal original, File.read(@book)
  end

  def test_stale_sources_are_rejected
    File.write(@book, "本文／です。\n")
    rules([{ 'expected' => '/', 'pattern' => '／' }])
    replacement = plan
    File.write(@book, "新本文／です。\n")
    assert_raises(AsciidocPubkit::Error) { replacement.apply }
    assert_equal "新本文／です。\n", File.read(@book)
  end

  def test_relative_includes_and_only
    chapter = File.join(@dir, 'chapter.adoc')
    File.write(@book, "= Book\n\n本文／。\n\ninclude::chapter.adoc[]\n")
    File.write(chapter, "章本文／。\n")
    rules([{ 'expected' => '/', 'pattern' => '／' }])
    plan(only: chapter).apply
    assert_includes File.read(@book), '本文／'
    assert_equal "章本文/。\n", File.read(chapter)
  end

  def test_strict_rules_and_specs
    File.write(@book, "本文です。\n")
    invalid = [
      { 'expected' => 'X' },
      { 'expected' => 'X', 'pattern' => 'Y', 'options' => {} },
      { 'expected' => 'X', 'pattern' => '/Y/g' },
      { 'expected' => 'X', 'pattern' => '/(?=文)/' },
      { 'expected' => '$2', 'pattern' => '/(文)/' },
      { 'expected' => 'X', 'pattern' => '文', 'specs' => [{ 'from' => '文', 'to' => 'wrong' }] },
      { 'expected' => 'X', 'pattern' => '/\\p{Han}/' }
    ]
    invalid.each do |entry|
      rules([entry])
      assert_raises(AsciidocPubkit::Error, entry.inspect) { plan }
    end
  end

  def test_configuration_excludes_files_without_loading_review_rules_or_mecab
    chapter = File.join(@dir, 'chapter.adoc')
    File.write(@book, "= Book\n\n本文／。\n\ninclude::chapter.adoc[]\n")
    File.write(chapter, "章本文／。\n")
    config = File.join(@dir, '.asciidoc-pubkit.yml')
    File.write(config, { 'review' => { 'exclude' => ['chapter.adoc'], 'rules' => 'missing.yml',
                                     'mecab_command' => '/missing/mecab' } }.to_yaml)
    rules([{ 'expected' => '/', 'pattern' => '／' }])
    plan.apply
    assert_includes File.read(@book), '本文/'
    assert_equal "章本文／。\n", File.read(chapter)
  end

  def test_failed_second_install_restores_first_source
    chapter = File.join(@dir, 'chapter.adoc')
    File.write(@book, "= Book\n\n本文／。\n\ninclude::chapter.adoc[]\n")
    File.write(chapter, "章本文／。\n")
    rules([{ 'expected' => '/', 'pattern' => '／' }])
    originals = [@book, chapter].to_h { |path| [path, File.binread(path)] }
    replacement = plan
    rename = File.method(:rename)
    calls = 0
    failing_rename = lambda do |from, to|
      calls += 1
      raise Errno::EIO if calls == 2
      rename.call(from, to)
    end
    begin
      File.define_singleton_method(:rename, failing_rename)
      assert_raises(Errno::EIO) { replacement.apply }
    ensure
      File.define_singleton_method(:rename, rename)
    end
    originals.each { |path, raw| assert_equal raw, File.binread(path) }
    assert_empty Dir.glob(File.join(@dir, '.pubkit-replace-*'))
  end

  def test_line_breaks_and_symlink_entry_are_rejected
    File.write(@book, "本文／。\n次。\n")
    rules([{ 'expected' => "a\nb", 'pattern' => '／' }])
    assert_raises(AsciidocPubkit::Error) { plan }
    rules([{ 'expected' => '/', 'pattern' => '／' }])
    link = File.join(@dir, 'linked.adoc')
    File.symlink(@book, link)
    assert_raises(AsciidocPubkit::Error) { AsciidocPubkit::Replacement.new(link, rules: @rules) }
  end

  def write_import_file(path, data)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, { 'version' => 1 }.merge(data).to_yaml)
  end

  def test_nested_imports_resolve_from_each_file_and_assign_unique_ids
    common = File.join(@dir, 'shared', 'common.yml')
    parent = File.join(@dir, 'nested', 'parent.yml')
    write_import_file(common, 'rules' => [{ 'expected' => 'B', 'pattern' => 'A' }])
    write_import_file(parent, 'imports' => ['../shared/common.yml'],
                      'rules' => [{ 'expected' => 'D', 'pattern' => 'C' }])
    write_import_file(@rules, 'imports' => [{ 'path' => 'nested/parent.yml' }],
                      'rules' => [{ 'expected' => 'F', 'pattern' => 'E' }])
    File.write(@book, "本文ACEと`ACE`。\n")
    replacement = Dir.chdir(File.dirname(@dir)) { plan }
    assert_equal %w[rule-1 rule-2 rule-3], replacement.candidates.map { |edit| edit[:rule] }
    replacement.apply
    assert_equal "本文BDFと`ACE`。\n", File.read(@book)
  end

  def test_shared_imports_and_symlink_aliases_load_each_physical_file_once
    shared = File.join(@dir, 'shared.yml')
    left = File.join(@dir, 'left.yml')
    right = File.join(@dir, 'right.yml')
    alias_path = File.join(@dir, 'alias.yml')
    write_import_file(shared, 'rules' => [{ 'expected' => '/', 'pattern' => '／' }])
    File.symlink(shared, alias_path)
    write_import_file(left, 'imports' => ['shared.yml'])
    write_import_file(right, 'imports' => ['alias.yml'])
    write_import_file(@rules, 'imports' => ['left.yml', 'right.yml', shared])
    File.write(@book, "本文／。\n")
    assert_equal 1, AsciidocPubkit::ReplacementRules.load(@rules).length
    plan.apply
    assert_equal "本文/。\n", File.read(@book)
  end

  def test_import_cycles_include_aliases_and_fail_before_writing
    File.write(@book, "本文／。\n")
    alias_path = File.join(@dir, 'alias.yml')
    File.symlink(@rules, alias_path)
    write_import_file(@rules, 'imports' => ['alias.yml'])
    error = assert_raises(AsciidocPubkit::Error) { plan }
    assert_includes error.message, 'Circular replacement imports'
    parent = File.join(@dir, 'parent.yml')
    write_import_file(@rules, 'imports' => ['parent.yml'])
    write_import_file(parent, 'imports' => ['rules.yml'])
    assert_raises(AsciidocPubkit::Error) { plan }
    assert_equal "本文／。\n", File.read(@book)
  end

  def test_import_validation_and_specs_are_not_bypassed
    File.write(@book, "本文／。\n")
    child = File.join(@dir, 'child.yml')
    write_import_file(@rules, 'imports' => ['child.yml'])
    [
      { 'version' => 2 },
      { 'rules' => false },
      { 'rules' => 'invalid' },
      { 'rules' => {} },
      { 'imports' => 'file.yml' },
      { 'imports' => [nil] },
      { 'imports' => [''] },
      { 'imports' => ['https://example.com/rules.yml'] },
      { 'imports' => [{ 'path' => 'file.yml', 'ignoreRules' => [] }] },
      { 'imports' => [{ 'path' => 'file.yml', 'disableImports' => true }] },
      { 'targets' => [] },
      { 'rules' => [{ 'expected' => 'X', 'pattern' => 'Y',
                     'specs' => [{ 'from' => 'Y', 'to' => 'wrong' }] }] }
    ].each do |data|
      write_import_file(child, data)
      assert_raises(AsciidocPubkit::Error, data.inspect) { plan }
    end
    File.write(child, "version: [\n")
    error = assert_raises(AsciidocPubkit::Error) { plan }
    assert_includes error.message, child
    File.unlink(child)
    out = StringIO.new
    err = StringIO.new
    assert_equal 2, AsciidocPubkit::CLI.run(['replace', 'apply', @book, '--rules', @rules], out: out, err: err)
    assert_includes err.string, 'child.yml'
    assert_equal "本文／。\n", File.read(@book)
  end

  def test_imported_rules_still_conflict_with_local_rules
    File.write(@book, "本文／。\n")
    child = File.join(@dir, 'child.yml')
    write_import_file(child, 'rules' => [{ 'expected' => '/', 'pattern' => '／' }])
    write_import_file(@rules, 'imports' => ['child.yml'],
                      'rules' => [{ 'expected' => '-', 'pattern' => '／' }])
    assert_raises(AsciidocPubkit::Error) { plan }
    assert_equal "本文／。\n", File.read(@book)
  end

  def test_import_depth_limit_and_empty_configuration
    write_import_file(@rules, {})
    assert_empty AsciidocPubkit::ReplacementRules.load(@rules)
    101.times do |index|
      write_import_file(File.join(@dir, "depth-#{index}.yml"),
                        index == 100 ? {} : { 'imports' => ["depth-#{index + 1}.yml"] })
    end
    error = assert_raises(AsciidocPubkit::Error) do
      AsciidocPubkit::ReplacementRules.load(File.join(@dir, 'depth-0.yml'))
    end
    assert_includes error.message, 'maximum depth'
  end

  def test_version_only_rules_file_is_a_successful_cli_no_op
    original = "本文／と`コード／`。\r\n"
    File.binwrite(@book, original)
    write_import_file(@rules, {})
    %w[check diff apply].each do |command|
      out = StringIO.new
      err = StringIO.new
      result = AsciidocPubkit::CLI.run(['replace', command, @book, '--rules', @rules], out: out, err: err)
      assert_equal 0, result, err.string
      assert_empty err.string
      if command == 'diff'
        assert_empty out.string
      else
        assert_includes out.string, '0 replacements'
      end
      assert_equal original.b, File.binread(@book)
    end
  end

  def test_null_rules_are_a_cli_no_op_and_do_not_discard_imported_rules
    original = "本文／と`コード／`。\r\n"
    File.binwrite(@book, original)
    child = File.join(@dir, 'child.yml')
    write_import_file(child, 'rules' => [{ 'expected' => '/', 'pattern' => '／' }])
    ["rules:", "rules: null", "rules: ~"].each do |declaration|
      File.write(@rules, "version: 1\n#{declaration}\n")
      %w[check diff apply].each do |command|
        out = StringIO.new
        err = StringIO.new
        assert_equal 0, AsciidocPubkit::CLI.run(['replace', command, @book, '--rules', @rules], out: out, err: err), err.string
        assert_empty err.string
        assert_equal original.b, File.binread(@book)
      end
      File.write(@rules, "version: 1\nimports:\n  - child.yml\n#{declaration}\n")
      replacement = plan
      assert_equal 1, replacement.candidates.length
      replacement.apply
      assert_equal original.sub('本文／', '本文/').b, File.binread(@book)
      File.binwrite(@book, original)
    end
  end

  def test_null_rules_in_imported_file_preserve_nested_imports
    File.write(@book, "本文／。\n")
    child = File.join(@dir, 'child.yml')
    leaf = File.join(@dir, 'leaf.yml')
    write_import_file(@rules, 'imports' => ['child.yml'])
    write_import_file(child, 'imports' => ['leaf.yml'], 'rules' => nil)
    write_import_file(leaf, 'rules' => [{ 'expected' => '/', 'pattern' => '／' }])
    plan.apply
    assert_equal "本文/。\n", File.read(@book)
  end

  def test_cli_applies_imported_rules_when_entry_and_intermediate_rules_are_omitted
    child = File.join(@dir, 'child.yml')
    leaf = File.join(@dir, 'leaf.yml')
    empty = File.join(@dir, 'empty.yml')
    write_import_file(@rules, 'imports' => ['child.yml'])
    write_import_file(child, 'imports' => ['empty.yml', 'leaf.yml'])
    write_import_file(empty, {})
    write_import_file(leaf, 'rules' => [{ 'expected' => '/', 'pattern' => '／' }])
    File.write(@book, "本文／と`コード／`。\n")
    out = StringIO.new
    err = StringIO.new
    args = [@book, '--rules', @rules]
    assert_equal 1, AsciidocPubkit::CLI.run(['replace', 'check', *args], out: out, err: err)
    assert_equal 0, AsciidocPubkit::CLI.run(['replace', 'apply', *args], out: out, err: err)
    assert_empty err.string
    assert_equal "本文/と`コード／`。\n", File.read(@book)
  end

  def test_cli_exit_codes_and_no_overwrite
    File.write(@book, "本文／。\n")
    rules([{ 'expected' => '/', 'pattern' => '／' }])
    out = StringIO.new
    err = StringIO.new
    assert_equal 1, AsciidocPubkit::CLI.run(['replace', 'check', @book, '--rules', @rules], out: out, err: err)
    assert_equal 0, AsciidocPubkit::CLI.run(['replace', 'diff', @book, '--rules', @rules], out: out, err: err)
    assert_includes File.read(@book), '／'
    assert_equal 2, AsciidocPubkit::CLI.run(['replace', 'diff', @book, '--rules', @rules, '-o', @book], out: out, err: err)
    assert_equal 0, AsciidocPubkit::CLI.run(['replace', 'apply', @book, '--rules', @rules], out: out, err: err)
    assert_equal 0, AsciidocPubkit::CLI.run(['replace', 'check', @book, '--rules', @rules], out: out, err: err)
    assert_equal 2, AsciidocPubkit::CLI.run(['replace', 'check', @book], out: out, err: err)
  end
end
