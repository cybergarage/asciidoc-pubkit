# frozen_string_literal: true

require 'open3'
require 'timeout'

module AsciidocPubkit
  class LocalEvaluator
    attr_reader :metadata

    def initialize(name, model: nil, timeout: 300)
      raise AsciidocPubkit::Error, 'Agent must be codex or claude.' unless %w[codex claude].include?(name)
      @name, @model, @timeout = name, model, timeout
      version, error, status = Open3.capture3(name, '--version')
      raise AsciidocPubkit::Error, "Cannot read #{name} version: #{error.strip}" unless status.success?
      @metadata = { 'agent' => name, 'cli_version' => version.strip, 'requested_model' => model,
                    'actual_model' => nil, 'timeout_seconds' => timeout }
    rescue Errno::ENOENT
      raise AsciidocPubkit::Error, "#{name} is not installed; run offline evaluation or install/authenticate that CLI."
    end

    def call(prompt, directory, stem)
      input = File.join(directory, "#{stem}-prompt.txt")
      output = File.join(directory, "#{stem}-stdout.txt")
      errors = File.join(directory, "#{stem}-stderr.txt")
      response = File.join(directory, "#{stem}-response.json")
      File.write(input, prompt)
      command = if @name == 'codex'
                  ['codex', 'exec', '--sandbox', 'read-only', '--ephemeral', '--skip-git-repo-check',
                   '--color', 'never', '--output-last-message', response, '-']
                else
                  ['claude', '--print', '--output-format', 'json', '--tools', '', '--strict-mcp-config',
                   '--mcp-config', '{"mcpServers":{}}', '--disable-slash-commands', '--no-session-persistence']
                end
      command += ['--model', @model] if @model
      pid = Process.spawn(*command, chdir: directory, in: input, out: output, err: errors, pgroup: true)
      begin
        _, status = Timeout.timeout(@timeout) { Process.wait2(pid) }
      rescue Timeout::Error
        Process.kill('TERM', -pid) rescue nil
        sleep 0.2
        Process.kill('KILL', -pid) rescue nil
        Process.wait(pid) rescue nil
        raise AsciidocPubkit::Error, "#{@name} evaluation timed out after #{@timeout} seconds."
      end
      raise AsciidocPubkit::Error, "#{@name} evaluation failed (exit #{status.exitstatus}); check CLI authentication and availability." unless status.success?
      raw = if @name == 'codex'
              record_model(File.read(errors)[/^model:\s*(\S+)/, 1])
              File.read(response)
            else
              envelope = JSON.parse(File.read(output))
              raise AsciidocPubkit::Error, 'Claude returned an error result.' if envelope['is_error']
              models = envelope.fetch('modelUsage', {}).keys
              record_model(models.one? ? models.first : nil)
              envelope.fetch('result')
            end
      # Accept a single fenced JSON response, never extract arbitrary fragments.
      raw = raw.strip.sub(/\A```(?:json)?\s*\n/, '').sub(/\n```\z/, '')
      result = JSON.parse(raw)
      raise AsciidocPubkit::Error, 'Agent response must be a JSON object.' unless result.is_a?(Hash)
      File.write(response, JSON.pretty_generate(result) + "\n")
      result
    end

    def record_model(model)
      if metadata['actual_model'] && model != metadata['actual_model']
        raise AsciidocPubkit::Error, 'Agent model changed during evaluation; start a separate run.'
      end
      metadata['actual_model'] = model
    end
  end

end
