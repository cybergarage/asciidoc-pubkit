# Changelog

## Unreleased

- Summarize review and scoring features at the start of the README architecture
  section, including AsciiDoc parsing, separate scopes, source-aligned static
  analysis, Japanese morphology, contextual prompts and baseline verification.

- Add separate `review scan --scope headings` sessions with packaged heading
  criteria and strict custom heading rules. Keep prose as the default and
  scoring scope; supply the full outline and read-only body evidence in one
  prompt without invoking an AI CLI. Accept mixed heading forms and leave
  section-role and body-agreement judgments to the reviewer.
- Permit mapped plain ATX section title edits in heading sessions while
  protecting body text, structure and section IDs. Report unsupported title
  mapping, retain stale-source and artifact checks, and require fresh sessions
  for schema 2. Generated section ID changes fail mechanical verification.
  Use separate default output directories for prose and heading sessions and
  protect physical titles reused by multiple includes.

- Introduce the review and scoring concepts before the architecture diagrams,
  with a table linking prose principles, implementation mechanisms, and their
  source files. Distinguish prompt guidance from mechanical guarantees.

## 0.6.2 — 2026-10-01

- Explain review and scoring architecture, flows, and algorithms in a separate
  README section with Mermaid diagrams. Add concrete applications for each
  editorial and research reference.

- Locate `repeated-ending` candidates at the matching ending in the third
  consecutive sentence, preserving Unicode columns and line offsets. Do not
  join repetitions across a sentence without a matching ending.
- Extend four configured metaphorical-operation phrases with MeCab/IPADIC
  predicate matching, including past, negative, and auxiliary forms. Retain
  polarity, custom-rule replacement, allow lists, protected text, and longest
  phrase precedence; literal mode keeps exact phrase matching.

## 0.6.1 — 2026-10-01

- Add `review score FILE` for direct AsciiDoc manuscript scoring without a
  session. Report a candidate-density indicator by default and optionally invoke
  a local Codex or Claude CLI for readability ratings with `--agent`. Preserve
  manuscript files, coverage limits, explicit tokenizer selection, and
  `meaning_verified: false`.
- Add a development-only prose benchmark with a fixed AsciiDoc corpus, scored
  candidate coverage and locations, and a saved MeCab baseline before detector
  changes. Keep quality judgments separate from detection performance.
- Add explicit local Codex/Claude rewrite and judge trials with fact checklists,
  blinded document labels, evaluator calibration, repeated-run statistics, and
  compatibility checks for baseline comparisons. Keep benchmark AI trials
  separate from manuscript scoring and the default test suite.

- Extend the shared Japanese prose criteria with evidence-based metaphor review,
  distinctions between instructions, behavior, and capabilities, and separate
  checks for information loss and unsupported additions.
- Add limited metaphorical-operation phrases as contextual review candidates,
  with a Japanese evaluation corpus for detection and manual meaning review.
- Introduce yomiyasu in the README references.

## 0.6.0 — 2026-09-30

Initial public release, including the earlier development work.

- Add `writing criteria` and `writing prompt` commands backed by one packaged
  Japanese technical prose guide. Include that guide in saved review prompts.
- Organize the CLI into `writing` and `review` groups and accept `--lang ja` on
  both. Reject unsupported languages explicitly, including document attributes.
- Save the shared criteria and language with each review session, and update the
  book writing and review skills to use the generated prompts.
- Refine Japanese review questions for redundant qualifications and generic
  recaps, and document the editorial sources and contextual limits.

- Consolidate Japanese review candidates for terminology, compressed noun
  relationships, operations, and negative qualifications in the packaged rules.
- Suppress literal candidates contained in longer matched terms, preserving
  allow-list handling, and recognize sahen potential forms before noun rules.
- Reduce single-file review prompts by emitting each paragraph once, sharing
  context metadata, and compacting JSON; retain all candidates and review settings.
- Confirm replacement of existing review sessions in interactive scans.
- Add `review scan --yes` (`-y`) and `--no-input` for batch execution.
- Preserve previous sessions until replacement scan artifacts are ready.

- Package default Japanese review rules as a validated UTF-8 YAML file.
- Support custom rule files through `review scan --rules` and `review.rules`.
- Save resolved rules in sessions for reproducible prompts and verification.
- Add concept, distinction, and negative meaning review candidates.
- Add a Make target for running a local checkout with arbitrary CLI arguments.

- Add contextual phrases, compound nouns, and potential and causative verb forms.
- Add requested abstract nouns, degree adjectives, and vague predicates.
- Use MeCab with UTF-8 IPADIC by default to match inflected predicates and adjectives.
- Preserve original surfaces, dictionary forms, and negative auxiliary information.
- Record analyzer and dictionary fingerprints in review sessions.
- Add an explicit literal mode for environments without MeCab.
- Reject incompatible dictionaries and unavailable analyzers with setup guidance.

- Add AsciiDoc running-prose extraction with checked source locations.
- Add Japanese review candidates and configurable terminology checks.
- Generate contextual English review instructions with Japanese source excerpts.
- Preserve review baselines and reject stale prompt inputs.
- Verify protected content, source membership, and document structure after edits.
- Package the CLI as a Ruby gem and add a test workflow.
