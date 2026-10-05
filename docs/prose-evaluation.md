# Prose evaluation

Use a fixed set of Japanese technical paragraphs to compare detector or review
criteria changes against a project-defined baseline. Keep detection performance,
readability, and meaning preservation separate so that a clearer rewrite cannot
hide a lost condition or invented fact.

This guide describes version 1.0.2, including the
`technical-prose-v2` corpus and expanded revision calibration. The evaluation runner is not an
installed gem command. It does not measure Japanese naturalness or AI authorship
as a single validated score.

## Three different evaluations

| Evaluation | Input and method | What the number means |
| --- | --- | --- |
| `review score` without `--agent` | A manuscript; candidate count normalized by unmasked prose length | Candidate-density indicator, not correctness or naturalness |
| `script/evaluate-prose` without `--agent` | Fixed corpus and annotated targets; deterministic analysis | Detector precision, recall, F1, and location accuracy |
| `script/evaluate-prose --agent codex` or `--agent claude` | Fixed corpus; generated review prompt, rewrite, and separate judge invocation | Readability and checklist preservation before and after rewriting |

The default manuscript score is `max(0, 100 - 5 × candidates per 1,000 characters)`.
A higher score means fewer detected candidates at that text length. Necessary
repetition can still be a candidate, and fewer candidates alone do not establish
better prose. See [Manuscript scoring](scoring.md) for the separate optional
single-manuscript readability rating; that path has no original-versus-revision
fact checklist.

For a detector change, use the deterministic benchmark. For a writing or review
criteria change, use the optional rewrite-and-judge trials to measure its effect
on the actual revisions. Criteria can change while deterministic detector scores
remain identical.

## Fixed test data

All examples are original project-authored editorial fixtures. They intentionally
include patterns associated with generated prose, plus valid technical controls.
They are not a collected dataset of known AI outputs or a representative sample
of Japanese writing.

| File | Contents and role |
| --- | --- |
| [prose_benchmark.ja.adoc](../test/fixtures/prose_benchmark.ja.adoc) | 21 paragraphs used as the actual AsciiDoc input |
| [prose_benchmark.ja.json](../test/fixtures/prose_benchmark.ja.json) | Matching paragraph IDs and text, 11 annotated detector targets, and preservation checklists |
| [prose_benchmark.yml](../test/fixtures/prose_benchmark.yml) | Fixed empty configuration that isolates the benchmark from discovered manuscript settings |
| [prose_evaluation.ja.json](../test/fixtures/prose_evaluation.ja.json) | Detection examples and 31 manual revision pairs with expected `accept`, `reject`, or `needs-evidence` dispositions |

The corpus includes framing such as `重要なのは`, metaphorical operations such
as `地味に効く`, inflected and negative forms, and repeated endings. Controls
include literal verbs, established technical terms, necessary repetition,
concurrency requirements, and protected inline code.

Eight paragraphs added in `technical-prose-v2` cover quantity targets, required
order, modifier targets, condition scope, parallel checks, advice versus actual
behavior, plain style, and punctuation and purpose scope. They have no additional
detector targets but still reach the reviewer and judge. The checklists include
explicit editorial constraints as well as technical facts.

For example, this pair must be rejected even though its numeral is unchanged:

| Original | Revision | Preservation issue |
| --- | --- | --- |
| 各ワーカーは最大3回再試行します。 | 全ワーカーで合計3回まで再試行します。 | A per-worker limit became an aggregate limit |

Other revision pairs cover reversed recovery order, authentication conditions
incorrectly extended to audit logging, independent checks made conditional, and
an unsolicited change from plain to polite style. Acceptable pairs and unresolved
cases prevent calibration from treating every change as an error.

Eleven further pairs cover path length changed into performance, capability
expanded into reuse, reconstruction changed into guaranteed shortening,
separate operations claimed to be independent, references changed into loaded
content, optional inheritance made mandatory, user-side storage assumed local,
and policy definition confused with enforcement. Controls retain precise plain
verbs or replace relative wording with supported counts and event operations.
Unsupported details use `needs-evidence`; contradictions and lost explicit
conditions use `reject`. These are original editorial fixtures, not manuscript
excerpts. The 21-paragraph corpus and judge rubric are unchanged, but the changed
calibration fingerprint requires a new AI baseline for comparison.

## What normal tests check

Run the complete suite from the repository root with MeCab and UTF-8 IPADIC
installed:

```sh
bundle exec rake test
```

[Prose benchmark tests](../test/prose_benchmark_test.rb) check exact agreement
between the AsciiDoc input and JSON corpus, source mapping and paragraph order,
annotated target positions, false positives and duplicates, and both MeCab and
explicit literal analysis. They also check response validation, comparison
compatibility, summary calculations, and mechanical verification in a trial
using a fake evaluator. The fake evaluator makes the workflow test repeatable;
it does not assess readability or understand the revision pairs.

[Default rule tests](../test/default_rules_test.rb) check metaphor detection,
allow lists, and protected text using the detection examples.
[Writing tests](../test/writing_test.rb) and
[review tests](../test/review_test.rb) check that the shared criteria reach writing
prompts and saved review prompts. Existing sessions retain their saved criteria.

Normal tests never invoke Codex or Claude. A passing suite establishes these
contracts and regressions, not a measured improvement in model-generated prose.
Literal-mode checks do not validate MeCab; there is no automatic fallback.

## Establish a detector baseline

Before changing the detector or review criteria, save a result on the fixed
corpus. After the change, use a new output directory and compare it:

```sh
bundle exec ruby script/evaluate-prose --output .pubkit/evaluation/before
# After changing the detector or review criteria:
bundle exec ruby script/evaluate-prose --output .pubkit/evaluation/after \
  --compare .pubkit/evaluation/before/report.json
```

The report scores only `generic-framing`, the four metaphorical-operation
patterns, and `repeated-ending`. Other rule findings are counted separately.
Detection matches a target's paragraph and kind. Location accuracy then checks
its exact Unicode character offset; CLI source columns are one-based. A repeated
ending target is at the matching ending of the third consecutive sentence.

| Report field | Definition |
| --- | --- |
| `detection.precision` | Matched targets divided by detected scored candidates, × 100 |
| `detection.recall` | Matched targets divided by annotated targets, × 100 |
| `detection.f1` | 2 × matched targets divided by the sum of detected and annotated counts, × 100 |
| `detection.location_accuracy` | Correctly located matches divided by all matched targets, × 100 |
| `detection_delta` | After minus before for these four metrics, in percentage points |

Duplicate detections count as false positives. Zero denominators are `null`, not
perfect scores. A correctly detected candidate can still deserve a `keep`
decision in contextual review.

The historical [MeCab baseline](../benchmark/baseline-mecab.json) belongs to the
original 13-paragraph `technical-prose-v1` corpus. Its precision was 100, recall
81.818, F1 90, and location accuracy 77.778. Later detector fixes brought the
11-target MeCab results to 100 for all four metrics; literal recall remained
81.818. Keep that historical report unchanged. It cannot be compared directly
with v2: create a new baseline after expanding the corpus.

## Compare review criteria with AI trials

First fix the corpus, calibration pairs, and judge rubric. Save an AI baseline
before changing the review criteria, then change only the intended criteria and
rerun under the same conditions:

```sh
bundle exec ruby script/evaluate-prose --agent codex --repeats 3 \
  --output .pubkit/evaluation/ai-before
# After changing only the review criteria:
bundle exec ruby script/evaluate-prose --agent codex --repeats 3 \
  --output .pubkit/evaluation/ai-after \
  --compare .pubkit/evaluation/ai-before/report.json
```

These commands use each CLI's default model. For controlled comparisons, use
`--model` and `--judge-model` to select fixed writer and judge models available
in your environment. `--judge-agent` selects a separate evaluator CLI; otherwise
the writer's CLI is used. Same-model judging can favor the writer's style.
Claude trials use `--agent claude`. AI trials require MeCab; literal mode is
available only for deterministic detector evaluation.

Each trial performs these steps:

1. Create a fresh review session and generate its actual saved review prompt.
2. Supply the prompt and source checklists to the writer, requesting one JSON
   paragraph per corpus ID. Faithful paragraphs can remain unchanged.
3. Install revisions in the temporary trial manuscript and run mechanical
   verification for scope, inline preservation, and structure.
4. Invoke the judge separately with original and revised text labelled A/B,
   alternating the order across trials. It receives source evidence but no
   candidate findings or expected calibration answers.
5. Summarize readability, checklist retention, additions, substitutions,
   calibration, and mechanical verification separately.

The writer receives evidence checklists, so the trial measures an
evidence-assisted review workflow. It does not simulate every manuscript review.
The judge sees original source evidence, so neutral labels reduce presentation
bias without guaranteeing full blindness.

## Read the AI results

| Metric | Interpretation |
| --- | --- |
| `sentence_clarity` | Actors, actions, conditions, and sentence relationships are understandable |
| `paragraph_coherence` | Sentences form a connected explanation |
| `fact_retention` | Percentage of supplied checklist entries retained, including explicit editorial constraints |
| `addition_free_paragraphs` | Percentage with no unsupported additions identified by the judge |
| `substitution_free_paragraphs` | Percentage with no substitutions identified by the judge |
| Calibration `accuracy` | Percentage of revision-pair dispositions matching the expected answers |
| Calibration `balanced_accuracy` | Mean recall across `accept`, `reject`, and `needs-evidence` classes |
| Mechanical verification pass rate | Percentage of trials passing the existing mechanical verifier |

Readability is rated per paragraph on an ordinal scale: 1 means hard to
understand, 2 means some ambiguity or distracting framing, and 3 means clear.
Ratings are mapped to 0, 50, and 100 and averaged. These averages are descriptive
summaries, not validated interval measurements. Inspect the paragraph reasons
and actual revisions alongside the numbers.

`ai.trials` contains each trial's `original`, `revision`, and `delta` metrics;
`delta` is revision minus original. `ai.summary` retains means, population
standard deviations, minima, and maxima. `ai_delta` compares these summary means
between runs. In particular, `ai_delta.delta.sentence_clarity` compares the
within-trial clarity improvement of the new run with that of the baseline.

For an illustrative example, clarity of 50 before rewriting and 75 afterwards
means a within-trial delta of +25. If the next run's delta is +30, the improvement
relative to the baseline is +5 points. These are example numbers, not measured
results. A readability gain with lower retention or new unsupported facts should
not be accepted merely because it scores higher.

One trial is a smoke test. Use at least three to inspect variation; the runner
provides no significance test. Poor calibration warrants inspection before
interpreting quality results. `meaning_verified` remains `false` regardless of
scores or mechanical pass rate.

## Comparison conditions and artifacts

Comparisons require the same corpus, document, benchmark identity, scoring
version, analyzer, and dictionary. Reports with configuration fingerprints also
check the fixed configuration. AI comparisons additionally require matching
judge rubric and calibration fingerprints, CLI versions, and actual reported
writer and judge models. Missing actual model identity prevents AI comparison.

Keep CLI user configuration consistent as well. Reports record criteria, rules,
source, harness, and analyzer fingerprints, but a fingerprint cannot restore old
content: retain the source revision and any uncommitted changes needed to
reproduce the run. A changed corpus, judge rubric, or calibration set needs a
new baseline. Compare the intended criteria or detector change only after the
other evaluation conditions are fixed.

AI trials require installed, authenticated local Codex or Claude CLIs. They may
call their configured remote model providers and consume account usage. The
runner uses argument arrays, read-only Codex execution or tool-disabled Claude
execution, and a per-invocation timeout (`--timeout`, default 300 seconds).
Missing CLIs, authentication failures, timeouts, and invalid responses fail
explicitly. See [the adapter](../lib/asciidoc_pubkit/local_evaluator.rb) for the
required flags; older CLIs may need an update.

Outputs are saved under the chosen directory, including `report.json`, AI-mode
`detection.json`, and per-trial review sessions, verification results, prompts,
and evaluator responses. Existing output directories are never replaced.
Partial artifacts remain after a failure. Keep results under ignored `.pubkit/`;
do not commit private evaluation artifacts.

For the version 1.0.1 yomiyasu v1.0.6 adaptation, the expanded v2 deterministic
benchmark ran before and after the criteria change: precision, recall, F1, and
location accuracy were all 100, with zero deltas. The suite passed 203 tests and
2,552 assertions with real MeCab/IPADIC. These are detector and workflow checks.
External AI rewrite-and-judge trials have not yet been run for this change, so
its readability and preservation improvement remains unmeasured.

[Development](development.md) · [Manuscript scoring](scoring.md) ·
[Back to README](../README.md)
