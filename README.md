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

Version 1.4.1 provides document-based image inspection and display sizing,
document inspection, explicit prose-only mechanical replacements, and Japanese
and English manuscript review. Inspect a book's outline,
metadata, and local cross-references; preview and apply your replacement rules;
then review and verify edits against a saved baseline.

Version 1.2.3 compares `分かれます` with classification, responsibility
sharing, branching and partitioning by context; see
[classification and related relationships](docs/writing.md#classification-and-related-relationships-v123).
These prompt criteria add no detector or automatic replacement rules.

Version 1.2.3 also compares `渡す` and `受け渡し` by their actual
operation; see [input, transmission, and handoff](docs/writing.md#input-transmission-and-handoff-v123).
These comparisons and skill routing do not automatically replace manuscript text.

Version 1.4.0 also compares explicit but vague actor names by their actual
responsibility; see [actor wording](docs/writing.md). This guidance adds no
detector or automatic replacement rules.

Version 1.4.1 provides document-based `image list`, `image stats`
and `image scale` (renamed from `image width`, without a compatibility alias). Use
`--include` to select images and `--width` for a fixed percentage; omit `--width`
for automatic aspect-ratio sizing. `--mode book` uses document-wide median
height/area budgets, with review reports for conflicting minimum widths. Collect images referenced by `book.adoc`, summarize their
pixel dimensions and file sizes, or explicitly update source `scaledwidth`
attributes from aspect ratios. Image pixels are unchanged. See
[image commands](docs/image-commands.md) for selection, tuning, ImageMagick
requirements, preservation rules and Make integration.

The CLI, diagnostics, documentation, and generated instructions are in English.
Japanese manuscript excerpts and rule terms retain their original text.

Version 1.2.3 also detects `行う` as an advisory operation-wording
cue. Compare direct actions with responsibilities rather than applying a fixed
replacement; see [general operation wording](docs/rules-and-coverage.md#general-operation-wording-v123).

Version 1.2.3 adds advisory `届く` candidates and operation-specific
arrival comparisons; see [arrival wording](docs/rules-and-coverage.md#arrival-wording-v123).
These hints do not automatically replace text or establish writing quality.

Version 1.2.3 also compares `定める` with `規定する`, `定義する`, and
`設定する` by the actual operation; see [rule wording](docs/writing.md#rules-definitions-and-configured-values).

Version 1.2.3 adds direct-negation comparisons and advisory variants
for `わけではありません`; see [direct negation](docs/writing.md#direct-negation-and-inference-limits-v123).
Existing sessions retain their saved rules and criteria. No automatic rewriting
is added.

Version 1.4.0 also adds contextual Japanese comparisons for
retention, input inclusion, representation and state indication; see
[retention and representation wording](docs/writing.md#retention-and-representation-wording-v140).
These criteria do not add automatic replacements or change scoring.
Version 1.4.0 also compares `示す` by explanatory role; see
[explanation, presentation and state indication](docs/writing.md#explanation-presentation-and-state-indication-v140).

Version 1.4.0 Japanese and English criteria also compare JSON examples with their
prose explanations while preserving each project's notation and edit scope;
see [JSON identifiers and explanatory strings](docs/writing.md#json-identifiers-and-explanatory-strings-v140).

## Available features

The following commands are available in version 1.4.1.

| Feature | Commands | Behavior |
| --- | --- | --- |
| [Document images](docs/image-commands.md) | `image list`, `image stats`, `image scale` | Inspect referenced block images; preview or explicitly apply source display widths |
| [Document outline](docs/document-commands.md#document-commands) | `document toc` | Print parsed section titles as text or JSON, including source locations, with optional depth and outline numbering |
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
| [Skill registration](docs/skill-commands.md) | `skill list`, `skill install`, `skill status`, `skill upgrade` | Register bundled skills for Codex or Claude and inspect or upgrade managed copies while protecting local changes |

Version 1.3.1: Japanese verification also shows selected text before/after edits
and advisory lexical change candidates. Save a report with `--output`, inspect
the changes, then use `--checked-report FILE` to detect subsequent source,
session or implementation changes. English behavior and scoring are unchanged.
See [Japanese verification records](docs/review-workflow.md#japanese-change-review-and-final-source-records-131).

The 1.2.0 [sentence-ending guidance](docs/writing.md#writing-commands)
adds contextual revision and keep examples, preserving capabilities, uncertainty,
comparison strength, and body sentences separately from heading form. It adds
no detector terms or automatic replacements. Version 1.2.1 includes 70
calibration pairs, without a measured claim of improved AI proofreading.

The v1.2.3 [communication-response criteria](data/writing/ja/criteria.md#distinguish-communication-responses-from-function-returns)
compare HTTP, ACP and MCP replies with internal return values and model generation.
Response fields, missing measurements and error handling remain distinct; no
blanket replacements or changes to mechanical verification are introduced.

Version 1.2.2 separates content guidance from actual checks and
learning objectives, honoring each author's explanatory voice. Development
calibration has 77 pairs, including valid exercises and runtime checks;
detector rules and mechanical verification are unchanged. See
[prose evaluation](docs/prose-evaluation.md) for validation limits.

The 1.2.0 [default rules](docs/rules-and-coverage.md) add `流れ` as an
`abstract-reference` hint for prose and list text. Review processing order,
information transfer and state changes in context; compare concrete alternatives and
prefer accurate technical terms without automatic substitutions. Existing sessions keep their saved
rules and criteria; start a new scan to use the update.

Version 1.2.0 also requires comparison with concrete alternatives for broad or
everyday wording. Review prompts reject automatic keep judgments and passage
summaries used as candidate decisions; missing comparisons remain pending.
Verification continues to check mechanical preservation only.

Version 1.2.1 [compares terminology independently of modality](data/writing/ja/criteria.md#compare-terminology-independently-of-modality), honors author terminology preferences, and adds advisory `組み込む` candidates. See [faithful terminology comparisons](docs/review-workflow.md#faithful-terminology-comparisons).

Version 1.0.1 extended the [shared writing criteria](docs/writing.md#writing-commands)
with structural comparison before and after revision and preservation of sentence
functions and plain or polite style. The [development evaluation](docs/prose-evaluation.md)
includes new cases for these checks.

Version 1.0.3 additionally preserves comparison axes, temporal roles,
and known actions in unclear passages, separating source uncertainty from editorial
questions. The evaluation guide describes the expanded corpus and calibration.

Version 1.1.0 adds contextual human-role guidance and standalone `人`
review hints, with terminology alignment and task-specific coverage reporting.
The checkout adds advisory `受け取る` candidates and
[receiving/returning comparisons](data/writing/ja/criteria.md#distinguish-receiving-returning-and-their-actual-operations)
(v1.2.3). Distinguish intake, reception, retrieval, arguments, generation,
stdout output, input assembly and exception handling; keep accurate value returns
and the original actor's responsibility.

These remain advisory; they do not automatically replace manuscript words or
expand the protected edit scopes. See the [review workflow](docs/review-workflow.md).

Version 1.1.0 also adds [outline review](docs/outline-review.md) with `document toc --json`,
`review scan --scope headings --depth N`, and `review prompt --view outline`.
Review subject coverage, heading granularity and terminology with saved body
evidence while protecting deeper titles, structure and section IDs. Full prompts
and unlimited heading selection remain the defaults.

Version 1.2.0 [skill commands](docs/skill-commands.md) add `skill list`,
`skill install NAME --agent codex|claude`, `skill status` and `skill upgrade`.
Use `--dir PATH` instead for a custom destination. Register a
bundled review skill, inspect its state and update unchanged copies from the
running pubkit package. Local changes and unmanaged copies stay protected.
These commands are included in the 1.2.0 gem.

## Requirements and scope

Ruby 3.2 or later is required; RubyGems installs Asciidoctor and the other Ruby
dependencies. Document inspection and replacement require neither MeCab nor an
AI CLI. Japanese review and scoring use external MeCab with UTF-8 IPADIC by
default. See [installation and analyzer setup](docs/installation.md).
Explicit `--tokenizer literal` offers limited phrase matching without MeCab.

Document commands accept any language. Version 1.3.0 adds
`--lang en` to writing and review, including scoring, headings and lists.
Replacement remains Japanese-only. See [English review](docs/english-review.md)
for boundaries, rules and score limits. Node.js and textlint are not required.

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
`gem 'asciidoc-pubkit', '~> 1.2.0'` to your project's `Gemfile` and run commands
through `bundle exec`. See [source installation and local checkout usage](docs/installation.md).

The checkout also adds `作用` as an advisory noun candidate. Compare its
actual operation, classification, result, or state change in context; see
[operation-effect cues](docs/rules-and-coverage.md#operation-effect-cues-v123).

## Quick start

Follow the [agent review tutorial](docs/agent-review-tutorial.md) for a complete
scan, prompt, Codex/Claude handoff, revision and verification walkthrough.
For a reusable agent workflow, see [skill integration](docs/skill-integration.md).


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
baselines and start a new review in a separate directory with v1.3.1. A new
scan cannot verify preservation relative to an earlier baseline.

## Documentation

| Guide | Contents |
| --- | --- |
| [Installation](docs/installation.md) | RubyGems, Bundler, source, local checkout, MeCab/IPADIC |
| [Document commands](docs/document-commands.md) | Outline, metadata, cross-references, English-title indexes |
| [Outline review](docs/outline-review.md) | JSON outline, heading-depth selection, whole-outline prompts and preservation |
| [Prose replacements](docs/replacements.md) | Rule format, imports, regex compatibility, preview/apply, preservation |
| [Skill commands](docs/skill-commands.md) | List/install/status/upgrade, managed files, local changes and recovery |
| [Skill integration](docs/skill-integration.md) | Register and maintain a skill, then orchestrate review in any book project |
| [Agent review tutorial](docs/agent-review-tutorial.md) | Illustrated first review, agent instructions, sequential scopes and verification recovery |
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
| [English review](docs/english-review.md) | English lexical matching, rules and preservation limits |
| [English evaluation](docs/english-evaluation.md) | Detection corpus, score baseline and editorial calibration |
| [English review research](docs/english-review-research.md) | Historical research and design decisions |

See [CHANGELOG.md](CHANGELOG.md) for release history.

## Contextual phase terminology (v1.2.3)

Japanese writing and new review prompts compare `段階` with `フェーズ` for
processing divisions, while preserving timing and progressive disclosure. See
[phase terminology guidance](docs/writing.md#processing-phases-timing-and-progressive-disclosure-v123).
This does not add detector rules or automatic replacement.

## Direct interpretation-limit wording (v1.2.3)

New scans flag `とはみなしません` and `とみなしません` for contextual comparison
with direct evidence-limit predicates. Preserve interpretation policies, missing
evidence and conditions; see [interpretation limits](docs/writing.md#direct-interpretation-limits-v123).
These hints do not automatically replace text or establish writing quality.

## License

Copyright 2026 CyberGarage.

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE).
