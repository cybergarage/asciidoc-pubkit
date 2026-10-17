# frozen_string_literal: true

module AsciidocPubkit
  # Advisory inventories avoid guessing paragraph matches after splits/merges.
  module JapaneseVerification
    MARKERS = {
      'negation' => /ません|ない|なく|ずに|禁止|不可/,
      'condition' => /場合|とき|なら|限り|だけ|のみ|以外|ただし|除く/,
      'certainty' => /かもしれません|かもしれない|可能性|おそれ|とされる|とみられる|必ず|保証/,
      'capability' => /できます|できません|できる|できない|可能|不可能/,
      'actor-topic' => /[\p{Han}\p{Katakana}A-Za-z][\p{Han}\p{Hiragana}\p{Katakana}A-Za-z]{0,29}(?:が|は)(?=[、\p{Han}\p{Hiragana}\p{Katakana}A-Za-z])/
    }.freeze

    def self.units(document, scope)
      scope == 'headings' ? document.fetch('headings') : document.fetch('paragraphs')
    end

    def self.inventory(entries, pattern)
      entries.flat_map { |entry| Rules.mask(entry.fetch('text')).scan(pattern) }.tally
    end

    def self.attach(result, document, baseline, manifest, directory)
      scope = manifest.fetch('settings').fetch('scope', 'prose')
      old_units = units(baseline, scope).group_by { |entry| entry.fetch('file') }
      new_units = units(document.to_h, scope).group_by { |entry| entry.fetch('file') }
      changes = (old_units.keys | new_units.keys).filter_map do |path|
        before = old_units.fetch(path, [])
        after = new_units.fetch(path, [])
        next if before.map { |e| e['text'] } == after.map { |e| e['text'] }

        candidates = MARKERS.filter_map do |kind, pattern|
          old_markers = inventory(before, pattern)
          new_markers = inventory(after, pattern)
          next if old_markers == new_markers
          { 'kind' => kind, 'before' => old_markers, 'after' => new_markers }
        end
        excerpt = ->(entries) { entries.map { |e| e.slice('line', 'end_line', 'text') } }
        { 'file' => path, 'before' => excerpt.call(before), 'after' => excerpt.call(after),
          'review_candidates' => candidates }
      end
      result['japanese_change_review'] = {
        'changes' => changes,
        'limitations' => 'File-level selected-text inventories, not aligned sentence pairs or semantic analysis. Actor/topic cues are lexical and do not identify grammatical roles. Inspect all changes even without candidates; unchanged counts can hide changes. Protected and excluded text is outside this comparison.'
      }
      implementation = (Dir[File.join(__dir__, '*.rb')] + [File.expand_path('../asciidoc_pubkit.rb', __dir__)]).sort.map { |path| [File.basename(path), Digest::SHA256.file(path).hexdigest] }
      result['verification_record'] = {
        'format' => 'pubkit-ja-verification-v1', 'tool_version' => VERSION,
        'implementation_sha256' => AsciidocPubkit.hash_text(JSON.generate(implementation)),
        'manifest_sha256' => Digest::SHA256.file(File.join(directory, 'manifest.json')).hexdigest,
        'sources' => document.sources.to_h { |path, content| [path, AsciidocPubkit.hash_text(content)] }
      }
      result
    end

    def self.read_report(path)
      report = JSON.parse(AsciidocPubkit.read_text(path))
      record = report.is_a?(Hash) && report['verification_record']
      valid = record.is_a?(Hash) && record['format'] == 'pubkit-ja-verification-v1' &&
              record['tool_version'].is_a?(String) &&
              %w[implementation_sha256 manifest_sha256].all? { |key| record[key].is_a?(String) && record[key].match?(/\A[0-9a-f]{64}\z/) } &&
              record['sources'].is_a?(Hash) && !record['sources'].empty? &&
              record['sources'].all? { |key, value| key.is_a?(String) && value.is_a?(String) && value.match?(/\A[0-9a-f]{64}\z/) } &&
              report['passed'] == true && report['meaning_verified'] == false && report['issues'] == []
      raise Error, 'Expected a successful Japanese verification report with a verification record.' unless valid
      record
    rescue JSON::ParserError => e
      raise Error, "Invalid checked report: #{e.message}"
    end
  end
end
