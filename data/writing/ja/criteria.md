# Shared criteria for Japanese technical prose

## Contents

- Start with the paragraph's technical purpose
- Replace abstraction with the thing being discussed
- Give weak predicates a concrete action or consequence
- Explain metaphorical operations from evidence
- Distinguish instructions, behavior, and capabilities
- Make relationships explicit
- Keep claims within their evidence and purpose
- Remove generated-prose patterns without flattening the meaning
- Preserve exact technical terminology
- Revise the complete paragraph
- Headings and the relation to figures and code

Apply these criteria in context. They identify patterns that deserve inspection,
not words that must always be removed.

## Start with the paragraph's technical purpose

Before rewriting sentences, summarize each paragraph in one sentence:

1. What implementation, behavior, or decision is this paragraph about?
2. Who or what performs the action?
3. Under what condition does it apply?
4. What changes or follows as a result?
5. What can an engineer decide or verify from it?

If the summary is impossible, repair the paragraph's argument before polishing
individual phrases. A short sentence is not automatically clear; omitted
subjects, objects, complements, and referents must still be recoverable from the
adjacent sentences.

## Replace abstraction with the thing being discussed

Abstract terms are valid when their referent is stated. Inspect terms such as:

| Term | What must be identifiable |
| --- | --- |
| 費用・コスト | investigation time, maintenance work, CPU time, memory, network transfer, or money |
| 契約 | accepted inputs, returned values and errors, compatibility, ownership, concurrency, or another promised behavior |
| 境界 | the two components and the call, data transfer, or ownership transfer between them |
| 観点 | the actual comparison axis, such as type safety, shutdown behavior, allocation count, or supported OS |
| 書き方 | syntax, implementation technique, API shape, or document notation |
| 範囲・射程 | supported readers, covered subjects, applicable versions, or behavior guaranteed by an API |

Do not improve a sentence by replacing one abstraction with another. For
example, changing `費用` to `コスト` says nothing unless the sentence identifies
what increases.

## Give weak predicates a concrete action or consequence

Predicates such as `利用します`, `決めます`, `示します`, `扱います`, `整理します`,
`表します`, `保てます`, `異なります`, `同じではありません`, `残します`, and
`評価します` often omit the important information. Ask what is used for what,
which value or policy is decided, what differs, where evidence is stored, and
which result drives the decision.

Prefer a precise action or consequence:

- `検証結果を利用します` becomes `検証結果をAPIの見直し材料にします` when that
  is the actual purpose.
- `採用する機能を決めます` becomes `サポートするバージョンと互換性を基に採用を
  判断します` when those are the criteria.
- `結果を残します` becomes `実行したコマンドと結果をプルリクエストへ記録します`
  when that is the storage location.

Do not choose a more impressive synonym merely to vary sentence endings. Keep
the technically correct verb when it names the real operation.

## Explain metaphorical operations from evidence

Inspect expressions such as `地味に効く`, `側に倒す`, `時間を溶かす`, and
`静かに壊れる`. Identify the actual effect, selection policy, work that took
time, or failure state before revising the paragraph. A system can be a valid
subject: `サーバーが応答を返します` describes observable behavior. Repair
personification only when it conceals who acts or what happens.

Concrete wording must not invent facts. `静かに壊れる` does not by itself establish
whether an exception, warning, or log is emitted. `地味に効く` does not establish
which failure a setting prevents. Check the surrounding explanation, code, or
primary documentation; when evidence is missing, record what needs confirmation
instead of supplying a plausible implementation or effect.

For example, `採否を判断できない項目は除外する側に倒します` can become
`採否を判断できない項目は除外します` if that is the stated policy. Retain its
condition and action. Keep literal meanings and established technical terms;
`解像度`, `触媒`, and `正本` are not inherently defects.

## Distinguish instructions, behavior, and capabilities

Identify whether a sentence asks the reader to act, describes an actual system
operation, or states an available capability. Use `〜してください` for an
instruction when that fits the document's voice. Do not change `〜します` to
`〜できます` merely to make the subject clearer: automatic execution and an
optional capability are different claims. Name the actor when context does not
identify it, without repeating an already clear subject in every sentence.

## Make relationships explicit

Inspect a sentence when it:

- begins a new topic without connecting it to the preceding paragraph;
- says two things differ without naming the differing property;
- introduces a comparison without naming the alternatives and comparison axis;
- uses `これ`, `それ`, `前者`, or `後者` when the referent requires rereading;
- strings three or more abstract nouns together without explaining their
  relationship;
- uses an abrupt `読者は` even though the effect can be stated directly;
- attaches `へ` or `から` to an abstract noun in phrases such as `判断へ戻す`;
- uses a literal translation that is not an established term in the technical
  domain.

When a standalone sentence cannot identify its subject or object, use the
surrounding paragraph to supply the missing noun. Do not repeat the subject in
every sentence when it is already unambiguous.
Use prose for a sequence in which one event causes or conditions the next; use
a list when the items are genuinely parallel. Do not turn a causal explanation
into disconnected bullets or impose an order on independent items.

## Keep claims within their evidence and purpose

State whether a claim comes from an implementation, a test, a cited study, or
the author's inference. Match its scope to that evidence: a single example or
test establishes what happened under its stated conditions, not a universal
result. Preserve uncertainty when evidence does not settle the claim; do not
weaken an established fact merely to sound cautious.

Before adding a qualification, ask what decision or interpretation it changes.
Correct an overbroad main claim at its source. Remove a following disclaimer if
the preceding explanation already excludes that reading. When a limitation
affects use, implementation, or verification, state the concrete condition and
connect it to the relevant action or check. Do not delete a technical boundary
merely because it uses negative wording.

## Remove generated-prose patterns without flattening the meaning

Common patterns that merit paragraph-level review include:

- repeated `AではなくBです` or `AだけでなくBも` contrasts;
- paired short slogans that omit the actor, object, condition, or consequence;
- repeated endings such as `扱います`, `示します`, or `選びます`;
- `重要なのは`, `ポイントは`, or `〜することです` standing in for the actual
  technical fact;
- a section opening that only announces what the section will discuss;
- a section ending that only says the material was explained or organized;
- metaphors such as `土台`, `器`, `橋渡し`, or `輪が閉じる` used instead of a
  concrete technical operation;
- a standalone qualification that only denies an overbroad reading already
  excluded by the preceding explanation, such as a redundant
  `という意味ではありません` or `保証ではありません`;
- generic praise, warnings, or recommendations without the condition that makes
  them true.

Keep a contrast when the two alternatives and the difference that affects the
decision are explicit. Keep necessary repetition when it improves technical
accuracy.
Do not shorten sentences or vary endings mechanically. Read the sequence aloud
and repair the missing relationship rather than replacing one stock pattern
with another.

## Preserve exact technical terminology

Check terminology against identifiers, surrounding code, the project's
glossary, and primary documentation before changing it.

- Distinguish an API from a function, method, interface, protocol, or command.
- Distinguish an error value, operation failure, incident, and defect.
- Distinguish resource ownership from the responsibility to close or stop it.
- Use the project's chosen forms consistently, such as `goroutine` versus
  `ゴルーチン`, or `reflection` versus `リフレクション`.
- Replace unnecessary English words with established Japanese terms, but retain
  identifiers and official names.
- Do not describe a language operation with a loose everyday verb when the
  domain has a precise term, such as name shadowing, method promotion, parsing,
  serialization, cancellation, or resource release.

Natural Japanese must not erase a technical distinction. If the original claim
is ambiguous, inspect the code or authoritative documentation before editing.
Preserve numerical values, versions, settings, responsibility, causal claims,
and implementation requirements. Do not add an actor, cause, mechanism, or
effect that the source evidence does not establish. Making prose more specific
requires evidence, not a guess.

## Revise the complete paragraph

Use a finding to understand the intended claim, then rewrite the paragraph so
that every sentence connects to the next. Do not paste an isolated suggested
sentence into the manuscript without adjusting its context. After editing,
read the paragraph as continuous prose and verify subject, object, modifier,
condition, cause, and effect.

Assess readability and meaning preservation separately. Compare the source and
revision for both missing information and unsupported additions, including
conditions, negation, numbers, actors, causes, and implementation requirements.
For example, removing a unique constraint from a duplicate-message check can
lose a concurrency requirement even when the revised paragraph sounds clearer.
Record unresolved evidence and keep necessary repetition or qualifications.
No candidate count or mechanical verification result proves semantic correctness.
Sentence length, punctuation, and list density can help locate passages to read;
they are not fixed acceptance thresholds. Keep lists for parallel items and
ordered procedures, and prose for connected explanations.


## Headings and the relation to figures and code

Headings identify the subject, operation, or comparison actually explained.
Do not promise a broader comparison than the text supports or replace the
subject with an unexplained metaphor. Heading length and required section
names belong to the book's format, not to universal prose quality.
Do not force every heading into a conclusion sentence or the same template;
make the section's content identifiable in the form the book uses.

Introduce tables and figures with enough context to explain what is compared
or traced, and explain what the reader can establish from them. Keep identifiers,
values, ordering, and conditions consistent with the code or clearly label a
simplified conceptual representation. Do not repeat every label as prose.

File paths and type names belong where they help explain a specific operation;
avoid a list of identifiers before the reader knows their roles. Bibliographic
and implementation-file descriptions introduce the referenced material, rather
than narrating the author's research activity.
