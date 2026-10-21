# Document-based image commands (v1.4.0)

All commands take an AsciiDoc entry document, such as `book.adoc`. They do not
accept a standalone image file or scan an arbitrary directory. They require Ruby
3.2 or later and ImageMagick 7 (`magick identify`) or 6 (`identify`) on PATH.
No Python, MeCab, AI, network fetch, or pixel modification is involved.

```sh
asciidoc-pubkit image list book.adoc
asciidoc-pubkit image list book.adoc --json
asciidoc-pubkit image stats book.adoc --json
asciidoc-pubkit image width book.adoc
asciidoc-pubkit image width book.adoc --diff
asciidoc-pubkit image width book.adoc --in-place
```

## Discovery and selection

Asciidoctor resolves active includes, attributes, conditional directives, and the
`imagesdir` value at each block image. Paths are relative to the document's base
directory, as in Asciidoctor, rather than each included file. Only parsed block
`image::` macros are collected. Inline `image:` macros, image text inside code or
comments, cover attributes without a block reference, and unreferenced files are
outside the v1.4.0 collection scope. An AsciiDoc table's separate inner documents
are not traversed in this version.

The default boundary is the entry document's directory. `--base-dir DIR` changes
both the parsing base and the permitted source/image boundary. Includes and
images outside it, including symlink escapes, are rejected. Direct symlink source
files are rejected. Image symlinks within the boundary are resolved and deduplicated.
Remote image references are reported as excluded without fetching; remote
includes and `allow-uri-read` are rejected. Missing or unsupported selected
images fail the command with exit 2 before source writes.

By default, block images whose basenames match `cover*`, `chapter-*`, `part-*`,
or `profile*`, and block references to `front-cover-image`, `back-cover-image`,
or `title-logo-image` assets, are excluded. `--include-artwork` disables these
built-in artwork exclusions; it does not collect assets that only appear in
attributes. Use `--exclude` for artwork with other names. Patterns match an image
basename or its path relative to the base directory. Repeat the flag for multiple
patterns. `--only FILE` selects references from one included source; it does not
mean one image, and the file must be part of the parsed document.

```sh
asciidoc-pubkit image list book.adoc --exclude 'special-*.png' --json
asciidoc-pubkit image width book.adoc --only chapters/intro.adoc --diff
asciidoc-pubkit image list book.adoc -a edition-en -a diagrams=1
```

## List and stats

`image list` reports each selected physical image once, in first-reference order:
absolute path, pixel width/height, full-precision width/height ratio, byte size,
and every reference's source file, line, target and current `scaledwidth`.
Text output rounds aspect ratios for display; JSON preserves the calculation
value. Source editability and exclusions are included in JSON.

`image stats` counts physical images and references separately. It reports the
sum of unique image bytes and minimum, maximum and arithmetic mean of width,
height, aspect ratio and bytes. Repeated references are not counted twice in
image statistics. With no selected images, totals are zero and min/max/mean are
null. Both commands are read-only; redirect stdout to save their reports.

## Width calculation and source edits

```text
raw width (%) = 100 × height-width-ratio × pixel width / pixel height
width (%) = clamp(raw width, min-width, max-width), rounded to one decimal
```

Rounding is clamped again so it never crosses a bound. A fractional bound may
therefore retain more than one decimal place. Defaults are coefficient 0.8,
minimum 40%, maximum 100%. A square uses 80%, a 3:4 image 60%, and width/height
>= 1.25 reaches 100%. Until a bound applies, the displayed image height approaches
0.8 times the text area's width. This is not a percentage of screen height.

| Option | Default | Behavior |
| --- | --- | --- |
| `--height-width-ratio NUMBER` | `0.8` | Display height / text-area width coefficient |
| `--min-width PERCENT` | `40` | Smallest permitted display width |
| `--max-width PERCENT` | `100` | Largest permitted display width |
| `--dry-run` | default behavior | Report planned changes without writing |
| `--diff` | off | Print a unified source diff without writing |
| `--in-place` | off | Explicitly update the source image references |
| `--json` | off | Structured inventory, settings and before/after changes |

Coefficients must be finite and positive, and widths must satisfy
`0 < min-width <= max-width <= 100`. `--in-place` cannot be combined with
`--dry-run` or `--diff`; `--diff` cannot be combined with `--json`.

```sh
asciidoc-pubkit image width book.adoc --height-width-ratio 0.7 \
  --min-width 50 --max-width 100 --exclude 'manual.png' --diff
```

The result is written to the physical source macro, including included files:

```adoc
image::diagram.png[Existing description,align=center,scaledwidth=87.9%]
```

Existing `scaledwidth` is updated; otherwise it is appended. Alt text, target
attribute references, other attributes, line endings, surrounding text and image
bytes are preserved. Explicit pixel width/height attributes are retained.
Backends that honor `scaledwidth`, including asciidoctor-epub3, consume it during
conversion; this does not impose a universal CSS width on every backend.

Source provenance is attached only in the parser's memory before include
lookahead can lose its location. No internal metadata is written to source.
Unsupported or unmapped source forms are not guessed: list/stats can report them,
but width refuses an unsafe edit. Duplicate `scaledwidth` declarations are rejected.
A reused source macro can be edited once when all references request the same
result; conflicting expansions or an excluded reuse block the edit. Separate
attributes or macros across multiple lines are not reconstructed.

All edits and image inspections complete before writing. Changed files are
staged in their own directories with their modes preserved. Source snapshots
are checked for concurrent changes. A failed multi-file replacement rolls back
already installed changes, without overwriting a later concurrent writer's edits.
Repeated execution with the same inputs is idempotent. There is no `--output`
or `--output-dir` mode in v1.4.0; a single output file cannot represent updates
across several included files. Use preview/diff to review changes first.

Image whitespace is included in the pixel dimensions. At the minimum width a
very tall figure can still exceed a page, and text may require a larger width.
The coefficient and bounds are tuning values, not KDP requirements. Run the
book build, EPUBCheck and Kindle Previewer after applying source changes.

Successful commands, previews and empty collections return 0. Invalid arguments,
parse errors, missing images and unsafe/unwritable source edits return 2. This
does not replace manuscript review verification or establish publication readiness.

## Make integration

Call width adjustment before the converter reads the source document:

```make
ASCIIDOC_PUBKIT ?= asciidoc-pubkit
IMAGE_HEIGHT_WIDTH_RATIO ?= 0.8
IMAGE_MIN_WIDTH ?= 40
IMAGE_MAX_WIDTH ?= 100
IMAGE_SELECTION_OPTS ?=
IMAGE_WIDTH_OPTS = --height-width-ratio $(IMAGE_HEIGHT_WIDTH_RATIO) --min-width $(IMAGE_MIN_WIDTH) --max-width $(IMAGE_MAX_WIDTH) $(IMAGE_SELECTION_OPTS)

.PHONY: image-list image-stats image-width
image-list:
	$(ASCIIDOC_PUBKIT) image list book.adoc $(IMAGE_SELECTION_OPTS)
image-stats:
	$(ASCIIDOC_PUBKIT) image stats book.adoc $(IMAGE_SELECTION_OPTS)
image-width:
	$(ASCIIDOC_PUBKIT) image width book.adoc $(IMAGE_WIDTH_OPTS) --in-place
```

Use your build's pre-generation prerequisite hook to run `image-width`. It must
finish before conversion, rather than running alongside the converter. No EPUB
postprocessing is needed. The earlier unreleased `epub image-width` prototype is
replaced by this document-based interface; it was not a released public command.

## Later scope

Image-file processing (`resize`, `trim`, `pad`, `quantize`, and possible composite
preparation) is planned for v1.4.1 and tracked in
[GitHub issue #1](https://github.com/cybergarage/asciidoc-pubkit/issues/1).
Those commands are not implemented in v1.4.0. Their input will also be the
AsciiDoc document, rather than a standalone image.
