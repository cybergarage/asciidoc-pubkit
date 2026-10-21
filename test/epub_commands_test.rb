# frozen_string_literal: true

require 'minitest/autorun'
require 'stringio'
require 'open3'
require 'asciidoc_pubkit'

class EpubCommandsTest < Minitest::Test
  def cli(*args)
    out, err = StringIO.new, StringIO.new
    code = AsciidocPubkit::CLI.run(args, out: out, err: err)
    [code, out.string, err.string]
  end

  def test_help_and_dispatch
    code, out, err = cli('epub', 'image-width', '--help')
    assert_equal 0, code
    assert_includes out, '--height-width-ratio'
    assert_includes out, '--in-place'
    assert_includes out, '--output'
    assert_equal '', err
    assert_includes cli('--help')[1], 'epub image-width'
    assert_equal 2, cli('epub', 'unknown')[0]
    assert_equal 2, cli('epub', 'image-width', 'missing.epub')[0]
  end

  def test_packaged_helper_regressions
    out, err, status = Open3.capture3('python3', File.expand_path('epub_image_width_test.py', __dir__))
    assert status.success?, out + err
    assert_includes err, 'Ran 12 tests'
  end
end
