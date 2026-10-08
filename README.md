![GitHub tag (latest SemVer)](https://img.shields.io/github/v/tag/cybergarage/asciidoc-pubkit)
[![Gem Version](https://img.shields.io/gem/v/asciidoc-pubkit.svg)](https://rubygems.org/gems/asciidoc-pubkit)
[![Build Status](https://github.com/cybergarage/asciidoc-pubkit/actions/workflows/test.yml/badge.svg)](https://github.com/cybergarage/asciidoc-pubkit/actions/workflows/test.yml)

# asciidoc-pubkit

A toolkit for authoring and reviewing AsciiDoc books.

This gem brings together practical lessons from the author's experience writing
and publishing books, along with a selection of the tools originally developed
for that work. Those projects include CyberGarage technical books in
[English](https://www.amazon.com/stores/CyberGarage/author/B0H8M3CPGH) and
[Japanese](https://www.amazon.co.jp/stores/CyberGarage/author/B0H8M3CPGH),
and books on health, exercise, and sports science published under
[WellBeing Lab](https://www.amazon.co.jp/stores/WellBeing-Lab/author/B0H7MB1HVD).
The experience informs the toolkit's writing criteria, contextual review prompts,
and checks for preserving manuscript content during revision.

Version 1.0.3 provides document inspection, explicit prose-only mechanical
replacements, and Japanese manuscript review. Inspect a book's outline,
metadata, and local cross-references; preview and apply your replacement rules;
then review and verify edits against a saved baseline.

The CLI, diagnostics, documentation, and generated instructions are in English.
Japanese manuscript excerpts and rule terms retain their original text.

## Available features

The following commands are available in version 1.0.3.

| Feature | Commands | Behavior |
| --- | --- | --- |
| [Document outline](docs/document-commands.md#document-commands) | `document toc` | Print parsed section titles, including book parts and chapters, with optional depth and outline numbering |
| [Book metadata](docs/document-commands.md#document-commands) | `document info` | Extract book attributes as text or JSON |
| [Cross-reference checks](docs/document-commands.md#document-commands) | `document check-xrefs` | Report unresolved local cross-references with source locations |
| [Document-title index](docs/document-commands.md#document-commands) | `document index` | Generate an alphabetical AsciiDoc index from English document titles and IDs |
| [Replacement preview](docs/replacements.md#prose-replacements) | `replace check`, `replace diff` | Report mechanical replacement candidates or preview a diff for mapped running prose; preserve source files |
| [Replacement application](docs/replacements.md#prose-replacements) | `replace apply` | Apply author-supplied rules after checking protected content and document structure; no MeCab or AI required |
| [Prose review](docs/review-workflow.md#review-workflow) | `review scan` | Collect mapped Japanese running prose and contextual review candidates with MeCab/IPADIC by default |
| [List review](docs/list-review.md#list-review) | `review scan --scope lists` | Review mapped single-line list text in a separate session |
| [Heading review](docs/review-workflow.md#heading-review) | `review scan --scope headings` | Collect editable section titles separately, retaining the outline and read-only body evidence |
| [Review prompts](docs/review-workflow.md#prompt) | `review prompt` | Generate one Markdown prompt from a saved session for review and editing by an external reviewer |
| [Baseline verification](docs/review-workflow.md#verify) | `review verify` | Check edited sources against a saved baseline for mechanical preservation; meaning is not verified |
| [Manuscript scoring](docs/scoring.md#score-an-asciidoc-manuscript) | `review score` | Report a prose candidate-density score; explicit `--agent codex` or `--agent claude` optionally invokes a local AI CLI for readability ratings |
| [Writing criteria and prompts](docs/writing.md#writing-commands) | `writing criteria`, `writing prompt` | Print Japanese prose criteria or generate a writing prompt without a manuscript or MeCab |

Version 1.0.1 extended the [shared writing criteria](docs/writing.md#writing-commands)
with structural comparison before and after revision and preservation of sentence
functions and plain or polite style. The [development evaluation](docs/prose-evaluation.md)
includes new cases for these checks.

Version 1.0.3 additionally preserves comparison axes, temporal roles,
and known actions in unclear passages, separating source uncertainty from editorial
questions. The evaluation guide describes the expanded corpus and calibration.

Unreleased changes add contextual human-role guidance and standalone `人`
review hints, with terminology alignment and task-specific coverage reporting.
These remain advisory; they do not automatically replace manuscript words or
expand the protected edit scopes. See the [review workflow](docs/review-workflow.md).

Unreleased [outline review](docs/outline-review.md) also adds `document toc --json`,
`review scan --scope headings --depth N`, and `review prompt --view outline`.
Review subject coverage, heading granularity and terminology with saved body
evidence while protecting deeper titles, structure and section IDs. Full prompts
and unlimited heading selection remain the defaults.

## Requirements and scope

Ruby 3.2 or later is required; RubyGems installs Asciidoctor and the other Ruby
dependencies. Document inspection and replacement require neither MeCab nor an
AI CLI. Japanese review and scoring use external MeCab with UTF-8 IPADIC by
default. See [installation and analyzer setup](docs/installation.md).
Explicit `--tokenizer literal` offers limited phrase matching without MeCab.

Document commands accept any language. Writing, replacement, and review support
`--lang ja` only. English review is a [research proposal](docs/english-review-research.md),
not an available feature. Node.js and textlint are not required.

Only `replace apply` edits manuscripts directly. Review prompts guide an external
human or agent; scan, prompt, verify, and scoring do not edit manuscripts.
Only explicit `review score --agent codex` or `--agent claude` invokes an
installed AI CLI, which may use its configured model provider.
Findings are review candidates; verification checks mechanical preservation and
keeps `meaning_verified: false`. The CLI does not publish books or provide EPUB,
image, or book scaffolding commands.
The packaged prose rules also flag broad operation and degree wording such as
`分かる`, `置く`, `変える`, `発火`, `短い`, `長い`, and `作れます` for contextual
review. Precise everyday language may remain; see the [review guide](docs/review-workflow.md).

## Install

```sh
gem install asciidoc-pubkit
asciidoc-pubkit --version
asciidoc-pubkit --help
```

To update, run `gem update asciidoc-pubkit`. For Bundler, add
`gem 'asciidoc-pubkit', '~> 1.0.3'` to your project's `Gemfile` and run commands
through `bundle exec`. See [source installation and local checkout usage](docs/installation.md).

## Quick start

Run these commands from the manuscript directory:

```sh
asciidoc-pubkit document toc book.adoc --depth 2 --numbered
asciidoc-pubkit document info book.adoc --json
asciidoc-pubkit document check-xrefs book.adoc
asciidoc-pubkit replace check book.adoc --rules replacements.yml
asciidoc-pubkit replace diff book.adoc --rules replacements.yml
asciidoc-pubkit replace apply book.adoc --rules replacements.yml
# Establish a review baseline after mechanical replacements.
asciidoc-pubkit review scan book.adoc --output .pubkit/review
asciidoc-pubkit review prompt .pubkit/review --output review-prompt.md
# Ask your reviewer to read the prompt and edit the referenced manuscript.
asciidoc-pubkit review verify .pubkit/review --output verification.json
```

Replacement requires author-supplied [replacement rules](docs/replacements.md);
review candidates are never applied as replacements. `replace check` exits 1
when candidates exist. Output files must be new.

Prose, headings, and lists use separate review sessions. For a complete review,
finish and verify headings first, then prose, then lists, creating each baseline
after the preceding phase. See the [review workflow](docs/review-workflow.md)
and [list review](docs/list-review.md) for supported spans and coverage limits.

To score prose or generate writing guidance:

```sh
asciidoc-pubkit review score book.adoc
asciidoc-pubkit writing criteria --lang ja
asciidoc-pubkit writing prompt --lang ja --output writing-prompt.md
```

Existing review sessions require the exact tool version that created them.
Before upgrading, finish ongoing reviews with that version or preserve their
baselines and start a new review in a separate directory with v1.0.3. A new
scan cannot verify preservation relative to an earlier baseline.

## Documentation

| Guide | Contents |
| --- | --- |
| [Installation](docs/installation.md) | RubyGems, Bundler, source, local checkout, MeCab/IPADIC |
| [Document commands](docs/document-commands.md) | Outline, metadata, cross-references, English-title indexes |
| [Outline review](docs/outline-review.md) | Unreleased JSON outline, heading-depth selection, whole-outline prompts and preservation |
| [Prose replacements](docs/replacements.md) | Rule format, imports, regex compatibility, preview/apply, preservation |
| [Review workflow](docs/review-workflow.md) | Scanning, heading review, prompts, sessions, verification, exit codes |
| [List review](docs/list-review.md) | Separate list sessions, editable items, protected syntax |
| [Scoring](docs/scoring.md) | Candidate density, optional AI readability ratings, output |
| [Writing](docs/writing.md) | Shared Japanese criteria and writing prompts |
| [Configuration](docs/configuration.md) | Discovery, precedence, paths, glossary, exclusions |
| [Rules and coverage](docs/rules-and-coverage.md) | Candidate detection, source positions, scope, session compatibility |
| [Custom review rules](docs/custom-rules.md) | Complete rule replacement, strict YAML schema, saved rules |
| [Architecture](docs/architecture.md) | Review principles, analysis pipeline, scoring algorithms |
| [Development](docs/development.md) | Setup, test suite, development validation |
| [Prose evaluation](docs/prose-evaluation.md) | Fixed fixtures, detector metrics, AI trials, before/after comparisons |
| [References](docs/references.md) | Editorial and research foundations |
| [English review proposal](docs/english-review-research.md) | Future design research; English review is not implemented |

See [CHANGELOG.md](CHANGELOG.md) for release history.

## License

Copyright 2026 CyberGarage.

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE).
