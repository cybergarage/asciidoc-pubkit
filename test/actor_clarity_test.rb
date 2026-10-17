# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require 'stringio'
require 'asciidoc_pubkit'

class ActorClarityTest < Minitest::Test
  def cli(*args)
    out = StringIO.new
    err = StringIO.new
    code = AsciidocPubkit::CLI.run(args, out: out, err: err)
    [code, out.string, err.string]
  end

  %w[mecab literal].each do |mode|
    define_method("test_candidate_free_actor_review_and_frozen_criteria_in_#{mode}") do
      Dir.mktmpdir('pubkit-actor-') do |dir|
        book = File.join(dir, 'book.adoc')
        session = File.join(dir, 'session')
        passage = 'モデルが変更を要求しても、許可されるまではファイルを変更しません。'
        source = "= Example\n\n== 操作\n\n#{passage}\n"
        File.write(book, source)
        code, _, error = cli('review', 'scan', book, '--tokenizer', mode,
                             '--output', session, '--no-input')
        assert_equal 0, code, error
        assert_empty JSON.parse(File.read(File.join(session, 'findings.json')))
        document = JSON.parse(File.read(File.join(session, 'document.json')))
        assert_equal [passage], document.fetch('paragraphs').map { |p| p.fetch('text') }
        manifest_path = File.join(session, 'manifest.json')
        manifest_bytes = File.binread(manifest_path)
        saved = JSON.parse(manifest_bytes.dup).fetch('writing_criteria')
        code, prompt, error = cli('review', 'prompt', session)
        assert_equal 0, code, error
        assert_includes prompt, saved
        assert_includes prompt, passage
        assert_equal source, File.read(book)
        # Criteria changes after scanning must not change the saved instructions.
        original = AsciidocPubkit::Writing.method(:criteria)
        begin
          AsciidocPubkit::Writing.define_singleton_method(:criteria) { |_language| 'Later criteria' }
          code, later, error = cli('review', 'prompt', session)
          assert_equal 0, code, error
          assert_equal prompt, later
        ensure
          AsciidocPubkit::Writing.define_singleton_method(:criteria, original)
        end
        assert_equal manifest_bytes, File.binread(manifest_path)
        # The verifier can preserve scope but cannot validate a newly named actor.
        %w[エージェント モデル].each do |actor|
          File.write(book, source.sub('許可されるまでは', "#{actor}は許可されるまでは"))
          code, report, error = cli('review', 'verify', session)
          assert_equal 0, code, error
          result = JSON.parse(report)
          assert result.fetch('passed')
          assert_equal false, result.fetch('meaning_verified')
        end
      end
    end
  end
end
