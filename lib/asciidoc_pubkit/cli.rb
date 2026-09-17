# frozen_string_literal: true

module AsciidocPubkit
  class CLI
    HELP = <<~TEXT
      Usage: asciidoc-pubkit review <command> [options] <input>

      Commands:
        review scan FILE       Collect Japanese prose and review candidates
        review prompt SESSION  Generate an English review prompt with Japanese source excerpts
        review verify SESSION  Compare edited sources with the saved baseline

      Options:
        --help                 Show help (also supported for each command)
        --version              Show the version

      No command edits manuscript files or invokes an AI service.
    TEXT

    def self.run(arguments, out: $stdout, err: $stderr)
      args = arguments.dup
      if args == ['--version']
        out.puts VERSION
        return 0
      end
      if args.empty? || args == ['--help'] || args == ['-h'] || args == ['review', '--help']
        out.puts HELP
        return 0
      end
      group, command = args.shift(2)
      raise Error, 'Expected review scan, review prompt, or review verify. Use --help.' unless group == 'review' && %w[scan prompt verify].include?(command)
      options = { attributes: {} }
      parser = OptionParser.new do |opts|
        opts.banner = "Usage: asciidoc-pubkit review #{command} [options] #{command == 'scan' ? 'FILE' : 'SESSION'}"
        opts.on('-o', '--output PATH', command == 'scan' ? 'New session directory (default: .pubkit/review)' : 'New output file (default: standard output)') { |v| options[:output] = v }
        if command == 'scan'
          opts.on('--only FILE', 'Review one included file in the book context') { |v| options[:only] = v }
          opts.on('--config FILE', 'Use an explicit YAML configuration') { |v| options[:config] = v }
          opts.on('--base-dir DIR', 'Set the Asciidoctor base directory') { |v| options[:base_dir] = v }
          opts.on('--lang LANG', 'Prose language (ja only)') { |v| options[:language] = v }
          opts.on('--style STYLE', 'preserve (default), desu-masu, or dearu') { |v| options[:style] = v }
          opts.on('-a', '--attribute NAME=VALUE', 'Set an Asciidoctor attribute; repeat as needed') do |v|
            key, value = v.split('=', 2)
            raise Error, 'Attribute name cannot be empty.' if key.nil? || key.empty?
            options[:attributes][key] = value || ''
          end
        elsif command == 'prompt'
          opts.on('--mode MODE', 'revise (default) or diagnose') { |v| options[:mode] = v }
        end
        opts.on('-h', '--help', 'Show command help') { options[:help] = true }
      end
      parser.parse!(args)
      if options[:help]
        out.puts parser
        return 0
      end
      raise Error, 'Exactly one input is required. Use --help.' unless args.length == 1
      if command == 'scan'
        result = Session.scan(args.first, options)
        out.puts "Scanned #{result['paragraphs']} paragraphs; found #{result['findings']} review candidates."
        out.puts "Coverage notices: #{result['coverage_notices']}. See document.json for limitations."
        out.puts "Review session: #{result['session']}"
        return 0
      end
      session = Session.new(args.first)
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
