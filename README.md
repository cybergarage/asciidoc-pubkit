![](https://img.shields.io/badge/status-Work%20In%20Progress-8A2BE2)
![GitHub tag (latest SemVer)](https://img.shields.io/github/v/tag/cybergarage/asciidoc-pubkit)
[![Gem Version](https://img.shields.io/gem/v/asciidoc-pubkit.svg)](https://rubygems.org/gems/asciidoc-pubkit)

# asciidoc-pubkit

A toolkit for authoring, reviewing, and publishing AsciiDoc books.

The initial release reviews Japanese running prose, generates contextual review
prompts for coding agents, and checks edited manuscripts against a saved baseline.
The CLI, diagnostics, documentation, and generated instructions are in English.
Japanese text is retained in manuscript excerpts, rule dictionaries, and fixtures.

## Status

This is an initial implementation. It does not invoke an AI service, automatically
rewrite manuscripts, or publish books. EPUB, image, and book scaffolding commands
are planned extensions, not available features.

Ruby 3.2 or later is required. Asciidoctor is installed as a gem dependency.
Starting with version 0.2.0, the default review backend requires the external MeCab
command and a UTF-8 IPADIC dictionary. Node.js and textlint are not required.
Explicit `--tokenizer literal` mode provides limited phrase matching without MeCab.

The current development version is 0.2.0. Until it is published, install from
source to use morphological analysis; RubyGems version 0.1.0 uses literal matching.

## Install from RubyGems

Install the CLI from [RubyGems](https://rubygems.org/gems/asciidoc-pubkit):

```sh
gem install asciidoc-pubkit
asciidoc-pubkit --version
asciidoc-pubkit --help
```

Ruby 3.2 or later is required. RubyGems installs the required Ruby dependencies;
no repository clone or Node.js installation is needed. MeCab and IPADIC must be
installed separately when using version 0.2.0 or later in the default mode.

Run the review workflow from your manuscript directory:

```sh
asciidoc-pubkit review scan book.adoc --output .pubkit/review
asciidoc-pubkit review prompt .pubkit/review --output review-prompt.md
# Ask your agent to review the prompt and edit the referenced manuscript.
asciidoc-pubkit review verify .pubkit/review --output verification.json
```

To update an existing installation:

```sh
gem update asciidoc-pubkit
```

### Use Bundler in a manuscript project

Add the gem to your project's `Gemfile` to manage its version with Bundler:

```ruby
source 'https://rubygems.org'
gem 'asciidoc-pubkit', '~> 0.1.0' # Published release; use 0.2.x after release
```

Then install dependencies and run the CLI through Bundler:

```sh
bundle install
bundle exec asciidoc-pubkit review scan book.adoc --output .pubkit/review
bundle exec asciidoc-pubkit review prompt .pubkit/review --output review-prompt.md
bundle exec asciidoc-pubkit review verify .pubkit/review --output verification.json
```

Commit `Gemfile` and `Gemfile.lock` in the manuscript project to keep the selected
version reproducible. Use `bundle update asciidoc-pubkit` to update it deliberately.

## Install from source

```sh
git clone https://github.com/cybergarage/asciidoc-pubkit.git
cd asciidoc-pubkit
bundle install
gem build asciidoc-pubkit.gemspec
gem install ./asciidoc-pubkit-0.2.0.gem
asciidoc-pubkit --version
```

The gem name and CLI name are `asciidoc-pubkit`; the Ruby require path is
`asciidoc_pubkit`, and the namespace is `AsciidocPubkit`.

For a small trial, use `examples/book.adoc` as the scan input. Its Japanese
paragraphs deliberately contain review candidates; its code block must remain
unchanged.

## Install the morphological analyzer (0.2.0 and later)

On macOS with Homebrew:

```sh
brew install mecab mecab-ipadic
mecab -D
```

On Ubuntu or Debian:

```sh
sudo apt-get update
sudo apt-get install mecab mecab-ipadic-utf8
mecab -D
```

Use a UTF-8 IPADIC dictionary. If the default dictionary is different, configure
`review.mecab_dictionary` with the IPADIC directory reported by your package
manager. UniDic and other feature layouts are rejected explicitly. MeCab and
IPADIC are separately installed dependencies, not bundled inside this gem.

The tool checks MeCab availability, dictionary encoding, and feature layout.
It never silently falls back to literal matching. To deliberately run without
morphological analysis:

```sh
asciidoc-pubkit review scan book.adoc --tokenizer literal --output .pubkit/literal-review
```

## Review workflow

Run the following commands from the manuscript project directory:

```sh
asciidoc-pubkit review scan book.adoc --output .pubkit/review
asciidoc-pubkit review prompt .pubkit/review --output review-prompt.md
# Ask your agent to read review-prompt.md and revise the referenced manuscript.
asciidoc-pubkit review verify .pubkit/review --output verification.json
```

All three commands leave manuscript files unchanged. Only the agent edits them.
Output paths must not already exist. Use a new session directory for a new pass.
Without `--output`, `prompt` writes Markdown and `verify` writes JSON to stdout.
`scan` defaults to `.pubkit/review` and prints a short summary.

### Scan

```sh
asciidoc-pubkit review scan book.adoc --only chapters/introduction.adoc
asciidoc-pubkit review scan chapter.adoc --style desu-masu
asciidoc-pubkit review scan book.adoc --attribute edition=print --base-dir .
```

An entrypoint or a standalone chapter can be scanned. Includes and conditionals
are processed by Asciidoctor. Match the publishing build's attributes and base
 directory to review the intended edition. `--only` selects one included source
file while retaining the book's attributes and heading hierarchy. Its path is
relative to the current working directory, as are other CLI path arguments.

Asciidoctor runs in safe mode. Local includes must resolve inside the base
directory. Remote includes and project-specific Asciidoctor extensions are not
supported. In particular, custom `/shared/` include conventions must be converted
to ordinary local paths before using this release. Parser diagnostics cause the
scan to fail rather than silently accepting incomplete input.

The session contains:

```text
.pubkit/review/
  manifest.json    # Schema, tool version, inputs, settings, hashes, protection data
  findings.json    # Candidate locations, rule IDs, severity, and review questions
  document.json    # Paragraphs, heading hierarchy, structure, and coverage notices
  baseline/       # Exact copies of the participating source files
```

Sessions use absolute source paths and are local working artifacts. Regenerate a
session after moving a project. Keep `.pubkit/` and generated prompts out of Git
when they contain private manuscript material. Rule settings and glossary contents
are frozen into the session; scan again after changing them.

### Prompt

```sh
asciidoc-pubkit review prompt .pubkit/review --mode revise --output review-prompt.md
asciidoc-pubkit review prompt .pubkit/review --mode diagnose
```

`revise` is the default and asks the agent to edit relevant prose. `diagnose` asks
for findings and proposed revisions without editing. Both modes require the agent
to distinguish **revise**, **keep**, and **needs-evidence** decisions.

The Markdown includes every selected paragraph, neighboring selected paragraphs,
heading context, candidates, saved settings, and preservation instructions. It
also asks for contextual review of paragraphs with no machine matches. Initial
support is for local prose correction, not chapter reorganization.

Source hashes are checked before generating a prompt. Modified sources, modified
session artifacts, and incompatible session versions require a fresh scan.

### Verify

```sh
asciidoc-pubkit review verify .pubkit/review
```

Verification compares the current source set, document structure, content outside
reviewed paragraphs, and recognized protected inline tokens with the baseline.
It reports remaining candidates and numeric changes separately. Existing candidates
do not make verification fail. Numeric changes require manual review but do not
by themselves fail mechanical verification.

Non-prose comparison ignores empty separator lines and trailing whitespace;
listing, literal, and passthrough block content is additionally compared as parsed
lines. Inline protection is heuristic, not a complete AsciiDoc inline parser.
Successful verification does not prove meaning preservation, technical accuracy,
or release readiness: `meaning_verified` is always `false`.

| Exit code | Meaning |
| --- | --- |
| `0` | Command completed; verification found no mechanical violations |
| `1` | Verification found protected-content, structure, source, or parsing issues |
| `2` | Invalid arguments, configuration, session, scan input, or output failure |

## Configuration

`scan` searches upward from the entrypoint directory for the nearest
`.asciidoc-pubkit.yml`. Use `--config FILE` to select a different file. CLI options
override configuration values; unspecified values use built-in defaults.
The initial release loads one configuration file, not merged book/repository files.

```yaml
review:
  language: ja
  style: desu-masu
  tokenizer: mecab
  # Optional overrides (dictionary paths are relative to this file):
  # mecab_command: /opt/homebrew/bin/mecab
  # mecab_dictionary: /opt/homebrew/lib/mecab/dic/ipadic
  base_dir: .
  glossary: glossary.yml
  exclude:
    - generated/**
  allows: []
  attributes:
    edition: print
```

Configuration paths are relative to the configuration file. Without configuration,
the base directory is the entrypoint's directory. Exclusion patterns match source
paths relative to the base directory; excluded files can still supply attributes
and are preserved by verification. The default style is `preserve`; explicit
alternatives are `desu-masu` and `dearu`. Only `ja` is currently supported.

A glossary maps canonical terms to variant strings:

```yaml
JavaScript:
  - Javascript
  - Java Script
```

Variants are review candidates, not automatic replacement instructions. In MeCab
mode, `allows` can suppress a canonical dictionary form (all its inflections) or
an exact matched surface (that occurrence's form only). In literal mode it
suppresses exact dictionary entries. It does not disable glossary checks.
Regex patterns are not interpreted in glossary or allow-list entries. Unknown
configuration keys are rejected. A bare `mecab_command` is resolved through PATH;
use an absolute path for an explicit executable override.

## Rules and coverage

| Rule | Severity | Purpose |
| --- | --- | --- |
| `abstract-reference` | hint | Ask what an abstract noun refers to |
| `weak-predicate` | hint | Ask whether an operation's purpose or result is clear |
| `generic-framing` | hint | Review generic introductions and emphasis |
| `vague-degree` | hint | Ask what depth, level, scope, or comparison is intended |
| `repeated-ending` | info | Identify three consecutive sentences with the same detected ending |
| `glossary-variant` | warning | Identify project-specific terminology variants |
| `style-candidate` | hint | Check selected polite/plain endings against an explicit style |

MeCab mode matches noun and adjective tokens and dictionary forms of verbs.
Sahen predicates are matched as a noun followed by the verb for "do"; standalone
sahen nouns are not treated as verbal predicates. Auxiliary sequences retain
negation, past tense, passive forms, and progressive forms in the reported surface.
The added reach predicate is negative-only; the existing handling predicate is
reviewed in both affirmative and negative forms. Glossary variants and generic
framing phrases continue to use literal matching.

Morphological candidates include `lemma`, `part_of_speech`, `negative`, and
`detector` alongside the original `match`, line, and column. Negation detection
covers common IPADIC negative auxiliaries; it is not full semantic analysis of
negation scope or double negatives. Unknown tokens are not guessed. Kana/kanji
variants of the alignment and gathering verbs have explicit canonical mappings;
other spelling variants are not automatically normalized.

The session records the MeCab version and dictionary file hashes. Verification
reports analyzer changes instead of treating results from different dictionaries
as directly comparable. Prompt generation uses saved evidence and does not need
MeCab. Changed rules or dictionary settings require a new scan.

Sessions from 0.1.0 are not compatible with 0.2.0. Keep the original baseline for
an ongoing review and finish it with the original version, or start a new review
pass in a different directory:

```sh
asciidoc-pubkit review scan book.adoc --output .pubkit/review-0.2.0
```

Severity describes review priority, not proof of an error. There is no AI-authorship
score and no requirement to eliminate every match.

Only source-mapped running-prose paragraphs are reviewed. Headings, list items and
their continuations, tables, quotations, code, and passthrough blocks are excluded
from prose review. Common inline literals, macros, attribute references, URLs, and
Japanese quotation spans are masked. Complex inline syntax can exceed the masking
heuristic; review its diagnostics with care.

Source locations are checked against original lines because Asciidoctor block
locations can be inaccurate at include boundaries. If a location cannot be matched
unambiguously, the paragraph is skipped with a coverage notice. Columns are
one-based Unicode character positions, not byte offsets or display widths.
An empty findings array does not establish full coverage or good prose.

## Development

```sh
bundle install
bundle exec rake test
bundle exec ruby -Ilib exe/asciidoc-pubkit --help
gem build asciidoc-pubkit.gemspec
```

The tests exercise include-boundary mapping, inline masking, configuration,
contextual prompts, stale inputs, protected-content verification, and real MeCab
analysis of inflections, negative predicates, Unicode positions, and long lines.
Install MeCab and UTF-8 IPADIC before running the complete test suite.
GitHub Actions is configured for Ruby 3.2, 3.3, 3.4, and 4.0 on Linux.

## License

Copyright 2026 CyberGarage.

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE).
