# frozen_string_literal: true

require 'find'
require 'tmpdir'
require 'rubygems/version'

module AsciidocPubkit
  # Manages only bundled skills at an explicitly chosen destination.
  class SkillCommands
    MANIFEST = '.asciidoc-pubkit-skill.json'
    LOCK = '.asciidoc-pubkit-skills.lock'

    def self.bundled_root
      File.expand_path('../../examples/skills', __dir__)
    end

    def self.run(command, args, out:, err:)
      raise Error, 'Unknown skill command. Use skill --help.' unless %w[list install status upgrade].include?(command)
      options = {}
      parser = OptionParser.new do |opts|
        opts.banner = "Usage: asciidoc-pubkit skill #{command}#{command == 'list' ? '' : ' NAME --dir PATH'} [options]"
        opts.on('--dir PATH', 'Explicit parent directory for installed skills') { |v| options[:dir] = v } unless command == 'list'
        opts.on('--json', 'Output structured skill information') { options[:json] = true } if %w[list status].include?(command)
        opts.on('-h', '--help', 'Show command help') { options[:help] = true }
      end
      parser.parse!(args)
      if options[:help]
        out.puts parser
        return 0
      end
      if command == 'list'
        raise Error, 'skill list does not accept a name or destination.' unless args.empty?
        skills = Dir.children(bundled_root).sort.select { |name| File.directory?(File.join(bundled_root, name)) }.map { |name| new(name).info }
        out.puts(options[:json] ? JSON.pretty_generate({ 'tool_version' => VERSION, 'skills' => skills }) : skills.map { |s| "#{s['name']}: #{s['description']}" }.join("\n"))
        return 0
      end
      raise Error, 'Provide one bundled skill name and --dir PATH.' unless args.length == 1 && options[:dir] && !options[:dir].empty?
      skill = new(args.first)
      root = File.expand_path(options[:dir])
      check_path(root)
      destination = File.join(root, skill.name)
      if command == 'status'
        report = skill.status(destination)
        out.puts(options[:json] ? JSON.pretty_generate(report) : format_status(report))
        return report['state'] == 'current' ? 0 : 1
      end
      if command == 'upgrade' && !%w[current update-available].include?(skill.status(destination)['state'])
        raise Error, "Cannot upgrade this skill. Use skill status to inspect it; existing content was kept."
      end
      FileUtils.mkdir_p(root)
      check_path(root)
      lock = File.join(root, LOCK)
      begin
        Dir.mkdir(lock, 0o700)
      rescue Errno::EEXIST
        raise Error, "Skill destination is locked: #{lock}. Another install or upgrade may be running."
      end
      begin
        result = skill.publish(destination, command)
      ensure
        Dir.rmdir(lock)
      end
      if result == :unchanged
        out.puts "Already current: #{destination}"
        return 0
      end
      out.puts "#{command == 'install' ? 'Installed' : 'Upgraded'} #{skill.name} from asciidoc-pubkit #{VERSION}: #{destination}"
      0
    rescue Error, OptionParser::ParseError, SystemCallError, JSON::ParserError, Psych::Exception, ArgumentError => e
      err.puts "Error: #{e.message}"
      2
    end

    def self.check_path(path)
      Pathname.new(path).ascend do |part|
        raise Error, "Symlink paths are not supported: #{part}" if File.symlink?(part)
        raise Error, "Expected a directory: #{part}" if File.exist?(part) && !File.directory?(part)
      end
    end

    def self.format_status(report)
      lines = ["Skill: #{report['name']}", "Destination: #{report['destination']}", "State: #{report['state']}",
               "Installed pubkit: #{report['installed_version'] || 'unknown'}", "Available pubkit: #{VERSION}"]
      %w[modified missing extra updated].each do |kind|
        report.fetch(kind, []).each { |file| lines << "#{kind.capitalize}: #{file}" }
      end
      lines.join("\n")
    end

    attr_reader :name

    def initialize(name)
      raise Error, 'Invalid skill name.' unless name.match?(/\A[a-z0-9]+(?:-[a-z0-9]+)*\z/) && name.length <= 64
      @name = name
      @source = File.join(self.class.bundled_root, name)
      raise Error, "Unknown bundled skill: #{name}. Use skill list." unless File.directory?(@source)
      self.class.check_path(@source)
      @files = snapshot(@source)
      raise Error, 'Bundled skill contains reserved registration metadata.' if @files.key?(MANIFEST)
      text = AsciidocPubkit.read_text(File.join(@source, 'SKILL.md'))
      frontmatter = text.match(/\A---\n(.*?)\n---(?:\n|\z)/m)
      metadata = frontmatter && YAML.safe_load(frontmatter[1], permitted_classes: [], aliases: false)
      unless metadata.is_a?(Hash) && metadata['name'] == name && metadata['description'].is_a?(String) && !metadata['description'].strip.empty?
        raise Error, "Invalid bundled SKILL.md: #{name}"
      end
      @description = metadata['description']
    end

    def info
      { 'name' => name, 'description' => @description, 'tool_version' => VERSION, 'files' => @files.keys.sort }
    end

    def snapshot(root)
      files = {}
      Find.find(root) do |path|
        raise Error, "Symlink skill content is not supported: #{path}" if File.symlink?(path)
        next if File.directory?(path)
        raise Error, "Unsupported skill file: #{path}" unless File.file?(path)
        relative = Pathname.new(path).relative_path_from(Pathname.new(root)).to_s
        files[relative] = Digest::SHA256.file(path).hexdigest
      end
      files
    end

    def registration(destination)
      path = File.join(destination, MANIFEST)
      raise Error, "Symlink registration is not supported: #{path}" if File.symlink?(path)
      return nil unless File.exist?(path)
      raise Error, "Expected a registration file: #{path}" unless File.file?(path)
      data = JSON.parse(AsciidocPubkit.read_text(path))
      valid = data.is_a?(Hash) && data.keys.sort == %w[files name schema_version tool tool_version] &&
              data['schema_version'] == 1 && data['tool'] == 'asciidoc-pubkit' && data['name'] == name &&
              data['tool_version'].is_a?(String) && !data['tool_version'].empty? && Gem::Version.correct?(data['tool_version']) &&
              data['files'].is_a?(Hash) && data['files'].key?('SKILL.md') && !data['files'].key?(MANIFEST)
      valid &&= data['files'].all? do |file, sha|
        file.is_a?(String) && !file.empty? && !file.start_with?('/') && !file.include?('\\') &&
          file.split('/', -1).none? { |part| ['', '.', '..'].include?(part) || part.include?("\0") } &&
          sha.is_a?(String) && sha.match?(/\A[0-9a-f]{64}\z/)
      end
      raise Error, "Invalid skill registration: #{path}" unless valid
      data
    end

    def status(destination)
      self.class.check_path(destination)
      report = { 'name' => name, 'destination' => destination, 'available_version' => VERSION,
                 'installed_version' => nil, 'state' => 'not-installed', 'modified' => [], 'missing' => [], 'extra' => [], 'updated' => [] }
      return report unless File.directory?(destination)
      data = registration(destination)
      return report.merge('state' => 'unmanaged') unless data
      actual = snapshot(destination).reject { |file, _| file == MANIFEST }
      expected = data['files']
      report['installed_version'] = data['tool_version']
      report['modified'] = (expected.keys & actual.keys).select { |file| expected[file] != actual[file] }.sort
      report['missing'] = (expected.keys - actual.keys).sort
      report['extra'] = (actual.keys - expected.keys).sort
      # Even empty additional directories are user-owned content.
      permitted_dirs = expected.keys.flat_map do |file|
        parts = file.split('/')[0...-1]
        (1..parts.length).map { |length| parts.first(length).join('/') }
      end
      Find.find(destination) do |path|
        next unless File.directory?(path) && path != destination
        relative = Pathname.new(path).relative_path_from(Pathname.new(destination)).to_s
        report['extra'] << relative + '/' unless permitted_dirs.include?(relative)
      end
      report['extra'].sort!
      report['updated'] = (expected.keys | @files.keys).select { |file| expected[file] != @files[file] }.sort
      report['state'] = if %w[modified missing extra].any? { |kind| !report[kind].empty? }
                          'modified'
                        elsif Gem::Version.new(data['tool_version']) > Gem::Version.new(VERSION)
                          'newer-installed'
                        elsif data['tool_version'] != VERSION || !report['updated'].empty?
                          'update-available'
                        else
                          'current'
                        end
      report
    end

    def publish(destination, command)
      self.class.check_path(destination)
      if command == 'install'
        raise Error, "Skill destination already exists: #{destination}. Use skill status or choose a different directory." if File.exist?(destination)
      else
        report = status(destination)
        unless %w[current update-available].include?(report['state'])
          raise Error, "Cannot upgrade #{report['state']} skill: #{destination}. Use skill status to inspect it; existing content was kept."
        end
        return :unchanged if report['state'] == 'current'
      end
      workspace = Dir.mktmpdir('.asciidoc-pubkit-skill-', File.dirname(destination))
      staged = File.join(workspace, 'new')
      backup = File.join(workspace, 'old')
      preserve_backup = false
      begin
        Dir.mkdir(staged)
        @files.each do |file, sha|
          source = File.join(@source, file)
          raise Error, 'Bundled skill changed while staging.' unless Digest::SHA256.file(source).hexdigest == sha
          target = File.join(staged, file)
          FileUtils.mkdir_p(File.dirname(target))
          FileUtils.copy_file(source, target)
          File.chmod(File.stat(source).mode & 0o777, target)
          raise Error, 'Bundled skill changed while copying.' unless Digest::SHA256.file(target).hexdigest == sha
        end
        File.write(File.join(staged, MANIFEST), JSON.pretty_generate({ 'schema_version' => 1, 'tool' => 'asciidoc-pubkit',
                                                                    'name' => name, 'tool_version' => VERSION, 'files' => @files }) + "\n")
        self.class.check_path(destination)
        if command == 'upgrade'
          raise Error, 'Installed skill changed while staging.' unless status(destination) == report
          File.rename(destination, backup)
        elsif File.exist?(destination)
          raise Error, "Skill destination already exists: #{destination}"
        end
        begin
          File.rename(staged, destination)
        rescue SystemCallError
          if File.directory?(backup)
            preserve_backup = true
            begin
              File.rename(backup, destination)
              preserve_backup = false
            rescue SystemCallError => restore_error
              raise Error, "Could not restore the skill. Original content is preserved at #{backup}: #{restore_error.message}"
            end
          end
          raise
        end
      ensure
        FileUtils.remove_entry_secure(workspace) unless preserve_backup
      end
      :updated
    end
  end
end
