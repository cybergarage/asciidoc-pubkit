# Writing commands

Version 1.4.0 extends the [actor criteria](../data/writing/ja/criteria.md#compare-explicit-actor-names-with-the-actual-responsibility)
to explicit but vague role names such as `実行側` and `処理側`. Compare the
evidenced system, internal component, execution environment or communication
peer, and judge actor specificity separately from verb accuracy. Recheck the
whole sentence for self-handoffs and changed modifier or configuration ownership.
These are contextual instructions, with no new detector or replacement rules;
saved sessions retain their original criteria.

The v1.2.3 [actor-change criteria](../data/writing/ja/criteria.md#clarify-omitted-subjects-when-actors-change)
compare omitted and explicit subjects across clauses, sentences and table roles.
They distinguish requesting, approving, executing and investigating, preserve
clear continued subjects, and require evidence before naming an actor. These are
contextual review criteria, with no new subject-omission detector or automatic
replacement. New sessions save the criteria; older sessions retain their originals.

The v1.2.3 [directory hierarchy comparisons](../data/writing/ja/criteria.md#compare-directory-hierarchy-terms-with-concrete-locations)
compare ancestor/descendant translations with `上位・下位ディレクトリ`, while
preserving direct-parent/direct-child relationships and exact grandchild depth.
Describe inherited settings by their directory locations; keep process, agent,
tree-node and conversation-record relationships distinct. These are advisory
comparisons, not automatic substitutions. `孫ディレクトリ` is an additional
contextual candidate; standalone `親`, `子` and `孫` are not new detector terms.
Saved sessions retain their original rules and criteria. Regression fixtures
and prompt-delivery tests do not measure AI proofreading quality.

The [identification comparisons](../data/writing/ja/criteria.md#distinguish-identification-from-conceptual-separation)
compare `区別できます` with `判別`, `識別`, `判定`, and separate checks according
to evidence and purpose. They preserve conceptual separation, capability,
negation and coexisting stages. They do not add automatic classification or
inspection. These v1.2.3 criteria are advisory; saved sessions retain their
original criteria and detector behavior is unchanged.

The [replacement comparisons](../data/writing/ja/criteria.md#distinguish-replacement-from-interpretation-and-permitted-use)
compare `置き換えません` with interpretation rules (`みなしません`) and use
limits (`扱えません`), while retaining actual value, history, and implementation
replacement. They preserve conditions, negation strength, missing evidence and
responsibility. These v1.2.3 criteria do not change detection or perform
automatic replacements; existing sessions retain their saved criteria.

`writing criteria` prints the packaged common criteria. `writing prompt` adds
task instructions around those same criteria. Neither command needs an AsciiDoc
file, a review session, MeCab, or network access. Both accept `--lang ja` or `--lang en` in version 1.3.0 and
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

The v1.2.3 [communication-response comparisons](../data/writing/ja/criteria.md#distinguish-communication-responses-from-function-returns)
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

The v1.2.3 criteria compare `決めます` with `決定します` and with the actual
operation: selecting tools or information, computing budgets, configuring values,
classifying states or permission outcomes, assessing evidence, and establishing
design or evaluation conditions. Describe causal relationships with `定まります`
when inputs determine a result, retaining every contributing factor. Do not
invent calculation, runtime changes, checks, or approvals for a more technical
verb. These are contextual prompt comparisons, not detector or replacement
rules; existing sessions retain their saved criteria. See
[Decision criteria](../data/writing/ja/criteria.md#distinguish-decisions-by-the-actual-operation).

[Back to README](../README.md)

## Rules, definitions, and configured values

The v1.2.3 criteria compare `定める` with `規定する` for specifications,
rules, evaluation conditions, and responsibilities, honoring an author's
terminology preference without adding obligations or enforcement. Use `定義する`
for structures, schemas, and workflows, and `設定する` for configured values and
destinations when those are the actual operations. A limit type describes supplied
values; its declaration does not itself configure or enforce a limit. Split mixed
operations such as `許可範囲を規定し、通知先を設定します` while preserving actor,
timing, conditions, negation, and modality. Do not turn a plan into a runtime check
or permission into an obligation. These contextual comparisons add no detector
terms or automatic replacements, and existing sessions retain saved criteria.
See [Rule wording criteria](../data/writing/ja/criteria.md#distinguish-rules-definitions-and-configured-values).

## Classification and related relationships (v1.2.3)

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

## Receiving and returning

The v1.2.3 criteria compare `受け取る` and `返す` with the actual operation:
request intake, response-stream reception, retrieval/reading, arguments and return
values, model generation, stdout output, input assembly, decision communication,
and established exception throwing/catching. Keep accurate value or Promise
returns; do not replace every receipt with retrieval or every return with
nominalized return wording. Preserve the actor and processing stage: a service
returning a display message need not display it, and an execution environment
returning a result need not assemble model input. Signal argument delivery and
later cancellation notification are distinct. See the
[shared criteria](../data/writing/ja/criteria.md#distinguish-receiving-returning-and-their-actual-operations).

## Explicit differences and decision conditions

The v1.2.3 criteria expand `区別します` comparisons with examples of loading
conditions, rule purposes, identifier uses, recorded states, and inference limits.
Naming two objects is insufficient when the property or consequence that differs
is missing. Compare the full passage with a direct explanation and remove any
resulting repetition. Retain accurate distinctions after comparison; do not infer
physical isolation, automatic checks, or extra approval steps. These are prompt
criteria, not detector rules or automatic replacements. Existing sessions retain
the criteria saved at scan time. See
[Relationship criteria](../data/writing/ja/criteria.md#make-relationships-explicit).

## Direct negation and inference limits (v1.2.3)

Compare `わけではありません` with a direct denial of the actual operation or
capability, while retaining its actor and conditions. Keep partial negation such
as `必ずしも一致しません` distinct from total denial, and retain a concrete
inference limit when evidence does not establish an outcome. The canonical
criteria include examples for sending tool definitions, unavailable input,
insufficient conditions and incomplete restoration. These are contextual
comparisons, not automatic replacement rules. Existing sessions retain their
saved criteria; use a new session to review under changed criteria.

## Processing phases, timing and progressive disclosure (v1.2.3)

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

## Direct interpretation limits (v1.2.3)

Compare `とはみなしません` and `とみなしません` with `確認できません`,
`判断できません`, `評価できません`, or `証拠にはなりません` by the actual
claim. Fixed-response branch results alone cannot evaluate model judgment;
unavailable token counts do not determine whether usage was zero. Keep `だけでは`
and other limits. Missing observation does not establish non-execution or nonzero
usage. Retain an explicit policy not to count non-response as approval; do not
change it into an inability to determine approval. Honor author wording preferences
through faithful comparisons. See [the shared criteria](../data/writing/ja/criteria.md#distinguish-replacement-from-interpretation-and-permitted-use).
No automatic checks or replacements are added. Existing sessions retain saved
rules and criteria; use a fresh scan for these comparisons.

## Input, transmission, and handoff (v1.2.3)

Use the canonical [transfer comparisons](../data/writing/ja/criteria.md#distinguish-input-transmission-delegation-inheritance-and-handoff)
for `渡す` and related forms. Compare model input construction, API transmission,
arguments, configuration, notifications, delegation, continuity and artifact
handoff before revising or retaining a passage. `連携` describes cooperation;
it must not hide a concrete data operation. Preserve conditions, modality,
negation, recipients and order. The bundled skill routes focused reviews to
saved criteria; existing sessions retain their original criteria.
No detector or automatic replacement rule is added.

## Comparison headings (v1.2.3)

Heading review prompts include the saved "Distinguish comparison subjects from
distinguishing actions" criteria. Compare `違い` / `相違` for differences,
`関係` for source correspondence, or a confirmation scope for observation limits.
Both `違い` and `相違` are noun phrases. Retain `区別` for actual distinguishing
actions and follow the book's tone. Recheck the compared subjects using the body;
changing a heading does not authorize body edits. Advisory examples do not add
detection or automatic replacement rules. New sessions save these criteria;
existing sessions retain their original criteria. The regression fixtures test
prompt delivery and mechanical preservation, not AI editorial accuracy.

## Figure/table introductions and author examples

The v1.2.3 [figure/table guidance](../data/writing/ja/criteria.md#introduce-figures-and-tables-by-their-explanatory-role)
compares introductions by their role: describing contents, defining notation,
guiding a comparison or identifying the kind of diagram. It includes Japanese
before/after and retained-wording examples rather than a uniform replacement rule.
A good/bad example accompanying a whole-text proofreading request serves as a
quality benchmark across the assigned text; explicitly focused requests keep
their scope. The bundled review skill routes these assignments to the saved
criteria. Writing commands and new heading, prose and list sessions include the
guidance; existing sessions keep their original criteria. Regression checks cover
criteria delivery and source preservation, not measured AI proofreading quality.


<a id="retention-and-representation-wording-unreleased"></a>

## Retention and representation wording (v1.4.0)

The shared Japanese criteria now compare `保持` with input inclusion, container
storage, recording and attribute assignment, and `表す` with state indication,
evidence and contents. Preserve valid retention of history, original values,
locks and snapshots, and valid representation by symbols, JSON, code or graphs.
See [retention](../data/writing/ja/criteria.md#distinguish-retention-from-inclusion-storage-and-assignment)
and [representation](../data/writing/ja/criteria.md#distinguish-representation-from-evidence-and-state-indication).

These are contextual comparisons, not blanket replacements or new detector rules.
They reach writing commands and new Japanese heading, prose and list sessions;
existing sessions keep their saved criteria. English guidance, scoring and
mechanical verification are unchanged. Manual comparison fixtures and delivery
regressions do not measure AI editing quality or semantic correctness.


<a id="explanation-presentation-and-state-indication-unreleased"></a>

## Explanation, presentation and state indication (v1.4.0)

The [shared Japanese criteria](../data/writing/ja/criteria.md#distinguish-explanation-presentation-and-state-indication)
compare `示す` by its role: announcing an explanation, stating technical behavior,
displaying or recording information, presenting an actual figure/table/example,
or indicating a value's meaning. Compare whole paragraphs, including repeated
`説明し…示します` guidance and method/outcome relationships. Preserve valid
presentation and state-indication wording; do not replace every use with
`説明します` or strengthen an inspection into a guarantee.

Writing commands and new Japanese heading, prose and list sessions include the
guidance; existing sessions retain their saved criteria. No detector, automatic
replacement, score or semantic-verification behavior changes. Delivery tests
check prompt contents and source preservation, not AI proofreading quality.


<a id="json-identifiers-and-explanatory-strings-unreleased"></a>

## JSON identifiers and explanatory strings (v1.4.0)

The [Japanese](../data/writing/ja/criteria.md#preserve-json-identifiers-and-explanatory-strings)
and [English](../data/writing/en/criteria.md#preserve-json-identifiers-and-explanatory-strings)
criteria distinguish JSON keys, schema keywords and technical values from
natural-language descriptions. Compare examples with their explanations,
including field/value ownership, nesting, required arguments, string/object
representation and request/result IDs. Follow the book's notation rather than
requiring emphasis or monospace. JSON/code blocks remain protected in prose
review; translation of explanatory strings requires its own assigned scope.

Writing commands and new review sessions include these comparisons. Existing
sessions retain their saved criteria. This is prompt guidance, not an automatic
JSON inventory or rewriting command; parsing and preservation checks do not
establish semantic correctness or translation fidelity.
