# frozen_string_literal: true

module AsciidocPubkit
  class CLI
    HELP = <<~TEXT
      Usage: asciidoc-pubkit <group> <command> [options] [input]

      Commands:
        document toc FILE      Print the parsed section outline
        document info FILE     Extract book metadata
        document check-xrefs FILE  Report unresolved local cross-references
        document index DIRECTORY  Generate an English-title AsciiDoc index
        writing criteria      Print the shared Japanese prose criteria
        writing prompt        Generate a Japanese technical writing prompt
        review scan FILE       Collect Japanese prose, headings, or list text and review candidates
        review score FILE      Score Japanese prose; optionally use a local AI CLI
        review prompt SESSION  Generate an English review prompt with Japanese source excerpts
        review verify SESSION  Compare edited sources with the saved baseline
        replace check FILE     Report prose-only replacement candidates
        replace diff FILE      Preview prose replacements as a unified diff
        replace apply FILE     Validate and apply explicit replacement rules

      Options:
        --help                 Show help (also supported for each command)
        --version              Show the version

      Use --lang ja with writing commands and review commands. Other review and
      writing languages are not supported yet and return an error.
      Only replace apply edits manuscripts. review score --agent explicitly invokes a
      local Codex or Claude CLI, which may connect to its configured AI service.
    TEXT

    def self.run(arguments, out: $stdout, err: $stderr, input: $stdin)
      args = arguments.dup
      if args == ['--version']
        out.puts VERSION
        return 0
      end
      if args.empty? || args == ['--help'] || args == ['-h'] || %w[review writing replace document].any? { |group| args == [group, '--help'] }
        out.puts HELP
        return 0
      end
      group, command = args.shift(2)
      if group == 'document' && %w[toc info check-xrefs index].include?(command)
        return DocumentCommands.run(command, args, out: out, err: err)
      end
      valid = (group == 'review' && %w[scan score prompt verify].include?(command)) ||
              (group == 'writing' && %w[criteria prompt].include?(command)) ||
              (group == 'replace' && %w[check diff apply].include?(command))
      raise Error, 'Unknown command. Use --help.' unless valid
      options = { attributes: {} }
      parser = OptionParser.new do |opts|
        input_name = group == 'writing' ? '' : ((group == 'replace' || %w[scan score].include?(command)) ? ' FILE' : ' SESSION')
        opts.banner = "Usage: asciidoc-pubkit #{group} #{command} [options]#{input_name}"
        opts.on('-o', '--output PATH', group == 'review' && command == 'scan' ? 'New session directory (default: .pubkit/review, .pubkit/headings, or .pubkit/lists)' : 'New output file (default: standard output)') { |v| options[:output] = v }
        opts.on('--lang LANG', 'Language (ja only in this release)') { |v| options[:language] = v }
        if group == 'replace'
          opts.on('--rules FILE', 'Required prh-format replacement rules (limited compatibility)') { |v| options[:rules] = v }
          opts.on('--base-dir DIR', 'Set the Asciidoctor base directory') { |v| options[:base_dir] = v }
          opts.on('--config FILE', 'Use review parsing configuration and exclusions') { |v| options[:config] = v }
          opts.on('--only FILE', 'Select one included file') { |v| options[:only] = v }
        elsif group == 'review' && %w[scan score].include?(command)
          if command == 'scan'
            opts.on('--scope SCOPE', 'prose (default), headings, or lists; separate review sessions') { |v| options[:scope] = v }
            opts.on('--heading-rules FILE', 'Replace default heading rules with a YAML rule set') { |v| options[:heading_rules] = v }
            opts.on('-y', '--yes', 'Answer yes to replacement confirmation') { options[:yes] = true }
            opts.on('--no-input', 'Never prompt; fail on existing output unless --yes') { options[:no_input] = true }
          else
            opts.on('--json', 'Print the complete score report as JSON') { options[:json] = true }
            opts.on('--agent NAME', 'Invoke local codex or claude for readability scoring') { |v| options[:agent] = v }
            opts.on('--model NAME', 'Local evaluator model (default: CLI default)') { |v| options[:model] = v }
            opts.on('--timeout SECONDS', Integer, 'Local evaluator timeout (default: 300)') { |v| options[:timeout] = v }
          end
          opts.on('--only FILE', 'Review one included file in the book context') { |v| options[:only] = v }
          opts.on('--config FILE', 'Use an explicit YAML configuration') { |v| options[:config] = v }
          opts.on('--rules FILE', 'Replace default review rules with a YAML rule set') { |v| options[:rules] = v }
          opts.on('--base-dir DIR', 'Set the Asciidoctor base directory') { |v| options[:base_dir] = v }
          opts.on('--tokenizer NAME', 'mecab (default) or literal (limited phrase matching)') { |v| options[:tokenizer] = v }
          opts.on('--style STYLE', 'preserve (default), desu-masu, or dearu') { |v| options[:style] = v }
          opts.on('-a', '--attribute NAME=VALUE', 'Set an Asciidoctor attribute; repeat as needed') do |v|
            key, value = v.split('=', 2)
            raise Error, 'Attribute name cannot be empty.' if key.nil? || key.empty?
            options[:attributes][key] = value || ''
          end
        elsif group == 'review' && command == 'prompt'
          opts.on('--mode MODE', 'revise (default) or diagnose') { |v| options[:mode] = v }
        end
        opts.on('-h', '--help', 'Show command help') { options[:help] = true }
      end
      parser.parse!(args)
      if options[:help]
        out.puts parser
        return 0
      end
      if group == 'writing'
        raise Error, 'Writing commands do not accept an input file. Use --help.' unless args.empty?
        language = Language.validate!(options.fetch(:language, Language::DEFAULT), operation: 'writing')
        content = command == 'criteria' ? Writing.criteria(language) : Writing.prompt(language)
        output(content, options[:output], out)
        return 0
      end
      raise Error, 'Exactly one input is required. Use --help.' unless args.length == 1
      Language.validate!(options[:language], operation: 'review') if options[:language]
      if group == 'replace'
        raise Error, 'replace apply does not accept --output.' if command == 'apply' && options[:output]
        replacement = Replacement.new(args.first, options)
        content = command == 'diff' ? replacement.diff : replacement.report
        replacement.apply if command == 'apply'
        content += "Applied #{replacement.candidates.length} replacements.\n" if command == 'apply'
        output(content, options[:output], out)
        return command == 'check' && !replacement.candidates.empty? ? 1 : 0
      end
      if command == 'score'
        if options[:output] && (File.exist?(options[:output]) || File.symlink?(options[:output]))
          raise Error, "Output already exists: #{options[:output]}"
        end
        report = Score.run(args.first, options)
        text = options[:json] ? JSON.pretty_generate(report) + "\n" : Score.format(report)
        output(text, options[:output], out)
        return 0
      end
      if command == 'scan'
        result = Session.scan(args.first, options) do |destination|
          if options[:yes]
            true
          elsif options[:no_input] || !input.tty?
            raise Error, "Output already exists: #{destination}. Use --yes to replace it or --output for a new session."
          else
            err.print "Output already exists: #{destination}. Replace it? [y/N] "
            err.flush
            answer = input.gets
            raise Error, 'Scan cancelled; existing session was kept.' unless answer && %w[y yes].include?(answer.strip.downcase)
            true
          end
        end
        if result['scope'] == 'headings'
          out.puts "Scanned #{result['headings']} headings; found #{result['findings']} review candidates."
        elsif result['scope'] == 'lists'
          out.puts "Scanned #{result['paragraphs']} list items; found #{result['findings']} review candidates."
        else
          out.puts "Scanned #{result['paragraphs']} paragraphs; found #{result['findings']} review candidates."
          out.puts "List text is excluded. Review it in a separate session with --scope lists."
        end
        out.puts "Tokenizer: #{result['tokenizer']}#{result['tokenizer'] == 'literal' ? ' (limited phrase matching; no morphological analysis)' : ' (UTF-8 IPADIC)'}"
        out.puts "Coverage notices: #{result['coverage_notices']}. See document.json for limitations."
        out.puts "Review session: #{result['session']}"
        return 0
      end
      session = Session.new(args.first)
      saved_language = Language.validate!(session.language, operation: 'review')
      if options[:language] && options[:language] != saved_language
        raise Error, "Requested language #{options[:language].inspect} does not match session language #{saved_language.inspect}."
      end
      if command == 'prompt'
        output(session.prompt(options.fetch(:mode, 'revise')), options[:output], out)
        return 0
      end
      result = session.verify
      output(JSON.pretty_generate(result) + "\n", options[:output], out)
      result['passed'] ? 0 : 1
    rescue Error, OptionParser::ParseError, SystemCallError, Psych::Exception, ArgumentError => e
      err.puts "Error: #{e.message}"
      2
    end

    def self.output(text, path, out)
      if path
        File.open(path, File::WRONLY | File::CREAT | File::EXCL, 0o644) { |file| file.write(text) }
        out.puts "Wrote #{File.expand_path(path)}"
      else
        out.write(text)
      end
    end
  end
end
