# Shared criteria for Japanese technical prose

## Contents

- Start with the paragraph's technical purpose
- Replace abstraction with the thing being discussed
- Give weak predicates a concrete action or consequence
- Explain metaphorical operations from evidence
- Distinguish instructions, behavior, and capabilities
- Make relationships explicit
- Compare structure before and after revision
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

Identify both the referent and its role before retaining an abstract term.
A named API, file, or command can make the referent recoverable while leaving
its operation vague. Inspect terms such as:

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

For role metaphors such as `入口`, check whether naming the actual operation or
relationship gives the reader more useful information, even when the referent
is already clear. Consider these alternatives only when evidence supports them:

| Intended role of 入口 | More direct wording |
| --- | --- |
| Object creation | 生成API・生成メソッド, or state what the method creates |
| Invocation or external access | 呼び出しAPI・アクセス経路, or name the call and its operation |
| Configuration or prompt changes | 設定項目・上書きメソッド・コールバック・変更手段, preserving the changed scope |
| Command use | Name the command and the action it performs |
| Documentation or test references | 参照先・確認対象, or state what the document explains or test checks |
| Learning introduction | 導入例・理解する手がかり, supported by the example's actual content |
| Actual execution entry point | エントリポイント when that is the established technical role |

For example, `実行基盤を作る入口はcreate()です` can become
`実行基盤は生成メソッドcreate()で作ります`; `利用側の入口はinstallです` can
become `インストールするコマンドはinstallです`. Keep asynchronous behavior,
inputs, conditions, and other facts from the surrounding passage.
Do not replace every `入口` with `エントリポイント`, or introduce an API,
mechanism, or stronger guarantee that the source does not establish. Preserve
negation and scope: a catalog listing does not imply an execution method exists.
Distinguish a public option or return field from internal state before describing
a change mechanism. Literal entrances and clearly established technical usage
can remain. For keep, explain the role and why retaining the wording serves the
reader better than the considered direct alternative; naming its referent alone
or appending the original sentence to a generic reason is insufficient.

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

For everyday verbs, identify the operation before choosing terminology:

| Wording to inspect | Revision when supported by context |
| --- | --- |
| ツールを呼ぶ | 呼び出す for invocation; 実行する only for execution |
| 責務を持つ | 責務を担う when describing responsibility, not stored state or ownership |
| 指示を読み取る | 解析する for parsing or analysis; 抽出する for selecting information |
| 設定を書く・設定を書きます | 設定を記述する・定義する for authoring a definition; 設定する for actually configuring something |
| 値を拾う | 取得する for retrieval; 抽出する for selection from existing data |
| 切り出す合図です | 切り出す目安です for a judgment criterion; シグナルです only for an actual signal |
| インタフェースから使えます | 利用できます when describing availability through the interface; retain the actor and capability |
| 拡張機構が積み重なります | 階層化されています only for established layers; スタックを構成しています only for an actual stack and its ordering |
| 拡張点として開放しています | 提供しています for offering an extension facility; 公開しています for exposing access, preserving any access restrictions |
| 自動継続を途中で切らずに一巡を追えます | 追跡できます・トレースできます when following the sequence; preserve the complete cycle and uninterrupted continuation |
| 再試行を見落とします | 検知漏れが生じます・捕捉漏れが発生します for a system's detection failure; 見落とすリスクがあります for a human's possible oversight |
| 差分を隠しすぎずに扱えます | 処理できます for processing; 制御できます only when control is available, preserving how much difference remains visible |
| 通知文に使っています | 用いられています when the use is the focus and the actor is recoverable; retain active voice when who uses it matters |

A familiar verb is not wrong merely because it is simple. Prefer the most direct
accurate verb; do not introduce jargon or claim parsing, execution, or a state
change that the evidence does not establish.

Layering and a stack are different structural claims. Do not infer either from
an accumulation metaphor alone. Tracking is more specific than confirmation;
retain ordering and continuity instead of shortening it to `確認できます`.
Distinguish an observed detection failure from a risk of human oversight: do not
turn a definite failure into a possibility or assign human observation to a
system. Active and passive voice must preserve the same actor and responsibility.

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

Distinguish advice, obligations, plans, and evaluations as well, including when
different functions occur in adjacent sentences or clauses. A paragraph can
combine advice with an explanation of actual behavior; that alone is not an
ending inconsistency. Do not turn advice into a policy, a plan into a completed
action, or an evaluation into an implementation goal. Sequence words such as
`まず` and `次に` establish order, not whether the action is advice or actual
behavior. When the function or actor is unresolved, retain the uncertainty and
record what needs confirmation.

Preserve plain or polite style unless the author requests a change or the book's
explicit style requirements call for one. A technical topic alone does not
require polite style. Resolve unintended style mixing separately from each
sentence's function; changing `する` to `します` must not change advice into
an asserted operation. Do not vary endings just to make these functions uniform.

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

## Compare structure before and after revision

Before replacing words, identify the subject and predicate, each modifier and
its target, and each referring expression and its referent. Trace conditions,
exceptions, negation, parallel relationships, quantities and their targets,
and required order. After revising, compare those relationships with the source,
including passages without candidates. Keep naturally clear wording when no
relationship needs repair. Supply missing actors or objects only from evidence;
leave an unresolved relationship pending rather than inventing one.

Use these checks when splitting, joining, or rearranging sentences:

- Keep a condition or exception attached to the same operations. Joining an
  unconditional audit-log statement to a conditional data-save statement must
  not make logging conditional on authentication success.
- Preserve what each quantity counts and whether it is a total, per-item limit,
  minimum, maximum, or exact count. `各ワーカーは最大3回再試行します` does not
  mean `全ワーカーで合計3回まで再試行します`, although the numeral is unchanged.
- Preserve required order and distinguish it from independent parallel work.
  Stopping processing, changing settings, and restarting in that order is not
  equivalent to changing settings before stopping. Do not invent an order or
  success prerequisite for independent validation steps.
- Keep modifiers attached to their original targets after replacing verbs or
  changing word order. In `圧縮されたログを送信するサーバーを監視します`, the
  logs are compressed and the server is monitored.
- Preserve the scope and direction of purpose, reason, contrast, and emphasis.
  A purpose applying to two operations must still apply to both after splitting;
  necessary contrast or priority must not become simple addition or equality.

Adjust punctuation when it obscures these relationships, not merely to reduce
comma counts. Keep a colon that maps a label to a value, such as `状態: 正常`,
and distinguish it from an ornamental ending. Preserve inline syntax and edit
scope; prose review does not authorize rewriting labels in protected blocks.

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
Inspect indirect predicates and author-centered emphasis as well:

- Simplify `無効化したりできます` to `無効化できます` when it describes a single
  capability. Preserve `たり` when it marks a meaningful non-exhaustive list.
- Simplify `切り替えで扱えます` to `切り替えられます` when switching is the
  capability itself. Preserve the subject, alternatives, and any separate
  operation enabled by switching.
- For `三点に分かれて現れます`, identify what the three points represent. Use
  `3か所に分散します` for distributed locations or `3つの要素として定義されます`
  for defined elements only when that structure is established. Keep the count,
  separation, and relationships; `現れます` alone loses structural information.
- Simplify `担保しなければなりません` to `担保が必要です` only when the guaranteed
  property, responsible actor, and requirement remain explicit. A noun phrase
  must not hide who must establish the guarantee or weaken an obligation.
- For `提供することが前提です`, identify whose prerequisite or assumption is
  stated. Use `提供する必要があります` only when the source establishes an actual
  requirement; do not turn an assumption into an obligation.
- For `宣言することは別です`, name what is compared and how it differs. A form such
  as `宣言することとは異なります` needs an explicit, correctly oriented comparison.
- For `そうではありません`, state the specific fact or negate the specific claim.
  `実際には異なります` alone can retain the same missing referent. Preserve negation.
- For `〜が見えてきます`, state the property the explanation makes identifiable.
  `理解しやすくなります` is still a reader-effect claim that needs support; retain
  literal visibility when discussing a display or visualization.
- For `理由がここにあります`, connect the cause and result directly, for example
  `これが〜の理由です` when `これ` has a clear referent.
- For `設計の肝です`, identify the central responsibility or design decision.
  `重要なポイントです` is not sufficient when it merely replaces one emphasis
  phrase with another. Remove emotional, essay-like, or promotional emphasis
  that supplies no technical fact; retain supported judgments and their basis.

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
- Prefer established terminology in the technical domain, whether Japanese or
  katakana. Avoid forced literal translations and unnecessary English; retain
  identifiers, official names, and the project's chosen terminology.
- Do not describe a language operation with a loose everyday verb when the
  domain has a precise term, such as name shadowing, method promotion, parsing,
  serialization, cancellation, or resource release.

Review unusual translations against the actual concept:

| Wording to inspect | Context-dependent terminology |
| --- | --- |
| 木 | ツリー when referring to the data structure; keep literal trees and established mathematical usage |
| 拡張点 | 拡張ポイント for the specific extension location or interface; 拡張機構 for the broader mechanism only when that is the intended referent |
| 構築入口 | ビルドのエントリポイント only when the entry point starts a build, not object construction or initialization |
| 実装の読解 | コードリーディング for reading code; 実装の解析 when analysis is the actual task |
| エラーを回収する | エラーを捕捉する for catching; ハンドリングする for handling; preserve aggregation or collection when that is the behavior |
| 介入パターン | フックパターン only when a hook mechanism is established, not arbitrary human intervention |

An extension point and an extension mechanism can denote different scopes.
Keep `拡張点` when it is the project's established term and its referent is clear;
choose terminology for the actual interface or mechanism rather than replacing
all occurrences with a broader term.

These alternatives are not interchangeable replacements. Confirm the operation
and the domain's established usage from code, the glossary, or primary
documentation; record uncertainty rather than inventing a mechanism.

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
Include modifier targets, quantity targets, required order, exception scope,
sentence functions, and requested style in that comparison. Unchanged numbers
or words do not establish unchanged relationships.
For example, removing a unique constraint from a duplicate-message check can
lose a concurrency requirement even when the revised paragraph sounds clearer.
Record unresolved evidence and keep necessary repetition or qualifications.
A review decision must come from reading the passage and checking the applicable
criteria. A retained word does not establish a `keep` decision, and a removed
word does not establish a satisfactory revision. Give passage-specific reasons
for retaining terminology, conditions, and distinctions; leave unreviewed items
pending rather than filling them with generic maintenance reasons. Compare the
actual revision with the original claim, including paragraphs without machine
candidates. Keep unresolved evidence and protected-scope proposals visible in
the completion report.

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
