# Development

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

[`test/fixtures/prose_evaluation.ja.json`](../test/fixtures/prose_evaluation.ja.json)
contains original Japanese technical prose for candidate regression and manual
revision evaluation. Automated tests check metaphor candidates in both
tokenizers, source positions, inline exclusions, and allow lists. The revision
pairs are manual evaluation cases, not an automated semantic checker or a
measured AI benchmark. Compare source and revision separately for readability,
information loss, and unsupported additions, using each case's review axes and
expected disposition. Cover conditions, negation, numbers, versions, actors,
causes, implementation requirements, and necessary repetition. The 20 manual
revision pairs also cover modifier and quantity targets, order, parallel work,
condition scope, sentence functions, and explicit style constraints. They include
acceptable revisions, meaning changes with unchanged numerals, and unresolved
actors that need evidence. These expected dispositions calibrate an optional
AI judge; automated fixture checks do not prove semantic understanding. Record the
model, prompt, source evidence, and human judgments when evaluating actual
generated revisions; fewer findings alone do not establish an improvement.

### Development prose benchmark

The checkout provides `script/evaluate-prose` for measuring future detector and
prompt changes. This is a development tool, not an installed gem command; the
benchmark CLI calls are separate from the optional `review score --agent` path.
The fixed
[`prose_benchmark.ja.adoc`](../test/fixtures/prose_benchmark.ja.adoc) contains 21
original editorial paragraphs with intentionally vague framing and metaphors,
inflection variants, and valid technical prose controls. Its
[`annotations`](../test/fixtures/prose_benchmark.ja.json) contain 11 review targets
and separate source fact checklists. It is a small synthetic regression corpus,
not an AI authorship dataset or a representative measure of prose quality.
The expanded `technical-prose-v2` corpus adds eight paragraphs for structural
preservation and style review. Their fact checklists include editorial constraints
as well as technical claims; they add no detector targets. They are still supplied
to the reviewer and judge even when the three scored detector kinds have no findings.
Normal tests validate corpus mapping and the evaluation workflow with a fake
agent; real model readability and preservation results require explicit `--agent`.

Run the deterministic benchmark before and after a change:

```sh
bundle exec ruby script/evaluate-prose --output .pubkit/evaluation/before
# After changing the detector or prompt:
bundle exec ruby script/evaluate-prose --output .pubkit/evaluation/after \
  --compare .pubkit/evaluation/before/report.json
```

The report measures candidate precision, recall, F1, and location accuracy on a
0–100 scale for `generic-framing`, metaphorical operations, and `repeated-ending`.
Other rule findings are counted separately and are not judged against these
annotations. Detection matches a target's paragraph and kind; location accuracy
then checks the one-based source position, represented internally as a zero-based
Unicode character offset within that paragraph. The annotated repeated-ending
location is the matching ending of the third sentence in the consecutive run.
A candidate can be correctly detected even when the reviewer should keep it.
Zero denominators are reported as `null`, not perfect scores. Duplicate detections
count as false positives. These scores measure the detector, not the manuscript.

The checked-in [`MeCab baseline`](../benchmark/baseline-mecab.json), captured before
the detector changes on the original 13-paragraph `technical-prose-v1` corpus,
has precision 100, recall 81.818, F1 90, and location
accuracy 77.778. It misses two inflected metaphor phrases and mislocates two
repeated-ending candidates. Reports record source, criteria, rules, corpus, and
dictionary fingerprints. Comparisons reject changed corpora, scoring versions,
analyzers, or dictionaries. Reports with configuration fingerprints also reject
changed benchmark configuration. A fixed empty configuration
keeps these trials independent of auto-discovered manuscript settings.
The 0.6.2 location correction raises location accuracy to 100 without
changing precision, recall, or F1 on this corpus. Adding the four MeCab predicate
patterns then raises precision, recall, F1, and location accuracy to 100 on these
11 targets. This is regression evidence for the fixed synthetic corpus, not
evidence of general performance on unseen manuscripts; literal recall remains
81.818.
That historical report is retained unchanged and cannot be compared directly
with `technical-prose-v2`. Record a new baseline on the expanded corpus before
changing criteria or detectors, and also when dictionary fingerprints differ.
`--tokenizer literal` explicitly selects a separate limited-mode run;
there is no automatic fallback, and literal results do not validate MeCab.

### Optional local AI evaluation

Use an installed, authenticated Codex or Claude CLI to perform rewrite and judge
trials explicitly. A local CLI may call its configured remote model provider and
consume account usage; this is not an offline model test. Normal `rake test`
does not run either CLI. For example:

```sh
bundle exec ruby script/evaluate-prose --agent codex --repeats 3 \
  --output .pubkit/evaluation/ai-before
bundle exec ruby script/evaluate-prose --agent codex --repeats 3 \
  --output .pubkit/evaluation/ai-after \
  --compare .pubkit/evaluation/ai-before/report.json
# Or use Claude:
bundle exec ruby script/evaluate-prose --agent claude \
  --output .pubkit/evaluation/claude-before
```

Each trial generates the actual saved review prompt, requests paragraph revisions
as JSON, and runs the existing mechanical verifier. A fresh judge invocation
evaluates both original and revised prose with neutral A/B labels, alternating
their order across trials. The judge sees source evidence but no findings, tool
revision labels, or expected calibration answers. The writer receives the source
fact checklist in addition to the review prompt, so this measures an evidence-
assisted workflow rather than every real-world manuscript review.

Sentence clarity and paragraph coherence are separately rated 1–3 and displayed
as 0, 50, or 100 before averaging. These ordinal averages are descriptive
summaries, not validated interval measurements. Fact retention measures the
percentage of annotated source facts preserved; addition-free and substitution-
free paragraph percentages remain separate. Known acceptable, incorrect, and
unsupported revisions from `prose_evaluation.ja.json` calibrate the judge using
accuracy and balanced accuracy across the three dispositions. Inspect poor
calibration before interpreting quality scores. No combined AI-likeness score or
semantic pass is produced: `meaning_verified` remains `false`.
Mechanical verification results and their pass rate are also reported separately.
Quality scores from a trial with preservation violations remain visible for
diagnosis; a completed evaluation does not authorize accepting that revision.

One trial is a smoke test; use at least three to inspect variation. Reports retain
individual scores, means, population standard deviations, and ranges. They do
not perform a significance test. Same-model judging can favor the writer's style;
`--judge-agent` and `--judge-model` select a separate evaluator. `--model` selects
the writer model; omitted model options use each CLI's default. AI comparisons
require the same reported writer and judge models, CLI versions, rubric, and
calibration corpus. CLI defaults can change, so retain the recorded model IDs
and use explicit model options for controlled comparisons. Score changes can
reflect sampling variation as well as implementation changes.
When testing a criteria change, first fix the expanded corpus, calibration pairs,
and judge rubric and record the AI baseline; then change only the review criteria
and rerun. A changed judge rubric or calibration corpus requires a new baseline.

The runner uses argument arrays rather than shell interpolation, read-only Codex
execution or tool-disabled Claude execution, and a per-invocation timeout
(`--timeout`, default 300 seconds). The CLI may still load its user configuration;
use consistent settings for comparisons. Current adapters require the flags
shown by `codex exec --help` and `claude --help`; older CLI versions may need an
update. Missing CLIs, authentication errors, timeouts, and malformed responses
fail explicitly. Existing output directories are never replaced. Partial
artifacts remain available after failures. Results, prompts, responses, and review
sessions belong under ignored `.pubkit/`; do not commit private evaluation runs.

[Back to README](../README.md)
