# Changelog

## Unreleased

## 0.1.3 — 2026-09-29

- Consolidate Japanese review candidates for terminology, compressed noun
  relationships, operations, and negative qualifications in the packaged rules.
- Suppress literal candidates contained in longer matched terms, preserving
  allow-list handling, and recognize sahen potential forms before noun rules.
- Reduce single-file review prompts by emitting each paragraph once, sharing
  context metadata, and compacting JSON; retain all candidates and review settings.
- Confirm replacement of existing review sessions in interactive scans.
- Add `review scan --yes` (`-y`) and `--no-input` for batch execution.
- Preserve previous sessions until replacement scan artifacts are ready.

## 0.1.2 — Released

- Package default Japanese review rules as a validated UTF-8 YAML file.
- Support custom rule files through `review scan --rules` and `review.rules`.
- Save resolved rules in sessions for reproducible prompts and verification.
- Add concept, distinction, and negative meaning review candidates.
- Add a Make target for running a local checkout with arbitrary CLI arguments.
- Require a new review session when upgrading from earlier tool versions.

## 0.1.1 — Released

- Add contextual phrases, compound nouns, and potential and causative verb forms.
- Add requested abstract nouns, degree adjectives, and vague predicates.
- Use MeCab with UTF-8 IPADIC by default to match inflected predicates and adjectives.
- Preserve original surfaces, dictionary forms, and negative auxiliary information.
- Record analyzer and dictionary fingerprints in review sessions.
- Add an explicit literal mode for environments without MeCab.
- Reject incompatible dictionaries and unavailable analyzers with setup guidance.
- Require a new review session when upgrading from 0.1.0.

## 0.1.0 — Released

- Add AsciiDoc running-prose extraction with checked source locations.
- Add Japanese review candidates and configurable terminology checks.
- Generate contextual English review instructions with Japanese source excerpts.
- Preserve review baselines and reject stale prompt inputs.
- Verify protected content, source membership, and document structure after edits.
- Package the CLI as a Ruby gem and add a test workflow.
