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

  def test_find_orientation_ratios_and_inclusive_bounds
    assert_equal ['tall.png'], json('find', '--portrait')['images'].map { |i| File.basename(i['path']) }
    assert_equal ['wide.png'], json('find', '--landscape')['images'].map { |i| File.basename(i['path']) }
    result = json('find', '--min-aspect-ratio', '0.5', '--max-aspect-ratio', '1')
    assert_equal %w[square.png tall.png], result['images'].map { |i| File.basename(i['path']) }
    assert_equal 3, result['selected_image_count']
    assert_equal 2, result['image_count']
    assert_equal 0, json('find', '--portrait', '--min-aspect-ratio', '1')['image_count']
    assert_equal 1, json('find', '--min-aspect-ratio', '0.50001', '--max-aspect-ratio', '1')['image_count']
  end

  def test_find_numeric_metrics_and_unit_parsing
    %w[pixels pixel-width pixel-height bytes].each do |metric|
      key = { 'pixel-width' => 'width', 'pixel-height' => 'height' }.fetch(metric, metric)
      json('find')['images'].each do |image|
        value = image.fetch(key)
        result = json('find', "--min-#{metric}", value.to_s, "--max-#{metric}", value.to_s)
        assert_includes result['images'].map { |i| i['path'] }, image['path']
        assert result['images'].all? { |i| i[key] == value }
      end
    end
    { 'B' => 1, 'KB' => 1000, 'MB' => 1000000, 'KiB' => 1024, 'MiB' => 1048576 }.each do |unit, multiplier|
      result = json('find', '--max-bytes', "2#{unit}")
      assert_equal 2 * multiplier, result['filters']['max-bytes']
      assert result['images'].all? { |i| i['bytes'] <= 2 * multiplier }
    end
    assert_equal 0, json('find', '--max-bytes', '0')['image_count']
    assert_equal 1, json('find', '--min-pixels', '10000', '--max-pixel-width', '100')['image_count']
    assert_equal 0, json('find', '--min-pixels', '999999999999999999999')['image_count']
  end

  def test_find_order_deduplication_locations_and_preservation
    File.open(@book, 'a') { |f| f.puts "\nimage::tall.png[Again]" }
    before = Dir[File.join(@dir, '**/*')].select { |f| File.file?(f) }.to_h { |f| [f, File.binread(f)] }
    result = json('find')
    assert_equal %w[wide.png square.png tall.png], result['images'].map { |i| File.basename(i['path']) }
    assert_equal 4, result['selected_reference_count']
    assert_equal 2, json('find', '--portrait')['reference_count']
    AsciidocPubkit::ImageCommands::FIND_METRICS.each do |metric, key|
      sorted = json('find', '--sort', metric)['images'].map { |i| i[key] }
      assert_equal sorted.sort.reverse, sorted
      ascending = json('find', '--sort', metric, '--order', 'asc')['images'].map { |i| i[key] }
      assert_equal ascending.sort, ascending
    end
    tied = json('find', '--sort', 'pixel-height')['images']
    assert_equal result['images'].map { |i| i['path'] }, tied.map { |i| i['path'] }
    code, out, err = cli('find', '--portrait')
    assert_equal 0, code, err
    assert_includes out, "#{@book}:8"
    assert_includes out, "#{@book}:10"
    assert_includes out, 'Matched images: 1 / 3; matched references: 2'
    before.each { |file, bytes| assert_equal bytes, File.binread(file) }
  end

  def test_find_selection_exclusions_and_inspection_failures
    image('chapter-1.png', 50, 100)
    File.open(@book, 'a') { |f| f.puts "\nimage::chapter-1.png[]\n\nimage::https://example.com/remote.png[]" }
    assert_equal 3, json('find')['selected_image_count']
    assert_equal 2, json('find', '--include-artwork', '--portrait')['image_count']
    assert_equal 1, json('find', '--include', 'chapter-*', '--portrait')['image_count']
    assert_equal 0, json('find', '--include', 'chapter-*', '--exclude', 'chapter-*')['image_count']
    result = json('find', '--include', 'absent*')
    assert_equal 0, result['selected_image_count']
    assert_empty result['images']
    assert_equal 5, result['excluded'].length
    chapter = File.join(@dir, 'chapter.adoc')
    File.write(chapter, "image::tall.png[]\n")
    File.open(@book, 'a') { |f| f.puts "\ninclude::chapter.adoc[]" }
    assert_equal 1, json('find', '--only', chapter)['reference_count']
    File.unlink(File.join(@dir, 'img/wide.png'))
    assert_equal 2, cli('find', '--portrait')[0]
    assert_equal 1, json('find', '--include', 'tall.png')['image_count']
    File.write(File.join(@dir, 'img/tall.png'), 'invalid image')
    assert_equal 2, cli('find', '--include', 'tall.png')[0]
  end

  def test_find_rejects_invalid_options
    bad = [%w[--portrait --landscape], %w[--sort unknown], %w[--sort bytes --order sideways],
           %w[--order asc], %w[--in-place], %w[--width 50]]
    %w[pixels pixel-width pixel-height aspect-ratio bytes].each do |metric|
      bad << ["--min-#{metric}", '2', "--max-#{metric}", '1']
      values = metric == 'bytes' ? %w[-1 1.5 1GB NaN Infinity] : %w[0 -1 NaN Infinity]
      values += %w[1.5 1px] unless metric == 'aspect-ratio'
      values.each do |value|
        %w[min max].each { |bound| bad << ["--#{bound}-#{metric}", value] }
      end
    end
    bad.each do |args|
      code, out, err = cli('find', *args)
      assert_equal 2, code, args.inspect
      assert_empty out
      refute_empty err
    end
    code, out, err = cli('find', '--help')
    assert_equal 0, code, err
    assert_includes out, '--landscape'
    assert_includes out, '--min-aspect-ratio'
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

  def test_book_mode_calibrates_unique_images_and_applies_idempotently
    File.open(@book, 'a') { |f| f.puts "\nimage::square.png[Again]" }
    before = File.binread(@book)
    pixels = Dir[File.join(@dir, 'img/*')].to_h { |f| [f, File.binread(f)] }
    result = json('scale', '--mode', 'book', '--min-width', '20')
    assert_equal 'book', result['settings']['mode']
    assert_equal 3, result['calibration']['image_count']
    assert_in_delta 0.8, result['calibration']['median_height'], 1e-10
    assert_in_delta 0.5, result['calibration']['median_area'], 1e-10
    assert_equal [89.4, 63.2, 36.0], result['images'].map { |i| i['width_percent'] }
    assert_empty result['conflicts']
    assert_equal before, File.binread(@book)
    result['images'].each do |i|
      assert_operator i['display_height'], :<=, result['calibration']['height_cap']
      assert_operator i['display_area'], :<=, result['calibration']['area_cap']
    end
    code, diff, = cli('scale', '--mode', 'book', '--min-width', '20', '--diff')
    assert_equal 0, code
    assert_includes diff, 'scaledwidth=63.2%'
    result = json('scale', '--mode', 'book', '--min-width', '20', '--in-place')
    assert result['applied']
    assert_empty json('scale', '--mode', 'book', '--min-width', '20')['changes']
    pixels.each { |f, bytes| assert_equal bytes, File.binread(f) }
  end

  def test_book_conflicts_are_reported_and_block_all_source_writes
    before = File.binread(@book)
    code, out, err = cli('scale', '--mode', 'book', '--json')
    assert_equal 0, code
    assert_includes err, 'require review'
    report = JSON.parse(out)
    assert_equal 1, report['conflicts'].length
    assert_equal 36.0, report['conflicts'][0]['proposed_width_percent']
    assert report['images'].last['requires_review']
    assert_equal 2, report['changes'].length
    assert_equal 2, cli('scale', '--mode', 'book', '--in-place')[0]
    assert_equal before, File.binread(@book)
    code, text, = cli('scale', '--mode', 'book')
    assert_equal 0, code
    assert_includes text, 'requires review; proposed width=36%'
  end

  def test_book_mode_even_medians_empty_set_and_selected_scope
    result = json('scale', '--mode', 'book', '--exclude', 'tall.png')
    assert_in_delta 0.65, result['calibration']['median_height'], 1e-10
    assert_in_delta 0.57, result['calibration']['median_area'], 1e-10
    empty = json('scale', '--mode', 'book', '--include', 'absent*', '--in-place')
    assert_nil empty['calibration']['median_height']
    assert_nil empty['calibration']['area_cap']
    assert_empty empty['changes']
    image('chapter-1.png', 50, 100)
    File.open(@book, 'a') { |f| f.puts "\nimage::chapter-1.png[]" }
    assert_equal 3, json('scale', '--mode', 'book', '--min-width', '20')['calibration']['image_count']
  end

  def test_book_factors_and_unsafe_combinations_are_validated
    before = File.binread(@book)
    bad = [%w[--mode invalid], %w[--mode book --width 100], %w[--area-factor 0.8],
           ['--mode', 'book', '--only', @book]]
    %w[--scale-factor --height-factor --area-factor].each do |flag|
      %w[0 -1 1.1 NaN Infinity].each { |value| bad << ['--mode', 'book', flag, value] }
    end
    bad.each { |args| assert_equal 2, cli('scale', *args, '--in-place')[0], args.inspect }
    assert_equal before, File.binread(@book)
    result = json('scale', '--mode', 'book', '--min-width', '10', '--scale-factor', '0.8',
                  '--height-factor', '0.75', '--area-factor', '0.6')
    assert_in_delta 0.6, result['calibration']['height_cap'], 1e-10
    assert_in_delta 0.3, result['calibration']['area_cap'], 1e-10
  end

  def test_book_mode_preserves_fractional_budget_caps_by_rounding_down
    result = json('scale', '--mode', 'book', '--min-width', '10', '--area-factor', '0.797')
    result['images'].each do |i|
      assert_operator i['display_area'], :<=, result['calibration']['area_cap']
      assert_operator i['width_percent'], :<=, i['baseline_width_percent'] * 0.9
    end
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
