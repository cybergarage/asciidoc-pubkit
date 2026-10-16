# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require 'stringio'
require 'asciidoc_pubkit'

class SkillCommandsTest < Minitest::Test
  NAME = 'review-asciidoc-manuscript'

  def setup
    @dir = File.realpath(Dir.mktmpdir('pubkit-skills-'))
    @root = File.join(@dir, 'project', '.agents', 'skills')
    @installed = File.join(@root, NAME)
    @bundle = File.join(@dir, 'bundle')
    FileUtils.cp_r(AsciidocPubkit::SkillCommands.bundled_root, @bundle)
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  def override(object, method, replacement)
    original = object.method(method)
    object.singleton_class.send(:remove_method, method)
    object.define_singleton_method(method, replacement)
    yield
  ensure
    object.singleton_class.send(:remove_method, method)
    object.define_singleton_method(method, original)
  end

  def cli(command, *args)
    out, err = StringIO.new, StringIO.new
    bundle = @bundle
    code = override(AsciidocPubkit::SkillCommands, :bundled_root, -> { bundle }) do
      AsciidocPubkit::CLI.run(['skill', command, *args], out: out, err: err)
    end
    [code, out.string, err.string]
  end

  def run_skill(command, *extra)
    cli(command, NAME, '--dir', @root, *extra)
  end

  def install
    code, _, err = run_skill('install')
    assert_equal 0, code, err
  end

  def report
    code, out, err = run_skill('status', '--json')
    [code, JSON.parse(out), err]
  end

  def inventory
    Dir.glob(File.join(@installed, '**', '*'), File::FNM_DOTMATCH).select { |f| File.file?(f) }.to_h { |f| [f, File.binread(f)] }
  end

  def test_list_help_and_argument_validation_without_creating_directories
    code, out, err = cli('list', '--json')
    assert_equal 0, code, err
    assert_equal [NAME], JSON.parse(out)['skills'].map { |s| s['name'] }
    assert_equal 0, cli('list', '--help')[0]
    assert_equal 0, cli('--help')[0]
    %w[install status upgrade].each { |command| assert_equal 0, cli(command, '--help')[0] }
    assert_equal 2, cli('remove', NAME, '--dir', @root)[0]
    assert_equal 2, cli('install', NAME)[0]
    assert_equal 2, cli('install', '../escape', '--dir', @root)[0]
    assert_equal 2, cli('install', 'unknown', '--dir', @root)[0]
    assert_equal 2, cli('list', NAME)[0]
    assert_equal 2, run_skill('install', '--force')[0]
    refute File.exist?(@root)
  end

  def test_agent_project_paths_share_the_standard_bundle_and_support_upgrade
    Dir.chdir(@dir) do
      { 'codex' => '.agents/skills', 'claude' => '.claude/skills' }.each do |agent, parent|
        code, out, err = cli('install', NAME, '--agent', agent)
        assert_equal 0, code, err
        target = File.join(@dir, parent, NAME)
        assert_includes out, target
        assert_equal File.read(File.join(@bundle, NAME, 'SKILL.md')), File.read(File.join(target, 'SKILL.md'))
        assert_equal 0, cli('status', NAME, '--agent', agent, '--json')[0]
      end
      File.open(File.join(@bundle, NAME, 'SKILL.md'), 'a') { |file| file.puts "Updated shared guidance." }
      %w[codex claude].each do |agent|
        assert_equal 1, cli('status', NAME, '--agent', agent)[0]
        assert_equal 0, cli('upgrade', NAME, '--agent', agent)[0]
        assert_equal 0, cli('status', NAME, '--agent', agent)[0]
      end
    end
  end

  def test_agent_validation_and_status_are_read_only
    Dir.chdir(@dir) do
      %w[install status upgrade].each do |command|
        assert_equal 2, cli(command, NAME, '--agent', 'unknown')[0]
        assert_equal 2, cli(command, NAME, '--agent', 'codex', '--dir', @root)[0]
        assert_equal 2, cli(command, NAME, '--dir', @root, '--agent', 'claude')[0]
      end
      assert_equal 2, cli('list', '--agent', 'codex')[0]
      assert_equal 1, cli('status', NAME, '--agent', 'codex')[0]
      assert_equal 2, cli('upgrade', NAME, '--agent', 'claude')[0]
      refute File.exist?('.agents')
      refute File.exist?('.claude')
    end
  end

  def test_status_is_read_only_and_upgrade_does_not_create_missing_destinations
    assert_equal 1, report[0]
    assert_equal 'not-installed', report[1]['state']
    refute File.exist?(@root)
    assert_equal 2, run_skill('upgrade')[0]
    refute File.exist?(@root)
  end

  def test_relative_destination_and_unrelated_sibling_are_preserved
    sibling = File.join(@root, 'custom-skill')
    FileUtils.mkdir_p(sibling)
    File.write(File.join(sibling, 'SKILL.md'), 'Unmanaged sibling')
    Dir.chdir(@dir) do
      assert_equal 0, cli('install', NAME, '--dir', 'project/.agents/skills')[0]
      assert_equal 0, cli('status', NAME, '--dir', 'project/.agents/skills')[0]
    end
    assert_equal 'Unmanaged sibling', File.read(File.join(sibling, 'SKILL.md'))
    assert_equal 'current', report[1]['state']
  end

  def test_install_current_and_idempotent_upgrade
    install
    assert_equal File.read(File.join(@bundle, NAME, 'SKILL.md')), File.read(File.join(@installed, 'SKILL.md'))
    before = inventory
    assert_equal 0, report[0]
    assert_equal 'current', report[1]['state']
    assert_equal AsciidocPubkit::VERSION, report[1]['installed_version']
    code, out, err = run_skill('upgrade')
    assert_equal 0, code, err
    assert_includes out, 'Already current'
    assert_equal before, inventory
    assert_equal 2, run_skill('install')[0]
    assert_equal before, inventory
    refute File.exist?(File.join(@root, AsciidocPubkit::SkillCommands::LOCK))
  end

  def test_upgrade_tracks_updated_added_and_removed_resources
    old_resource = File.join(@bundle, NAME, 'old.txt')
    File.write(old_resource, 'previous resource')
    install
    File.delete(old_resource)
    FileUtils.mkdir_p(File.join(@bundle, NAME, 'references'))
    File.write(File.join(@bundle, NAME, 'references', 'workflow.md'), '# New workflow')
    File.open(File.join(@bundle, NAME, 'SKILL.md'), 'a') { |f| f.puts "\nUpdated guidance." }
    code, result, err = report
    assert_equal 1, code, err
    assert_equal 'update-available', result['state']
    assert_equal ['SKILL.md', 'old.txt', 'references/workflow.md'], result['updated']
    code, _, err = run_skill('upgrade')
    assert_equal 0, code, err
    refute File.exist?(File.join(@installed, 'old.txt'))
    assert_equal '# New workflow', File.read(File.join(@installed, 'references', 'workflow.md'))
    assert_equal 'current', report[1]['state']
    assert_empty Dir.glob(File.join(@root, '.asciidoc-pubkit-skill-*'))
  end

  def test_unmanaged_empty_and_populated_destinations_are_kept
    FileUtils.mkdir_p(@installed)
    assert_equal 'unmanaged', report[1]['state']
    assert_equal 2, run_skill('install')[0]
    assert_equal 2, run_skill('upgrade')[0]
    File.write(File.join(@installed, 'SKILL.md'), 'User-owned skill')
    assert_equal 2, run_skill('upgrade')[0]
    assert_equal 'User-owned skill', File.read(File.join(@installed, 'SKILL.md'))
  end

  def test_modified_missing_extra_files_and_empty_directories_block_upgrade
    install
    title = File.join(@installed, 'SKILL.md')
    original = File.read(title)
    File.write(title, original + "\nLocal instructions.")
    assert_equal ['SKILL.md'], report[1]['modified']
    before = inventory
    assert_equal 2, run_skill('upgrade')[0]
    assert_equal before, inventory
    File.delete(title)
    assert_equal ['SKILL.md'], report[1]['missing']
    assert_equal 2, run_skill('upgrade')[0]
    File.write(title, original)
    extra = File.join(@installed, 'custom.md')
    File.write(extra, 'Local guide')
    assert_equal ['custom.md'], report[1]['extra']
    assert_equal 2, run_skill('upgrade')[0]
    File.delete(extra)
    Dir.mkdir(File.join(@installed, 'custom'))
    assert_equal ['custom/'], report[1]['extra']
    assert_equal 2, run_skill('upgrade')[0]
    assert File.directory?(File.join(@installed, 'custom'))
  end

  def test_symlink_roots_destinations_registration_and_resources_are_rejected
    FileUtils.mkdir_p(File.dirname(@root))
    File.symlink(@dir, @root)
    assert_equal 2, run_skill('install')[0]
    File.unlink(@root)
    FileUtils.mkdir_p(@root)
    File.symlink(@dir, @installed)
    assert_equal 2, run_skill('install')[0]
    assert_equal 2, run_skill('status')[0]
    File.unlink(@installed)
    install
    manifest = File.join(@installed, AsciidocPubkit::SkillCommands::MANIFEST)
    text = File.read(manifest)
    File.delete(manifest)
    File.symlink(File.join(@dir, 'missing'), manifest)
    assert_equal 2, run_skill('status')[0]
    File.unlink(manifest)
    File.write(manifest, text)
    File.symlink(File.join(@dir, 'missing'), File.join(@installed, 'resource'))
    assert_equal 2, run_skill('upgrade')[0]
    assert File.symlink?(File.join(@installed, 'resource'))
  end

  def test_corrupt_registration_and_path_traversal_are_rejected_without_edits
    install
    path = File.join(@installed, AsciidocPubkit::SkillCommands::MANIFEST)
    original = JSON.parse(File.read(path))
    [nil, { 'schema_version' => 99 }, original.merge('files' => { '../outside' => '0' * 64, 'SKILL.md' => '0' * 64 })].each do |data|
      File.write(path, JSON.generate(data))
      before = inventory
      assert_equal 2, run_skill('status')[0]
      assert_equal 2, run_skill('upgrade')[0]
      assert_equal before, inventory
    end
    File.write(path, '{ broken json')
    assert_equal 2, run_skill('status')[0]
  end

  def test_version_only_upgrade_and_downgrade_protection
    install
    path = File.join(@installed, AsciidocPubkit::SkillCommands::MANIFEST)
    data = JSON.parse(File.read(path))
    data['tool_version'] = '1.0.0'
    File.write(path, JSON.generate(data))
    assert_equal 'update-available', report[1]['state']
    assert_equal 0, run_skill('upgrade')[0]
    assert_equal AsciidocPubkit::VERSION, report[1]['installed_version']
    data['tool_version'] = '999.0.0'
    File.write(path, JSON.generate(data))
    before = inventory
    assert_equal 'newer-installed', report[1]['state']
    assert_equal 2, run_skill('upgrade')[0]
    assert_equal before, inventory
  end

  def test_existing_lock_is_not_removed
    FileUtils.mkdir_p(@root)
    lock = File.join(@root, AsciidocPubkit::SkillCommands::LOCK)
    Dir.mkdir(lock)
    assert_equal 2, run_skill('install')[0]
    assert File.directory?(lock)
    refute File.exist?(@installed)
  end

  def test_corrupt_or_symlinked_bundle_is_not_installed
    source = File.join(@bundle, NAME, 'SKILL.md')
    original = File.read(source)
    File.write(source, "---\nname: wrong-name\ndescription: Test\n---\n")
    assert_equal 2, run_skill('install')[0]
    refute File.exist?(@root)
    File.write(source, original)
    File.symlink(source, File.join(@bundle, NAME, 'linked.md'))
    assert_equal 2, run_skill('install')[0]
    refute File.exist?(@root)
  end

  def test_copy_failure_keeps_existing_skill_and_cleans_staging
    install
    before = inventory
    File.open(File.join(@bundle, NAME, 'SKILL.md'), 'a') { |f| f.puts 'Updated.' }
    override(FileUtils, :copy_file, ->(*) { raise Errno::ENOSPC, 'Simulated full disk' }) do
      assert_equal 2, run_skill('upgrade')[0]
    end
    assert_equal before, inventory
    assert_empty Dir.glob(File.join(@root, '.asciidoc-pubkit-skill-*'))
    refute File.exist?(File.join(@root, AsciidocPubkit::SkillCommands::LOCK))
  end

  def test_failed_restore_preserves_and_reports_original_backup
    install
    before = inventory.transform_keys { |path| path.delete_prefix(@installed + '/') }
    File.open(File.join(@bundle, NAME, 'SKILL.md'), 'a') { |f| f.puts 'Updated.' }
    original_rename = File.method(:rename)
    failing = lambda do |from, to|
      raise Errno::EIO, 'Simulated failure' if %w[new old].include?(File.basename(from))
      original_rename.call(from, to)
    end
    result = override(File, :rename, failing) { run_skill('upgrade') }
    assert_equal 2, result[0]
    backup = Dir.glob(File.join(@root, '.asciidoc-pubkit-skill-*', 'old')).fetch(0)
    assert_includes result[2], backup
    before.each { |name, content| assert_equal content, File.binread(File.join(backup, name)) }
    refute File.exist?(File.join(@root, AsciidocPubkit::SkillCommands::LOCK))
  end

  def test_failed_upgrade_restores_original_and_cleans_staging
    install
    before = inventory
    File.open(File.join(@bundle, NAME, 'SKILL.md'), 'a') { |f| f.puts 'Updated.' }
    original_rename = File.method(:rename)
    failing = lambda do |from, to|
      raise Errno::EIO, 'Simulated replacement failure' if File.basename(from) == 'new'
      original_rename.call(from, to)
    end
    override(File, :rename, failing) { assert_equal 2, run_skill('upgrade')[0] }
    assert_equal before, inventory
    assert_equal 'update-available', report[1]['state']
    assert_empty Dir.glob(File.join(@root, '.asciidoc-pubkit-skill-*'))
    refute File.exist?(File.join(@root, AsciidocPubkit::SkillCommands::LOCK))
  end
end
