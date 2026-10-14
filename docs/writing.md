# Writing commands

The unreleased [actor-change criteria](../data/writing/ja/criteria.md#clarify-omitted-subjects-when-actors-change)
compare omitted and explicit subjects across clauses, sentences and table roles.
They distinguish requesting, approving, executing and investigating, preserve
clear continued subjects, and require evidence before naming an actor. These are
contextual review criteria, with no new subject-omission detector or automatic
replacement. New sessions save the criteria; older sessions retain their originals.

The [identification comparisons](../data/writing/ja/criteria.md#distinguish-identification-from-conceptual-separation)
compare `区別できます` with `判別`, `識別`, `判定`, and separate checks according
to evidence and purpose. They preserve conceptual separation, capability,
negation and coexisting stages. They do not add automatic classification or
inspection. These unreleased criteria are advisory; saved sessions retain their
original criteria and detector behavior is unchanged.

The [replacement comparisons](../data/writing/ja/criteria.md#distinguish-replacement-from-interpretation-and-permitted-use)
compare `置き換えません` with interpretation rules (`みなしません`) and use
limits (`扱えません`), while retaining actual value, history, and implementation
replacement. They preserve conditions, negation strength, missing evidence and
responsibility. These unreleased criteria do not change detection or perform
automatic replacements; existing sessions retain their saved criteria.

## Classification and related relationships (unreleased)

Compare `分かれます` by the actual relationship: classification by purpose or
type, assignment of responsibilities, execution-path branching, content
partitioning, route differences, or the correspondence presented in a table.
`分類できます` may describe reader organization without a runtime classifier;
a defined category scheme and actual classification behavior need their own
wording. Preserve owners, conditions, destinations, counts, modality and joins;
branching alone does not guarantee parallel execution or exclusive choice.
See [the canonical comparisons](../data/writing/ja/criteria.md#distinguish-classification-responsibility-sharing-branching-and-partitioning).

Writing commands and new heading, prose and list sessions include this guidance.
Existing sessions keep their saved criteria. Detector and automatic replacement
behavior are unchanged. Manual comparison fixtures and regression tests check
criteria delivery and session preservation, not measured editorial accuracy.

`writing criteria` prints the packaged common criteria. `writing prompt` adds
task instructions around those same criteria. Neither command needs an AsciiDoc
file, a review session, MeCab, or network access. Both accept `--lang ja` and
`--output FILE`; output defaults to stdout, and an existing output file is never
overwritten. The prompt asks the agent to read project instructions and evidence;
it does not supply source facts or authorize edits. Book-specific voice and
format still come from the book. The OSS-only prose style profile remains with
the book workflow, not the shared default.

The criteria also ask reviewers to compare source and revision for
modifier targets, condition and exception scope, quantities and their targets,
parallel relationships, and required order. Preserve each sentence's function
(including advice, obligations, plans, and actual behavior) separately from plain
or polite style. Keep the author's style unless a change is requested or the
book explicitly requires one. Sentence splitting and punctuation changes must
retain the original relationships; these are contextual review instructions,
not automatic semantic checks. Saved sessions retain the criteria from their scan.

The unreleased [communication-response comparisons](../data/writing/ja/criteria.md#distinguish-communication-responses-from-function-returns)
separate HTTP, ACP and MCP responses from internal function returns and model
generation. Identify response fields, missing measurements, error values,
exception throwing and Promise rejection without inventing transport or moving
responsibility. These are advisory wording comparisons; detector and verification
behavior are unchanged, and old sessions retain their saved criteria.

Sentence-ending review first identifies scope guides, actual operations,
capabilities, checking procedures, and historical or future statements. Keep
useful guidance and precise plain verbs; clarify vague judgment targets or
comparison axes from passage evidence. Preserve negation strength: a definite
difference is not interchangeable with insufficient evidence for equality.
A noun-phrase heading policy does not apply to body sentences. These examples
are contextual decisions, not new detector terms or replacement rules. See
[Sentence-ending criteria](../data/writing/ja/criteria.md#review-sentence-endings-by-their-role).

Terminology comparison is independent of sentence function. A technical synonym
can improve consistency while retaining the same capability or condition; honor
explicit author preferences rather than keeping a plain verb just because it is
understandable. Compare a faithful full explanation, not an unsupported stronger
alternative or a shortened passage. See
[Terminology and modality](../data/writing/ja/criteria.md#compare-terminology-independently-of-modality).

The criteria also preserve the comparison axis, completed changes,
current behavior, future plans, and the distinction between event dates and
observation or report dates. An unclear state term does not authorize deleting
its known action. Keep source-provided undecided or investigation status in the
body; put reviewer doubts and questions in the separate report, without adding
editing markers to the manuscript.

The shared criteria also distinguish human roles from human-versus-AI
comparisons. Terms such as `開発者`, `利用者`, `評価担当者`, and `文書の作成者`
are evidence-based alternatives to `人`, not a replacement dictionary. Preserve
general populations and established research concepts, and do not introduce
new permissions or imply that different roles require different people.
Heading criteria connect terminology changes with the section's body and
separately proposed table, figure, and alternative-text synchronization.

```sh
asciidoc-pubkit writing criteria --lang ja
asciidoc-pubkit writing prompt --lang ja --output writing-prompt.md
```

For example, `--lang en` exits with an unsupported-language error. No English
review or writing criteria are shipped in 1.2.1.

For a small trial, use `examples/book.adoc` as the scan input. Its Japanese
paragraphs deliberately contain review candidates; its code block must remain
unchanged.

## Decision wording

The unreleased criteria compare `決めます` with `決定します` and with the actual
operation: selecting tools or information, computing budgets, configuring values,
classifying states or permission outcomes, assessing evidence, and establishing
design or evaluation conditions. Describe causal relationships with `定まります`
when inputs determine a result, retaining every contributing factor. Do not
invent calculation, runtime changes, checks, or approvals for a more technical
verb. These are contextual prompt comparisons, not detector or replacement
rules; existing sessions retain their saved criteria. See
[Decision criteria](../data/writing/ja/criteria.md#distinguish-decisions-by-the-actual-operation).

[Back to README](../README.md)

## Explicit differences and decision conditions

The unreleased criteria expand `区別します` comparisons with examples of loading
conditions, rule purposes, identifier uses, recorded states, and inference limits.
Naming two objects is insufficient when the property or consequence that differs
is missing. Compare the full passage with a direct explanation and remove any
resulting repetition. Retain accurate distinctions after comparison; do not infer
physical isolation, automatic checks, or extra approval steps. These are prompt
criteria, not detector rules or automatic replacements. Existing sessions retain
the criteria saved at scan time. See
[Relationship criteria](../data/writing/ja/criteria.md#make-relationships-explicit).

## Direct negation and inference limits (unreleased)

Compare `わけではありません` with a direct denial of the actual operation or
capability, while retaining its actor and conditions. Keep partial negation such
as `必ずしも一致しません` distinct from total denial, and retain a concrete
inference limit when evidence does not establish an outcome. The canonical
criteria include examples for sending tool definitions, unavailable input,
insufficient conditions and incomplete restoration. These are contextual
comparisons, not automatic replacement rules. Existing sessions retain their
saved criteria; use a new session to review under changed criteria.

## Processing phases, timing and progressive disclosure (unreleased)

The shared criteria compare `段階` with `フェーズ` for execution-state fields and
processing or work divisions, while preserving counts, order and conditions.
Timing, state predicates, progressive disclosure and research evaluation scope
need individual comparisons; no blanket replacement is prescribed. See
[the contextual examples](../data/writing/ja/criteria.md#compare-processing-phases-with-timing-and-progressive-disclosure).

Writing commands and new heading, prose and list sessions include these criteria.
Existing sessions keep their saved criteria. Detection and automatic replacement
behavior are unchanged. Manual accept/reject examples are maintained in
`test/fixtures/phase_terminology.ja.json`; their labels and regression tests do
not measure AI proofreading accuracy.

## Input, transmission, and handoff (unreleased)

Use the canonical [transfer comparisons](../data/writing/ja/criteria.md#distinguish-input-transmission-delegation-inheritance-and-handoff)
for `渡す` and related forms. Compare model input construction, API transmission,
arguments, configuration, notifications, delegation, continuity and artifact
handoff before revising or retaining a passage. `連携` describes cooperation;
it must not hide a concrete data operation. Preserve conditions, modality,
negation, recipients and order. The bundled skill routes focused reviews to
saved criteria; existing sessions retain their original criteria.
No detector or automatic replacement rule is added.
