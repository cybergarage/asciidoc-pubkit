# EPUB figure widths (unreleased)

`asciidoc-pubkit epub image-width` calculates display widths for Asciidoctor EPUB
body figures from the dimensions of the embedded images. It does not edit
AsciiDoc manuscripts, image pixels, review sessions, or publication metadata.
This command is available in the development checkout, not released version 1.3.1.

The Ruby CLI invokes a packaged Python helper. Python 3 and ImageMagick 7
(`magick identify`) or ImageMagick 6 (`identify`) must be on PATH for this command.
They are not needed for other pubkit commands. No AI or network service is used.

## Preview and apply

The default is a preview; it does not write the input file.

```sh
asciidoc-pubkit epub image-width book.epub
asciidoc-pubkit epub image-width book.epub --dry-run --json
asciidoc-pubkit epub image-width book.epub --output preview.epub
asciidoc-pubkit epub image-width book.epub --in-place
```

`--output` writes a new EPUB and rejects an existing destination, including a
symlink. `--in-place` explicitly authorizes replacement of the input. These
options and `--dry-run` are mutually exclusive. Symlink inputs are rejected.
All image dimensions and document changes are prepared before writing. Failed
analysis leaves the input intact; replacement uses a temporary file in the
destination directory. Running again with identical settings makes no changes.

## Algorithm and options

```text
raw width (%) = 100 × height-width-ratio × pixel width / pixel height
width (%) = clamp(raw width, min-width, max-width), rounded to one decimal
```

Rounding never exceeds either bound. The defaults are coefficient 0.8, minimum
40%, and maximum 100%. A 1:1 image displays at 80%; 3:4 displays at 60%; and an
image with width/height >= 1.25 displays at 100%. This targets a display height
of 0.8 times the text area's width until a bound applies. It does not mean 80%
of the screen height, and does not guarantee a figure fits a page.

| Argument | Default | Effect |
| --- | --- | --- |
| `--height-width-ratio NUMBER` | `0.8` | Lower values reduce widths below the maximum; square images use 100 times this coefficient |
| `--min-width PERCENT` | `40` | Prevent excessive shrinkage of narrow images |
| `--max-width PERCENT` | `100` | Limit wide figures; use `90` to leave additional space |
| `--exclude GLOB` | none added | Exclude an image basename; repeat for multiple patterns |
| `--dry-run` | default mode | Calculate without writing |
| `--in-place` | off | Explicitly replace the input EPUB |
| `--output FILE`, `-o FILE` | none | Write a new EPUB without overwriting |
| `--json` | off | Report settings, per-image dimensions and widths, and changed-document count as JSON |

Coefficients must be finite and positive; widths must satisfy
`0 < min-width <= max-width <= 100`. The aspect ratio at which a figure reaches
the maximum is `max-width / (100 × coefficient)`. For example, coefficient
`0.6` and maximum `100` move that threshold to about `1.67`. There is no separate
landscape threshold or independently adjustable rounding mode in this version.

```sh
asciidoc-pubkit epub image-width book.epub --height-width-ratio 0.7 \
  --min-width 50 --max-width 100 --exclude 'special-diagram.png' --output preview.epub
```

The command processes only `img` elements inside `figure.image` in spine XHTML.
It excludes the OPF cover image and basenames matching `cover*`, `chapter-*`,
`part-*`, or `profile*`. Add `--exclude` for differently named title pages or
portraits. Inline images and navigation-only documents are not processed.

For selected images, it replaces width/height HTML attributes and width/height
CSS declarations with the calculated percentage width and `height: auto`.
Other attributes and styles are retained. Existing manual sizes are overwritten;
exclude any figure you want to size manually. Source image bytes, unrelated ZIP
entries, ZIP metadata, and excluded image tags are retained.

Image whitespace contributes to the measured dimensions. A very narrow figure
may still be too tall when constrained by the minimum; the report flags such
figures for review. The coefficient and bounds are tuning defaults, not KDP
requirements. KDP's [reflowable image guidelines](https://kdp.amazon.com/en_US/help/topic/G75V4YX5X8GRGXWV)
recommend at least 80% width for text-bearing diagrams and show 100% in a block
image example. They do not prescribe this formula or a 90% width. Check the
result with EPUBCheck and Kindle Previewer for the intended devices.

Errors return exit code 2. Preview and successful writes return 0. Neither
success nor a changed-document count establishes rendering or publication readiness.

## Make integration

Call this after the EPUB generator and any XHTML/typography postprocessing.
Make variables below are trusted command/options text; quote paths and globs.

```make
ASCIIDOC_PUBKIT ?= asciidoc-pubkit
EPUB_IMAGE_HEIGHT_WIDTH_RATIO ?= 0.8
EPUB_IMAGE_MIN_WIDTH ?= 40
EPUB_IMAGE_MAX_WIDTH ?= 100
EPUB_IMAGE_EXTRA_OPTS ?=
EPUB_IMAGE_WIDTH_OPTS = --height-width-ratio $(EPUB_IMAGE_HEIGHT_WIDTH_RATIO) --min-width $(EPUB_IMAGE_MIN_WIDTH) --max-width $(EPUB_IMAGE_MAX_WIDTH) $(EPUB_IMAGE_EXTRA_OPTS)

epub-image-width:
	$(ASCIIDOC_PUBKIT) epub image-width "$(EPUB)" $(EPUB_IMAGE_WIDTH_OPTS) --in-place
```

Until a release contains the command, select the checkout explicitly:

```sh
make epub-image-width \
  ASCIIDOC_PUBKIT='ruby -I /path/to/asciidoc-pubkit/lib /path/to/asciidoc-pubkit/exe/asciidoc-pubkit'
```

Use Ruby 3.2 or later. An installed 1.3.1 CLI does not provide this command.
