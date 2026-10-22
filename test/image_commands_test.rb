# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require 'stringio'
require 'zlib'
require 'asciidoc_pubkit'

class ImageCommandsTest < Minitest::Test
  def setup
    @dir = File.realpath(Dir.mktmpdir('pubkit images '))
    @book = File.join(@dir, 'book.adoc')
    FileUtils.mkdir_p(File.join(@dir, 'img'))
    image('wide.png', 200, 100)
    image('square.png', 100, 100)
    image('tall.png', 50, 100)
    File.write(@book, "= Book\n:imagesdir: img\n\nimage::wide.png[Wide]\n\nimage::square.png[Square]\n\nimage::tall.png[Tall]\n")
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  def image(name, w, h)
    chunk = lambda { |kind, data| [data.bytesize].pack('N') + kind + data + [Zlib.crc32(kind + data)].pack('N') }
    raw = "\x89PNG\r\n\x1a\n".b + chunk.call('IHDR', [w, h, 8, 2, 0, 0, 0].pack('NNCCCCC')) +
          chunk.call('IDAT', Zlib.deflate(("\0".b + "\xff".b * w * 3) * h)) + chunk.call('IEND', '')
    File.binwrite(File.join(@dir, 'img', name), raw)
  end

  def cli(command, *args)
    out, err = StringIO.new, StringIO.new
    code = AsciidocPubkit::CLI.run(['image', command, @book, *args], out: out, err: err)
    [code, out.string, err.string]
  end

  def json(command, *args)
    code, out, err = cli(command, *args, '--json')
    assert_equal 0, code, err
    assert_equal '', err
    JSON.parse(out)
  end

  def test_include_patterns_select_artwork_and_explicit_exclusions_win
    image('chapter-1.png', 50, 100)
    image('part-1.png', 50, 100)
    File.open(@book, 'a') { |f| f.puts "\nimage::chapter-1.png[]\n\nimage::part-1.png[]" }
    args = ['--include', 'chapter-*', '--include', 'img/part-*']
    assert_equal 2, json('list', *args)['image_count']
    assert_equal 2, json('stats', *args)['image_count']
    assert_equal 1, json('list', *args, '--exclude', 'part-*')['image_count']
    assert_equal 0, json('list', '--include', 'absent*')['image_count']
    result = json('scale', *args, '--width', '100', '--in-place')
    assert_equal [100.0, 100.0], result['images'].map { |i| i['width_percent'] }
    assert_equal 'fixed', result['settings']['mode']
    assert_includes File.read(@book), 'image::chapter-1.png[scaledwidth=100%]'
    assert_includes File.read(@book), 'image::part-1.png[scaledwidth=100%]'
    assert_includes File.read(@book), 'image::square.png[Square]'
    assert_empty json('scale', *args, '--width', '100')['changes']
  end

  def test_fixed_width_preserves_fraction_and_ignores_default_automatic_bounds
    result = json('scale', '--width', '25.25', '--in-place')
    assert_equal [25.25] * 3, result['images'].map { |i| i['width_percent'] }
    assert result['images'].none? { |i| i['minimum_limited'] }
    assert_includes File.read(@book), 'scaledwidth=25.25%'
  end

  def test_fixed_width_rejects_invalid_or_mixed_options_without_writes
    before = File.binread(@book)
    %w[0 -1 101 NaN Infinity].each { |n| assert_equal 2, cli('scale', '--width', n, '--in-place')[0] }
    %w[--height-width-ratio --min-width --max-width].each do |option|
      assert_equal 2, cli('scale', '--width', '80', option, '1', '--in-place')[0]
    end
    assert_equal before, File.binread(@book)
    assert_equal 2, cli('width')[0]
  end

  def test_minimum_width_notice_in_text_preview
    code, out, = cli('scale', '--min-width', '60')
    assert_equal 0, code
    assert_includes out, 'minimum width reached; height may exceed target'
    assert_equal 'automatic', json('scale')['settings']['mode']
  end

  def test_inventory_and_statistics_deduplicate_physical_images
    File.open(@book, 'a') { |f| f.puts "\nimage::square.png[Again]" }
    before = File.binread(@book)
    list = json('list')
    assert_equal 3, list['image_count']
    assert_equal 4, list['reference_count']
    assert_equal 2, list['images'][1]['references'].length
    assert_equal 2.0, list['images'][0]['aspect_ratio']
    assert_equal 4, list['images'][0]['references'][0]['line']
    stats = json('stats')
    assert_equal({ 'min' => 50, 'max' => 200, 'mean' => 350.0 / 3 }, stats['width'])
    assert_equal 3, stats['image_count']
    assert_equal Dir[File.join(@dir, 'img/*')].sum { |f| File.size(f) }, stats['total_bytes']
    assert_equal before, File.binread(@book)
  end

  def test_width_preview_apply_and_idempotency_preserve_images
    before = File.binread(@book)
    pixels = Dir[File.join(@dir, 'img/*')].to_h { |f| [f, File.binread(f)] }
    result = json('scale')
    assert_equal [100.0, 80.0, 40.0], result['images'].map { |i| i['width_percent'] }
    assert_equal 3, result['changes'].length
    refute result['applied']
    assert_equal before, File.binread(@book)
    result = json('scale', '--in-place')
    assert result['applied']
    assert_includes File.read(@book), 'image::square.png[Square,scaledwidth=80%]'
    assert_empty json('scale')['changes']
    pixels.each { |f, bytes| assert_equal bytes, File.binread(f) }
  end

  def test_includes_attributes_conditions_and_per_node_imagesdir
    FileUtils.mkdir_p(File.join(@dir, 'other'))
    FileUtils.cp(File.join(@dir, 'img/tall.png'), File.join(@dir, 'other/tall.png'))
    chapter = File.join(@dir, 'chapter.adoc')
    File.write(chapter, "image::{name}.png[First]\n\n:imagesdir: other\nimage::tall.png[Second]\n")
    File.write(@book, "= Book\n:imagesdir: img\n:name: wide\n\ninclude::chapter.adoc[]\n\nifdef::extra[]\nimage::missing.png[]\nendif::[]\n")
    result = json('list')
    assert_equal [File.join(@dir, 'img/wide.png'), File.join(@dir, 'other/tall.png')], result['images'].map { |i| i['path'] }
    assert_equal chapter, result['images'][0]['references'][0]['file']
    assert_equal 2, cli('list', '-a', 'extra')[0]
    result = json('scale', '--in-place')
    assert_equal [chapter], result['changed_files']
    assert_includes File.read(chapter), 'image::{name}.png[First,scaledwidth=100%]'
  end

  def test_artwork_and_remote_images_are_excluded_without_reading_them
    File.write(@book, "= Book\n:imagesdir: img\n:front-cover-image: image:custom-cover.png[]\n\n" +
               %w[chapter-1.png part-1.png profile-cg.png custom-cover.png cover.png].map { |n| "image::#{n}[]\n\n" }.join +
               "image::https://example.invalid/x.png[]\n\nimage::wide.png[Wide]\n\nText image:inline.png[Icon].\n")
    result = json('list')
    assert_equal 1, result['image_count']
    assert_equal 6, result['excluded'].length
    assert_equal 2, cli('list', '--include-artwork')[0] # Artwork files intentionally do not exist.
    json('scale', '--in-place')
    assert_includes File.read(@book), 'image::chapter-1.png[]'
    assert_includes File.read(@book), 'Text image:inline.png[Icon].'
  end

  def test_only_and_exclude
    chapter = File.join(@dir, 'chapter.adoc')
    File.write(chapter, "image::tall.png[Tall]\n")
    File.open(@book, 'a') { |f| f.puts "\ninclude::chapter.adoc[]" }
    result = json('scale', '--only', chapter, '--in-place')
    assert_equal 1, result['changes'].length
    refute_includes File.read(@book), 'scaledwidth='
    assert_equal 1, json('list', '--exclude', 'square*', '--exclude', 'img/tall.png')['image_count']
    File.write(File.join(@dir, 'unused.adoc'), '')
    assert_equal 2, cli('scale', '--only', File.join(@dir, 'unused.adoc'))[0]
  end

  def test_preserves_quoted_alt_commas_existing_sizes_and_crlf
    File.binwrite(@book, "= Book\r\n:imagesdir: img\r\n\r\nimage::square.png[\"図, A\",100,200, align=center, scaledwidth = \"65%\" ]\r\n")
    before = File.binread(@book)
    json('scale', '--in-place')
    assert_equal before.sub('"65%"', '"80%"'), File.binread(@book)
  end

  def test_unquoted_apostrophe_and_quoted_named_attributes
    File.write(@book, "= Book\n:imagesdir: img\n\nimage::square.png[O'Reilly example,title=\"First, second\",scaledwidth='50%']\n")
    before = File.read(@book)
    json('scale', '--in-place')
    assert_equal before.sub("scaledwidth='50%'", "scaledwidth='80%'"), File.read(@book)
  end

  def test_custom_coefficients_bounds_and_minimum_flag
    result = json('scale', '--height-width-ratio', '0.5', '--min-width', '30', '--max-width', '90')
    assert_equal [90.0, 50.0, 30.0], result['images'].map { |i| i['width_percent'] }
    assert result['images'].last['minimum_limited']
  end

  def test_diff_does_not_change_sources
    before = File.binread(@book)
    code, out, err = cli('scale', '--diff')
    assert_equal 0, code, err
    assert_includes out, '--- a/book.adoc'
    assert_includes out, '+image::square.png[Square,scaledwidth=80%]'
    assert_equal before, File.binread(@book)
  end

  def test_missing_or_invalid_images_fail_before_writes
    before = File.binread(@book)
    File.delete(File.join(@dir, 'img/tall.png'))
    assert_equal 2, cli('scale', '--in-place')[0]
    assert_equal before, File.binread(@book)
    File.write(File.join(@dir, 'img/tall.png'), 'invalid')
    assert_equal 2, cli('scale', '--in-place')[0]
    assert_equal before, File.binread(@book)
  end

  def test_shared_source_with_conflicting_expansions_is_not_edited
    template = File.join(@dir, 'template.adoc')
    File.write(template, "image::{name}.png[Template]\n")
    File.write(@book, "= Book\n:imagesdir: img\n:name: wide\n\ninclude::template.adoc[]\n\n:name: square\ninclude::template.adoc[]\n")
    before = File.binread(template)
    assert_equal 2, json('list')['image_count']
    assert_equal 2, cli('scale', '--in-place')[0]
    assert_equal before, File.binread(template)
  end

  def test_shared_source_with_equal_expansions_is_edited_once
    template = File.join(@dir, 'template.adoc')
    File.write(template, "image::square.png[Template]\n")
    File.write(@book, "= Book\n:imagesdir: img\n\ninclude::template.adoc[]\n\ninclude::template.adoc[]\n")
    result = json('scale', '--in-place')
    assert_equal 1, result['image_count']
    assert_equal 2, result['reference_count']
    assert_equal 1, result['changes'].length
  end

  def test_shared_source_with_excluded_expansion_is_not_edited
    template = File.join(@dir, 'template.adoc')
    File.write(template, "image::{name}.png[Template]\n")
    File.write(@book, "= Book\n:imagesdir: img\n:name: wide\n\ninclude::template.adoc[]\n\n:name: chapter-1\ninclude::template.adoc[]\n")
    assert_equal 2, cli('scale', '--in-place')[0]
    refute_includes File.read(template), 'scaledwidth='
  end

  def test_unsafe_includes_and_images
    outside = File.join(File.dirname(@dir), "outside-#{File.basename(@dir)}.adoc")
    File.write(outside, 'image::a.png[]')
    begin
      File.write(@book, "include::#{outside}[]\n")
      assert_equal 2, cli('list')[0]
    ensure
      File.unlink(outside)
    end
    File.write(@book, "image::https://example.invalid/a.png[]\n")
    assert_equal 2, cli('list', '-a', 'allow-uri-read')[0]
    File.write(@book, "image::../outside.png[]\n")
    assert_equal 2, cli('list')[0]
    File.symlink(File.join(@dir, 'img/square.png'), File.join(@dir, 'img/link.png'))
    File.write(@book, "= Book\n:imagesdir: img\n\nimage::square.png[]\n\nimage::link.png[]\n")
    assert_equal 1, json('list')['image_count']
  end

  def test_empty_collection_statistics
    File.write(@book, "= Book\n\nNo images.\n")
    result = json('stats')
    assert_equal 0, result['image_count']
    assert_equal 0, result['total_bytes']
    assert_equal({ 'min' => nil, 'max' => nil, 'mean' => nil }, result['width'])
  end

  def test_invalid_options_and_input_types
    before = File.binread(@book)
    [%w[--min-width 101], %w[--max-width 0], %w[--height-width-ratio NaN], %w[--in-place --dry-run],
     %w[--in-place --diff], %w[--diff --json]].each { |args| assert_equal 2, cli('scale', *args)[0], args.inspect }
    assert_equal 2, cli('list', '--in-place')[0]
    assert_equal 2, cli('resize')[0]
    out, err = StringIO.new, StringIO.new
    assert_equal 2, AsciidocPubkit::CLI.run(['image', 'scale', File.join(@dir, 'img/wide.png')], out: out, err: err)
    assert_equal before, File.binread(@book)
    %w[list stats scale].each { |cmd| assert_equal 0, cli(cmd, '--help')[0] }
  end

  def test_listing_blocks_are_not_selected_and_attribute_blocks_are_preserved
    File.write(@book, "= Book\n:imagesdir: img\n\n----\nimage::missing.png[Code]\n----\n\n[scaledwidth=50%,role=example]\nimage::square.png[Square]\n")
    result = json('scale', '--in-place')
    assert_equal 1, result['image_count']
    assert_includes File.read(@book), 'image::missing.png[Code]'
    assert_includes File.read(@book), '[scaledwidth=50%,role=example]'
    assert_equal '80%', json('list')['images'][0]['references'][0]['current_scaledwidth']
    refute_includes File.read(@book), 'pubkit-image-source-'
  end

  def test_tagged_include_and_fractional_bounds
    chapter = File.join(@dir, 'chapter.adoc')
    File.write(chapter, "// tag::figure[]\nimage::wide.png[Wide]\n// end::figure[]\n\nimage::missing.png[Not included]\n")
    File.write(@book, "= Book\n:imagesdir: img\n\ninclude::chapter.adoc[tag=figure]\n")
    result = json('scale', '--max-width', '99.95', '--in-place')
    assert_equal 2, result['changes'][0]['line']
    assert_includes File.read(chapter), 'scaledwidth=99.95%'
    assert_includes File.read(chapter), 'image::missing.png[Not included]'
  end

  def test_symlink_entry_is_rejected
    link = File.join(@dir, 'linked.adoc')
    File.symlink(@book, link)
    out, err = StringIO.new, StringIO.new
    code = AsciidocPubkit::CLI.run(['image', 'scale', link, '--in-place'], out: out, err: err)
    assert_equal 2, code
    assert_includes err.string, 'Symlinked source'
    refute_includes File.read(@book), 'scaledwidth='
  end

  def test_changed_source_context_blocks_apply
    options = { attributes: {}, exclude: [], ratio: 0.8, min: 40.0, max: 100.0, in_place: true }
    tool = AsciidocPubkit::ImageCommands.new(@book, options, StringIO.new)
    File.open(@book, 'a') { |f| f.puts 'A later author edit.' }
    saved = File.binread(@book)
    assert_raises(AsciidocPubkit::Error) { tool.scale }
    assert_equal saved, File.binread(@book)
  end

  def test_multiple_source_commit_rolls_back_on_rename_failure
    chapter = File.join(@dir, 'chapter.adoc')
    File.write(chapter, "image::tall.png[Tall]\n")
    File.open(@book, 'a') { |f| f.puts "\ninclude::chapter.adoc[]" }
    saved = [@book, chapter].to_h { |f| [f, File.binread(f)] }
    rename = File.method(:rename)
    fail_once = true
    replacement = lambda do |src, dst|
      if dst == chapter && fail_once
        fail_once = false
        raise Errno::EACCES, dst
      end
      rename.call(src, dst)
    end
    begin
      File.define_singleton_method(:rename, replacement)
      assert_equal 2, cli('scale', '--in-place')[0]
    ensure
      File.define_singleton_method(:rename, rename)
    end
    saved.each { |file, bytes| assert_equal bytes, File.binread(file) }
    assert_empty Dir[File.join(@dir, '.pubkit-image-*')]
  end
end
