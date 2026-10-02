# Project guide

## Scope and sources of truth

This repository provides the `asciidoc-pubkit` Ruby gem and CLI. Its implemented
workflow emits Japanese writing prompts, scans Japanese AsciiDoc running prose,
reviews section headings in separate sessions, emits review prompts, scores
running prose, and verifies edited manuscripts
against a baseline. Only `review score --agent` invokes an installed Codex or
Claude CLI for optional readability evaluation; that CLI may call its configured
model provider. Explicit `replace apply` applies author-supplied mechanical rules to mapped prose;
review and scoring do not rewrite manuscripts. It does not publish books. Do not describe
planned publishing features as available functionality.

- [README.md](README.md) owns installation, command usage, configuration, rule
  schemas, coverage limits, and verification semantics. Update it when changing
  user-visible behavior rather than duplicating its full reference here.
- [CHANGELOG.md](CHANGELOG.md) records released and unreleased changes. Consult
  its Unreleased section and Git history when resuming work; a feature in the
  checkout is not necessarily present in the published gem.
- Keep CLI output, diagnostics, documentation, and generated instructions in
  English. Preserve Japanese manuscript excerpts, rule terms, and fixtures.
- Keep work within this repository unless the user requests manuscript or other
  project changes. No sibling checkout is required to develop or test the gem.

## Setup on another machine

Use Ruby 3.2 or later and Bundler. Install the external MeCab command and a UTF-8
IPADIC dictionary before running the full suite. See the README's morphological
analyzer installation section for macOS and Debian/Ubuntu commands. Confirm the
dictionary with `mecab -D`; UniDic is not an interchangeable backend.

From the repository root:

```sh
bundle install
bundle exec rake test
bundle exec ruby -Ilib exe/asciidoc-pubkit --help
```

`make run ARGS="--help"` runs the local checkout without installing this gem.
Use `make -f /path/to/asciidoc-pubkit/Makefile run ARGS="review scan book.adoc"`
from a manuscript directory to retain caller-relative paths. Do not use `make -C`
for that purpose. `RUBY` selects the executable; `ARGS` is trusted shell text and
needs shell quoting for paths containing spaces.

Git does not transfer ignored `Gemfile.lock`, `.bundle/`, `vendor/`, `pkg/`, root
gem archives, `.pubkit/`, or coverage output. Reinstall dependencies and rebuild
packages as needed; existing package filenames are not evidence of the current
source version. Review manuscript-owned configuration, glossary/rule files, and
MeCab executable/dictionary overrides separately when moving a manuscript.
Do not commit private review artifacts or machine-specific paths to this repo.

Review sessions contain absolute source paths. Preserve an ongoing baseline
before moving or replacing it, and start a fresh session at the new location.
A new scan establishes a new baseline; it cannot prove preservation relative to
the previous review. Prompt generation uses saved evidence without MeCab, while
verification of a MeCab session requires the analyzer and reports backend drift.

## Implementation map

| File | Responsibility |
| --- | --- |
| `exe/asciidoc-pubkit`, `lib/asciidoc_pubkit/cli.rb` | Entry point, arguments, confirmation, output, exit codes |
| `lib/asciidoc_pubkit/settings.rb` | Configuration discovery, path resolution, option precedence |
| `lib/asciidoc_pubkit/document.rb` | Asciidoctor parsing, source mapping, prose selection, structure |
| `lib/asciidoc_pubkit/morphology.rb` | MeCab execution, IPADIC validation, tokens, backend identity |
| `lib/asciidoc_pubkit/rules.rb` | Candidate detection, inline masking, positions and polarity |
| `lib/asciidoc_pubkit/heading_rules.rb`, `data/heading-rules.ja.yml`, `data/writing/ja/headings.md` | Separate heading candidates, book format preferences, and heading criteria |
| `lib/asciidoc_pubkit/rule_set.rb`, `data/review-rules.ja.yml` | Validated rule schema and packaged Japanese defaults |
| `lib/asciidoc_pubkit/language.rb`, `lib/asciidoc_pubkit/writing.rb`, `data/writing/ja/criteria.md` | Language gate and canonical writing criteria/prompt |
| `lib/asciidoc_pubkit/session.rb` | Baselines, artifact integrity, safe replacement, prompts, verification |
| `lib/asciidoc_pubkit/replacement.rb` | Limited prh-format rules, prose-only replacement plans, staged validation and explicit apply |
| `lib/asciidoc_pubkit/score.rb`, `lib/asciidoc_pubkit/local_evaluator.rb` | Manuscript scoring and explicit local CLI evaluation |
| `test/review_test.rb`, `test/morphology_test.rb` | Workflow regression tests and real MeCab tests |

## Contracts to preserve

- Scoring uses the same prose scope as default prose scanning. Keep candidate-density scores
  distinct from optional model readability ratings and benchmark accuracy.
  Invoke external model CLIs only with explicit `--agent`; no default test or
  other gem command may invoke them. Scoring never edits manuscripts or replaces
  existing output, and does not establish semantic correctness.
- Keep prose and heading scan scopes separate. Prose is the default; heading
  sessions use body text as read-only evidence. Only source-mapped plain ATX
  section title spans and opt-in exact saved old-ID anchors immediately before
  eligible titles are editable in heading sessions; retain structure and
  section IDs, including generated IDs. Separate list sessions edit only mapped
  single-line simple outline item text, preserving markers and inline syntax.
  Unsupported or reused source titles stay protected. Do not impose one heading form or length limit on every book.
- Findings are review candidates, not proven defects or automatic replacement
  instructions. Preserve negation, conditions, terminology, source text, and
  protected content. Columns are one-based Unicode character positions.
  Ambiguous source mappings must produce coverage notices instead of guesses.
- MeCab is the default. Never silently fall back to literal matching; require
  explicit `--tokenizer literal`. Literal-mode success does not validate MeCab.
- Rule precedence is `--rules`, then configuration `review.rules`, then packaged
  defaults. Custom rules replace the complete set. Keep YAML validation strict
  and save resolved rules in the session so later file edits do not change it.
- Preserve the single Markdown review-prompt workflow. Emit each selected
  paragraph once in document order, including paragraphs without candidates;
  share context and compact metadata without removing review evidence. Do not
  split required data into a separate file to reduce prompt size. Data fences
  must exceed any backtick run in their contents. Keep instructions for reading
  manageable ranges with neighboring context and tracking paragraph decisions.
- Sessions consist of `manifest.json`, `document.json`, `findings.json`, and
  `baseline/`. Retain integrity and stale-source checks. Replacing a session
  resets its baseline: only replace valid session directories, reject symlinks
  and destinations containing manuscript sources, stage the new artifacts first,
  and restore the old session if installation fails.
- Prompt for replacement only with terminal input. Only `y`/`yes` confirms;
  `--yes` authorizes replacement, `--no-input` rejects existing output without
  prompting, and both flags together replace without reading stdin. Batch jobs
  must never wait for an answer. `prompt` and `verify` must not overwrite output
  files or manuscripts.
- Verification checks mechanical preservation, not semantic or publication
  readiness. Keep `meaning_verified: false`. Remaining candidates and numeric
  changes alone do not fail verification; numeric changes need manual review.
  Preserve exit codes: 0 for success, 1 for verification violations, 2 for invalid
  arguments/configuration/session/input/output failures.
- `writing criteria` and `writing prompt` require no manuscript or analyzer.
  They and all review commands accept `--lang ja`; reject unsupported languages
  explicitly. Keep common criteria in the packaged language-specific file, not
  duplicated in book skills or rule questions. Save the criteria used by each
  review session and include them in its generated prompt.

## Validation and delivery

Run `bundle exec rake test` for code, rule, or generated-prompt changes. The suite
uses real MeCab/IPADIC; report missing dependencies instead of claiming complete
coverage from literal-mode checks. Add focused regression cases for changed
behavior. When asserting findings, select the intended rule rather than counting
unrelated informational candidates such as `repeated-ending`.

For packaging changes, also run `gem build asciidoc-pubkit.gemspec` and check that
the packaged rules and writing criteria are included. Keep the version in `lib/asciidoc_pubkit.rb` and
`asciidoc-pubkit.gemspec` consistent when a release is requested. CI configuration
is maintained in [.github/workflows/test.yml](.github/workflows/test.yml).

For documentation-only changes, check references and `git diff --check`; avoid
regenerating manuscript artifacts merely to validate documentation. Distinguish
tests executed from source inspection, package builds, and external integration
checks in reports. Preserve unrelated work, stage only the requested scope, and
use focused English commits. After committing, report the hash and worktree state.
