# English regression and editorial evaluation

This development workflow is separate from the manuscript CLI. It never invokes
an AI CLI or network service. Its scripts, fixtures and baseline report are kept
in the repository rather than packaged in the gem.

## Detection corpus and score baseline

`test/fixtures/english_detection.json` contains 120 original agent-authored
technical paragraphs from 12 document groups. Six groups (60 paragraphs) are
assigned to development and six disjoint groups to a reserved evaluation
partition. Topics include APIs, procedures, architecture, failure analysis,
storage, deployment, networking, policy, observability, concurrency, import and
compatibility. Each expected finding has a rule ID, source character offset and
original matched text; negative examples have an empty list. These are lexical
candidate labels, not labels asserting that the sentence is defective.

The corpus has 59 expected candidates: 22 redundant-framing, 24 wordy-expression
and 13 repeated-word candidates. Exceptions and protected/identifier examples
are retained. In particular `is is` is deliberately exempt even when it might
be a typo; the detector does not resolve that grammatical ambiguity. Contextual
review must still read paragraphs without candidates.

The acceptance contract, recorded with the corpus before the initial run, is
at least 0.90 precision and recall per rule, and exact locations for matched
expected surfaces. Regression comparison also rejects any decrease from the
recorded baseline's per-rule precision, recall or F1 and overall location
accuracy. Counts, false positives per 1,000 lexical words and per-rule metrics
remain visible. Lexical words are tokens under `unicode-lexical-v1` after inline
masking; this is an evaluation denominator, not a new manuscript score unit.

```sh
bundle exec ruby benchmark/english.rb --baseline benchmark/baseline-english.json
bundle exec ruby benchmark/english.rb --split development
bundle exec ruby benchmark/english.rb --split held_out
bundle exec ruby benchmark/english.rb --output /tmp/new-english-report.json
```

The initial baseline has precision, recall, F1 and location accuracy of 1.0,
zero false positives, and candidate-density score 65.853 (59 candidates over
8,639 non-space unmasked Unicode characters). The score is obtained through the
actual `Score.run` path and is a within-configuration indicator. A candidate
score delta is reported but never used as proof of quality improvement. Removing
all detectors fails recall; wrong locations and duplicated findings fail the
regression checks even if a density score looks favorable.

The comparator requires the same corpus hash and split. Rule identity and
analysis identity are reported alongside the score; changes require review of
the exact metrics rather than cross-configuration score comparisons. Do not
regenerate the baseline merely to make a regression pass. A changed corpus needs
an explicit new baseline and review of the changed annotations. Existing output
paths are never overwritten. Exit 0 means selected checks passed, 1 means a
quality/regression gate failed, and 2 means invalid input or output failure.

The authoring agent could see both partitions. They prevent accidental document
mixing and support regression tracking, but this is not blind held-out testing
or independent human annotation. Perfect fixture results do not estimate
production precision or prove better writing. Before promoting these thresholds
to an editorial quality claim, independently annotate a technical-book sample,
use multiple reviewers on a calibration subset and adjudicate disagreements.
Keep the Japanese corpus and historical baseline unchanged.

## Revision calibration and imported judgments

`test/fixtures/english_revisions.json` contains 24 agent-authored revisions:
12 acceptable alternatives and 12 fluent but unacceptable alternatives. Cases
cover actors, permission, capability, negation, quantities, uncertainty, future
plans, justified passive voice, technical terms, measurement conditions,
acceptance versus completion, and framing. Each supplies explicit source facts,
expected fact-retention labels and an acceptance decision. These labels are
calibration proposals, not independent human judgments.

Generate an evaluator prompt without expected decisions or retention labels:

```sh
bundle exec ruby benchmark/english.rb --judge-prompt --output /tmp/english-judge.md
```

Case IDs do not encode acceptance, and cases are ordered by opaque ID rather
than accept/reject blocks. The prompt asks for separate ordinal 1–3 sentence
clarity and paragraph coherence ratings, fact retention booleans, a decision and
reason. Any external evaluation must be explicitly arranged by the user; this
script does not send the prompt. Record the evaluator/model identity and retain
raw responses when performing such a trial. Repeated trials, order changes and
comparison with independent human labels are needed before claiming stability.

Import the resulting JSON, with every case ID exactly once:

```json
{
  "evaluator": "reviewer or exact model/configuration identity",
  "judgments": [
    {
      "id": "an exact case ID from the prompt",
      "decision": "reject",
      "sentence_clarity": 3,
      "paragraph_coherence": 3,
      "retained_facts": [true, false],
      "reason": "The revision changes the stated condition."
    }
  ]
}
```

The example shows one row's structure; actual input must include all 24 rows and
one boolean per supplied fact. An accept decision with a false fact-retention
judgment is invalid. Missing/duplicate IDs, out-of-range ratings and missing
reasons are rejected.

```sh
bundle exec ruby benchmark/english.rb --judgments /tmp/english-judgments.json \
  --baseline benchmark/baseline-english.json --output /tmp/english-evaluation.json
```

The report includes decision accuracy, false accepts, fact-retention accuracy,
clarity/coherence, and corpus/rubric identities. Ratings map 1, 2, 3 to 0, 50,
100 as in the Japanese readability path, independently of fact retention.
Calibration gates require zero false accepts and at least 0.90 decision and
fact-retention accuracy. High readability cannot override lost facts.

Normal tests use synthetic responses only to verify this evaluator harness,
including an evaluator that incorrectly accepts every fluent revision. They do
not constitute model trials. Without imported judgments the semantic result is
`not_run`; even a passing imported evaluation keeps `meaning_verified: false`.
This evaluates the judge on fixed revisions, not an agent's ability to produce
better edits. Evaluating a real editing workflow additionally requires preserving
its actual before/after outputs, source facts, prompt/model versions, independent
judgments and comparable trials. No such experiment has been run here.

[English review](english-review.md) · [Scoring](scoring.md)
