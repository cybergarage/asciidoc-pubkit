# Shared criteria for Japanese technical prose

## Contents

- Start with the paragraph's technical purpose
- Clarify omitted subjects when actors change
- Identify human actors by their supported roles
- Replace abstraction with the thing being discussed
- Give weak predicates a concrete action or consequence
- Distinguish stopping, cancellation requests, and non-execution
- Distinguish decisions by the actual operation
- Distinguish rules, definitions, and configured values
- Distinguish retention from inclusion, storage, and assignment
- Distinguish representation from evidence and state indication
- Distinguish explanation, presentation, and state indication
- Distinguish receiving, returning, and their actual operations
- Distinguish communication responses from function returns
- Distinguish arrival wording by the actual operation
- Explain metaphorical operations from evidence
- Distinguish instructions, behavior, and capabilities
- Review sentence endings by their role
- Separate explanatory guidance from actual checks
- Distinguish direct negation, partial negation, and inference limits
- Compare directory hierarchy terms with concrete locations
- Make relationships explicit
- Distinguish replacement from interpretation and permitted use
- Compare structure before and after revision
- Keep claims within their evidence and purpose
- Keep source uncertainty separate from editorial questions
- Remove generated-prose patterns without flattening the meaning
- Preserve exact technical terminology
- Revise the complete paragraph
- Compare revisions before delivery and respect passage roles
- Headings and the relation to figures and code

Apply these criteria in context. They identify patterns that deserve inspection,
not words that must always be removed.

## Compare revisions before delivery and respect passage roles

For each proposed revision, compare the topic and claim, affirmation and negation,
actor and recipient, scope and conditions, certainty and capability, and quantities,
names and timing with the original and supported context. Include relative weight,
units, per-item versus aggregate limits, and completed versus planned actions.
If a comparison fails, reject that alternative; consider a faithful alternative
or retain the original with a passage-specific reason. Deletion must retain any
unique claim or condition elsewhere in the authorized scope. Evidence-backed
factual corrections require separate author authorization and an explicit source;
do not silently treat them as stylistic revisions.

Identify each passage's role from its content. Explanations describe actual
behavior; procedures may repeat imperative endings and numbered steps; warnings
retain prohibition and requirement strength. Do not remove necessary repetition,
merge distinct steps, or soften warnings merely to vary style. Document genre
alone does not establish the actor, authority, or required sentence ending.

Inspect all edited passages against the original, including edits with no
detector candidates. Lexical counts can stay unchanged despite a reversed
condition, exchanged actors, or an invented fact. Keep automatic preservation,
execution of the final checks, and editorial judgments separate. If supporting
material suggests a missing fact, report the proposed addition with its exact
source and scope; do not insert it as part of an unrequested prose correction.

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

## Clarify omitted subjects when actors change

Identify the actor of each action from the complete paragraph and its evidence.
A subject in a conditional or subordinate clause does not automatically identify
the main clause's actor. When a model requests an operation but an agent executes
it, or a user rejects an operation but a program skips it, name the main clause's
actor. Apply the same comparison across adjacent sentences when responsibility
changes between design, request generation, approval, execution, recording, and
investigation. A possible reading recovered from context alone does not justify
keeping an omission that invites a different actor reading.

Compare an explicit subject while preserving the same facts and modality:

| Passage and supported context | Comparison |
| --- | --- |
| The agent controls file changes: `モデルが変更を要求しても、許可されるまではファイルを変更しません。` | `モデルが変更を要求しても、エージェントは許可されるまではファイルを変更しません。` separates requesting from executing without naming an unsupported approver. |
| The program applies the user's decision: `利用者が拒否した場合、その要求を実行しません。` | `利用者が拒否した場合、プログラムはその要求を実行しません。` separates refusal from execution control. |
| The preceding sentence names the agent: `エージェントはファイルを読み込みます。その結果を会話へ追加します。` | Compare repeating `エージェントは` in the second sentence; retain omission when both actions belong to that agent and repetition adds no useful distinction. |
| A table separates runtime results from recovery steps | Identify the runtime actor and the caller investigating the result; use clear row/column roles instead of repeating subjects in every cell. |

When runtime failure is followed by a checking or recovery procedure, establish
who investigates it. Do not assign a caller's check to the failing tool, or turn
a program's automatic check into a developer's manual test. Likewise, distinguish
an API provider from an adapter that parses its response. Name only roles supported
by the passage or owning implementation; do not assume every check is performed
by a user, developer, or agent.

Keep a continued subject, a clear table label, a noun-phrase heading, or a suitable
passive construction when an explicit actor would only repeat context or misstate
the responsibility. These criteria do not require a subject in every sentence.
If evidence cannot identify an actor, record needs-evidence rather than supplying
a plausible one. An explicit actor must not introduce automatic execution,
approval ownership, permission changes, inspections, or guarantees. Preserve
conditions, partial negation, capability, and the difference between a request
and its completion. Record the original, faithful alternative, and specific reason
for revising or retaining each assigned passage, even without detector candidates.

### Compare explicit actor names with the actual responsibility

A written subject can still hide its owner or role. Compare terms such as
`実行側` and `処理側` with the evidenced system, internal component, execution
environment, or communication peer. Establish the level of responsibility from
the full paragraph and implementation evidence before choosing a name. A system
name can suit behavior shared across its components; a component name can suit
an internal handoff. Neither is universally more precise.

| Passage and supported context | Comparison |
| --- | --- |
| The agent validates tool requests: `実行側は対象への操作が許可されるかを判定します。` | Compare `エージェントは対象への操作が許可されるかを判定します。`; preserve the target and permission owner. |
| A request is delegated inside the agent: `エージェントは要求を実行側へ引き渡します。` | Compare `エージェントは要求をツール実行処理へ引き渡します。` when that internal recipient is established; replacing the recipient with the same agent obscures the handoff. |
| The benchmark's environment executes commands: `実行側がコマンドを実行します。` | Compare `環境側の実行処理がコマンドを実行します。`; do not assign environment execution to the evaluated model or agent without evidence. |
| A request recipient sends a response: `実行側が結果を応答として送信します。` | Compare `要求を受信した相手が結果を応答として送信します。`; do not narrow the peer to a server if either endpoint can receive requests. |
| A preceding definition names one component `実行側` | Compare repeating the component's name, and retain the defined role when it identifies the same responsibility clearly and no author terminology preference requires a change. |

Do not replace every occurrence with `エージェント`, a product name, or
`実行処理`. Name only roles established by the assigned passage; keep formal
identifiers, book-specific terms, and other systems' ownership. Compare actor
specificity separately from whether a verb such as `戻します` describes the
correct operation. A valid verb does not settle an ambiguous actor, and a clear
actor does not settle an imprecise verb.

Compare the complete revised sentence and its neighbors after changing a name.
Check subject-predicate and particle relationships, modifier targets, repeated
words and unintended self-handoffs. In particular, naming the component applying
a configured rule must not also make it the component that configured the rule.
Retain conditions, capability, permission ownership and processing order. Record
the actual alternative and reason; missing actor evidence remains unresolved.

## Identify human actors by their supported roles

Treat `人` as a cue to identify the actor, not as a forbidden word or a
replacement instruction. Determine who performs the operation from the
paragraph, neighboring context, and source evidence before naming a role.

| Supported role in the passage | Possible wording |
| --- | --- |
| Designing or implementing a system, test, or execution environment | 開発者・設計者 |
| Requesting work, operating a UI, approving an operation, or selecting a workflow | 利用者・ユーザー |
| Reviewing samples or calibrating scoring criteria | 評価担当者 |
| Authoring a document whose authority is being discussed | 文書の作成者 |
| Contrasting human judgment with a model or program | 人間・人間側 |

These are context-dependent examples, not a mandatory glossary. Follow the
book's established terms. A developer can also be a user; these role names do
not imply separate people, new permissions, qualifications, or staffing.
Do not infer `開発者` merely because the book concerns software. For example,
`人が候補を選ぶ` can become `利用者が候補を選ぶ` when the application displays
candidates for selection, while constructing those candidates can be a developer's
role. A role change must not narrow who may perform the documented operation.

Keep general populations, established research terminology, and human-versus-AI
comparisons when specificity would change their scope. `人の介入` can name a
measure of autonomy, and `多くの人` need not mean only developers. Do not treat
`個人`, `人数`, or `3人` as ambiguous actor wording. If the actor cannot be
established, record the missing evidence rather than assigning an occupation.
When an actor is unnecessary, state the concrete form instead: a displayed table
may be described as `表形式` instead of `人が読みやすい形`.

## Replace abstraction with the thing being discussed

Identify both the referent and its role before retaining an abstract term.
Understandability is an initial factual check, not a keep decision. For broad or
everyday wording, compare a concrete alternative and prefer an accurate established
technical term that narrows the intended meaning. Record the alternative and the
specific benefit or loss; a summary of the passage does not establish this comparison.
A named API, file, or command can make the referent recoverable while leaving
its operation vague. Inspect terms such as:

| Term | What must be identifiable |
| --- | --- |
| 費用・コスト | investigation time, maintenance work, CPU time, memory, network transfer, or money |
| 契約 | accepted inputs, returned values and errors, compatibility, ownership, concurrency, or another promised behavior |
| 境界 | the two components and the call, data transfer, or ownership transfer between them |
| 観点 | the actual comparison axis, such as type safety, shutdown behavior, allocation count, or supported OS |
| 書き方 | syntax, implementation technique, API shape, or document notation |
| 流れ | processing order, information transfer, invocation path, work procedure, or state changes |
| 範囲・射程 | supported readers, covered subjects, applicable versions, or behavior guaranteed by an API |

Do not improve a sentence by replacing one abstraction with another. For
example, changing `費用` to `コスト` says nothing unless the sentence identifies
what increases.

Treat `流れ` as a cue to identify the described operation, not as a banned word.
Even when the actors, transferred information, order, or conditions are clear,
compare a more exact expression for the supported relationship. Prefer that
expression when it clarifies the technical role; keep the original only with
a specific comparison showing no improvement or a loss of scope. Examples include
`処理順`, `情報の受け渡し`, `呼び出し経路`, or `作業手順`.
Changing `流れ` to `処理フロー` alone does not add specificity. Use `シーケンス`
for the order of calls or events, `データフロー` for data transfers and
transformations, and `ライフサイクル` for creation, execution, termination or
release only when those are the actual subject. These terms are not interchangeable;
do not invent missing stages, narrow an explanation to data alone, or lose a
branch condition merely to make the wording more technical. For example,
`検査に成功した後だけ、実行関数を呼び出す流れです` already states the
operation, order and condition and can remain unchanged only after comparing
a direct description of that conditional invocation and finding no useful improvement.

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

## Distinguish decisions by the actual operation

Compare `決めます` with `決定します` and with the operation actually described.
`決定します` can suit a technical book's voice, but it is not automatically more
precise. Identify the actor, target, evidence, condition, and processing stage
before choosing the verb; honor the author's terminology preference while
preserving the facts and modality.

| Intended operation | Faithful comparison when supported |
| --- | --- |
| Choosing a tool, information, or an improvement target | `呼び出すツールを選択します`・`外部へ送信する情報を選択します`; retain selection criteria and the scope of the choice |
| Computing an input budget or capacity limit | `入力予算を算出します`; establish the calculation before using 算出, and retain reservations, margins, units, and limits |
| Specifying a configured value | `上限を設定します`; do not imply automatic calculation or runtime mutation when only a design choice is established |
| Classifying an execution state or permission outcome | `実行全体の状態を判定します`・`実行可否を判定します`; preserve the observations, rules, and timing used for the classification |
| Assessing whether records can serve as evidence | `証拠として利用できるかを判断します`; do not turn limited evidence into a guaranteed outcome |
| Establishing design policies, evaluation conditions, or expected states | `評価前に条件を規定します`; compare rule-making with definition and configuration below, retaining who establishes the conditions and when |
| Deciding the next process, adoption start, or ordering | `次の処理を決定します`・`適用を開始する依頼を決定します`; do not invent an algorithm, tie-break direction, or approval step |
| Describing how inputs or configuration determine a result | `最終設定は、読み込んだファイルと値を反映する順序によって定まります`; preserve every contributing factor and do not attribute decision-making to an inert value |

A sentence can contain different operations: `呼び出すツールを選択し、どの操作を
同時に進められるかを判定します` distinguishes selection from eligibility.
Compare the complete paragraph and related tables, figures, and alternative text
within the authorized scope. Do not replace every occurrence with `決定します`,
and do not add calculation, configuration, inspection, execution, or approval
merely to make a verb more technical. Record the original, actual alternative,
and passage-specific reason. These are contextual prompt criteria, not automatic
replacement instructions; existing sessions retain their saved criteria.

## Distinguish rules, definitions, and configured values

Compare `定める` with `規定する` when the passage establishes rules,
specifications, evaluation conditions, or responsibilities. Honor the author's
technical terminology preference while retaining the actor, timing, conditions,
negation, and modality. Greater formality alone does not establish a more exact
operation; compare these equally faithful alternatives in the complete paragraph:

| Intended operation | Faithful comparison when supported |
| --- | --- |
| Stating a rule, contract, or evaluation condition | `評価前に条件を規定します`・`APIの提供元が要求の形式を規定します`; preserve who specifies the rule and when |
| Describing a structure, schema, or workflow | `工程と分岐を定義します`; do not imply compilation or execution from a definition alone |
| Specifying a configured value or destination | `上限や接続先を設定します`; do not turn a design policy into an actual runtime mutation |
| Describing a type used to supply values | `RunLimitsは上限を指定する型です`; a type declaration does not itself configure, enforce, or execute a limit |
| Deciding whether an option applies | `Skillを追加するか決定します`; do not substitute general rule-making for a particular adoption decision |
| Describing a result determined by inputs | `保存方式は実装によって定まります`; retain the causal factors rather than assigning rule-making to an inert value |

Write different operations separately when they occur in one sentence:
`許可範囲を規定し、通知先を設定します` distinguishes an authorization rule
from a configured destination. Preserve capability: `条件を規定できます` must
not become an assertion that the conditions have been specified or enforced.
A rule can permit ignoring a notification; `無視できると仕様に規定されています`
must not become an obligation to ignore it. Recommendations and plans do not
become requirements merely because `規定` sounds more technical.

Do not reject `規定します` merely because `定めます` is understandable or
synonymous when the author prefers the former. Conversely, do not replace every
`定める` with `規定する`, ban valid plain wording, or add calculation,
configuration, checks, enforcement, approvals, or guarantees. Distinguish defining
a policy from enforcing it at runtime. Record the original, actual alternative,
and passage-specific reason; check related tables, figures, and alternative text
within the authorized scope. Existing sessions retain their saved criteria.

## Distinguish stopping, cancellation requests, and non-execution

Compare `止める` and its inflections with `停止する` when describing the
stopping of execution, a process, or request intake. Honor the author's
terminology preference, but identify the actual operation before choosing a
verb; these are contextual comparisons, not automatic replacements.

| Intended operation | Faithful comparison when supported |
| --- | --- |
| Stopping a running process or request intake | `プロセスを停止します`・`新規受付を停止します`; preserve the target, condition, and responsibility |
| Ending iteration or traversal | `上限に達したら反復を終了します`・`repoで探索を終了せず、上位ディレクトリも対象にします`; retain the limit and traversal scope |
| Requesting cancellation through an API | `Runの取消を要求する場合は、取消APIを呼び出します`; an API call or signal notification does not establish actual termination |
| Refusing an operation before execution | `実行前フックで要求を拒否できます`・`規則に従って送信を拒否します`; do not claim the ability to terminate a running process |
| Preventing unstarted subsequent work | `失敗時は後続を開始しません`; do not imply that subsequent work has already started |
| Disabling an operation through configuration | `Offでは、イベントの保持と通知を行いません`; do not turn non-execution into interruption of an active operation |
| Temporarily pausing with supported resumption | `処理を一時停止します`; use only when temporary suspension and resumption are established |

Preserve capability independently of terminology: `反復を止められます` can
become `反復を終了できます`, not an assertion that termination occurs.
Keep desire, requests, notifications, observed termination, and confirmation
separate. `停止を要求した後、処理の終了を確認します` must not become
`停止を要求すると処理が終了します`. A timeout or an unknown operation result
does not establish that external work has terminated. Retain unfinished work,
record preservation, conditions, negation, and the owner responsible for stopping
or closing resources; do not invent forceful termination or a restart facility.

Compare literal and idiomatic uses separately. `現実的な選択肢と受け止められて
いません` describes perception, not stopping; preserve it rather than changing
it to `停止されていません`. Do not ban every occurrence of `止める`, prescribe
one replacement for all contexts, or infer a resumable pause from stopping alone.
Record the original, faithful alternative, and passage-specific reason even when
no detector candidate is emitted. Synchronize related authorized tables, figures,
and alternative text separately from protected review scopes. Existing sessions
retain their saved criteria; these comparisons add no detector or replacement rule.

## Distinguish retention from inclusion, storage, and assignment

Compare `保持する` with the operation actually described. Identify the owner,
container, lifetime and processing stage. Input construction, storing a newly
obtained value, assigning an attribute, and keeping existing state are different
operations; do not replace them with one universal verb.

| Context | Faithful comparison when supported |
| --- | --- |
| Input construction | `成否の情報も入力へ保持します` → `成否の情報も入力に含めます`; supplying input does not establish storage across calls. |
| Contents of a summary | `すべての情報を要約に保持する必要はありません` → `すべての情報を要約に含める必要はありません`; preserve the necessity and negation. |
| Putting a retrieved value in a container | `取得した名前を結果用の変数に保持します` → `取得した名前を結果用の変数に格納します` when the insertion is the subject. |
| Assigning an identifier | `結果へ識別子を付与します` describes assignment; retaining an existing identifier is a different operation. |
| Adding information to a record | Compare `ノートに時刻を記録します` or `検索結果に出典を添えます` when recording or attachment is established. |
| Keeping original data or state | Retain `元の応答を保持し、次の呼び出しへ引き継ぎます` and `ロックを終了まで保持します`; inclusion or insertion alone loses continuity or ownership. |

Compare complete sentences, including retained uses. `入力に含めます` does not
mean `モデルへ送信します`; `格納します` does not establish file persistence.
A type declaring fields does not itself execute storage or assignment. Use
`付与` for an established attribute or identifier assignment, not as a blanket
replacement for input inclusion. Keep original values, duration, negation,
conditions, ownership and capability; do not add persistence, delete history,
or shorten the lifetime of a lock or snapshot. Keeping source facts does not
require keeping the word `保持`; record the actual alternative and reason.

## Distinguish representation from evidence and state indication

For `表す` and its inflections, identify whether the passage describes a
representation (notation, format, role or data model), contents, or a result
indicating a fact or state. Compare `示す` for the latter, honoring the author's
terminology preference without treating all uses of `表す` as unnatural.

| Context | Faithful comparison when supported |
| --- | --- |
| A result indicating failure | `失敗を表す結果` → `失敗を示す結果`; do not turn failure into an unknown outcome or vice versa. |
| Status information | `成否を表す情報` → `成否を示す情報` when information indicates success or failure. |
| What a record establishes | `要求の記録は、操作を要求したことを表します` → `要求の記録は、操作を要求したことを示します`; a request record alone does not establish execution. |
| Contents of a result | Compare `結果に含まれる情報` with `結果が表す情報` when describing included data rather than its interpretation. |
| Symbolic or structural representation | Retain `工程をノードで表します`, `引数をJSONで表します` and `利用者をUと表します`; `示す` is not required for notation or encoding. |

`裏付ける` may make a stronger evidence claim than `示す`. Use it only when the
source establishes that evidential role; do not upgrade a reported state into
proof, a correlation into causation, or request acceptance into successful work.
Preserve uncertainty, negation, conditions, actors and capability. Review the
whole paragraph and related authorized tables, figures and alternative text;
record each original, alternative and reason. These comparisons add no detector
or automatic replacement rule, do not change scoring or mechanical verification,
and do not measure AI proofreading quality. Existing sessions keep their saved
criteria; use a separate new session for updated guidance.

## Distinguish explanation, presentation, and state indication

For `示す` and its inflections, identify the sentence's role before choosing
its predicate. A content guide, a technical explanation, a displayed output,
a figure or example being presented, and a value indicating a state are different
uses. Read the complete paragraph and the referenced content when available;
these comparisons do not prescribe a blanket change to `説明します`.

| Role and wording to inspect | Faithful comparison when supported |
| --- | --- |
| Announcing explanatory content: `反復を継続・終了する条件を示します。` | Compare `反復を継続・終了する条件を説明します。` when the section explains those conditions; keep both continuation and termination. |
| Repeating one explanatory action: `保存方法を説明し、再開する条件を示します。` | Compare `保存方法と再開する条件を説明します。` when both are explanatory subjects. Preserve a meaningful order, separate artifact or distinct presentation purpose instead of merging merely to vary endings. |
| Naming an unspecified aid: `判断材料を示します。` | Name what is being selected or checked and which information supports that judgment. Use only criteria evidenced in the paragraph; do not invent a fixed decision rule. |
| Describing a screen: `画面には、使用を停止する範囲を示します。` | Compare `画面には、使用を停止する範囲を表示します。` when screen output is the operation. Do not assign display to a service that only returns data. |
| Describing a definition: `ツール定義は、引数の入力条件を示します。` | Compare `ツール定義には、引数の入力条件を記述します。` for authoring a definition, or `記述されています` for its existing contents. Preserve the distinction between writing a definition and enforcing it. |
| Recording scope: `計測した区間を示します。` | Compare `計測した区間を記録します。` when the passage specifies what to record; keep the measured interval and clock conditions. |
| Presenting an actual artifact: `次の表に、検査対象と確認内容を示します。` or `設定ファイルの例を示します。` | Retain these when the table or following example actually presents that content. `説明します` would shift from presenting the artifact to describing it. |
| Indicating a state: `結果は、返答を記録したことを示します。` | Retain the indication when that is the result's meaning. Compare contents wording such as `結果に記録の成否が含まれます` only when included data is the subject; recorded acceptance does not establish successful execution. |
| Leaving the indicated target implicit: `結果が継続を示します。` | Compare `一回分の処理結果が、次の回へ進むことを示します。` when that is the continuation being described. Keeping `示します` can be the clearest revision. |

In the middle or at the end of a technical explanation, compare stating the
relationship directly instead of promising another explanation. For example,
`プロセス内の順序制御で防ぐ競合と、外部からの変更に備えて検査する競合を示します。`
can become `プロセス内の競合は、操作の順序を制御して防ぎます。外部からの変更による競合には、検査で確認する状態と検査のタイミングを明確にして備えます。`
when the surrounding paragraph establishes both methods. Preserve the scope of
the controlled operations; neither ordering nor checking guarantees prevention
of every external change. If the original also names the inspected state and
timing, retain them in the revised paragraph.

Compare the full paragraph before replacing the verb. Resolve vague subjects,
comparison axes, repeated guidance and the relationship between methods and
outcomes; exchanging `示します` for `説明します` alone may leave those problems
unchanged. Keep valid figure/table introductions and state indications after a
specific comparison, not because all occurrences must share one ending. Check
related authorized tables, figures and alternative text without inventing
actors, processing, evidence, guarantees or successful checks.

These criteria add no detector, automatic replacement or scoring change.
Existing sessions retain their saved criteria; mechanical verification remains
separate from meaning review and does not measure AI proofreading quality.

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

### Distinguish operations from responsibility

Treat `行う` and its inflections as advisory cues, not banned wording. Compare
whether the sentence describes an actual operation, its purpose or order, or
an implementation's responsibility. Read neighboring sentences and table roles.

| Context | Faithful alternative to compare |
| --- | --- |
| 入力の検証は、利用者への確認と実行より前に行います。 | 利用者への確認と実行より前に、入力を検証します。 preserves both ordering conditions. |
| 次のコード生成を行います。 | 次のコードを生成します。 states the generation operation directly. |
| settings.tsは設定の読み込みと検証を行います。 in a file-responsibility table | settings.tsは設定の読み込みと検証を担当します。 names the file's role without adding execution timing. |
| トークンの生成はモデルが行い、ファイルの読み取りはエージェントが行います。 | トークンの生成はモデルが担当し、ファイルの読み取りはエージェントが担当します。 preserves the division of responsibility. |

Use `担当します` when responsibility is the point; direct verbs such as
`検証します`, `生成します`, `変換します`, or `修正します` when explaining
actual behavior. Do not replace every `行います` with `担当します` or a fixed
synonym. Retain accurate established expressions when the comparison offers
no improvement. Preserve purpose, conditions, negation, capability, actors and
processing stage; `検証を行えます` must not become mandatory or automatic
`検証します`. A runtime validation must not become only a developer's test.
Record the original, faithful alternative and passage-specific comparison.

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

## Distinguish receiving, returning, and their actual operations

Treat `受け取る` and `返す` as contextual review cues, not banned verbs.
Identify the actor, source, destination, data, condition, and processing stage
before choosing a more specific expression. Compare a faithful full sentence;
a blanket change to `取得する`, `受信する`, or `返却する` is not a policy.

| Wording to inspect | Operation-specific comparison |
| --- | --- |
| 利用者から依頼を受け取る | 依頼を受け付ける for request intake; do not imply authorization, successful admission, or execution merely from receipt |
| 応答イベントを受け取る | 応答イベントを受信する when communication or a response stream is established; do not invent a network transport for a local callback |
| 関数が設定を受け取る | 設定を引数として受け取る when describing arguments; distinguish constructor configuration, callback arguments, and external input |
| 検索結果・ファイル内容を受け取る | 取得する・読み込む when retrieval or reading is the operation; preserve pushed events and unsolicited delivery rather than making every receipt an active lookup |
| モデルが操作要求を返す | モデルが操作要求を生成する when the model's generation is the subject; an API or adapter returning that response is a different stage |
| 応答本文を標準出力へ返す | 応答本文を標準出力へ出力する; stdout writes and a function's return value are different operations |
| 実行側が結果をモデルへ返す | 実行側が結果をモデルの入力へ追加する when input assembly is established; otherwise describe result delivery without assigning assembly to the tool or execution environment |
| 利用者が判断を返す | 利用者が判断を伝える when communicating a decision; keep its recipient, timing, approval condition, and capability |
| 実行関数が例外を返す・呼び出し側が例外を受け取る | 例外を送出する・捕捉する only when throw/catch or equivalent behavior is established; preserve returned error values as return values |

Keep `値を返す`, `Promiseを返す`, and an API returning a response when they
accurately describe a return value or request/response relationship. Compare
`戻り値として返却する` before retaining the plain verb; a longer nominalized
synonym alone does not improve an already precise return operation. Where the
input/output distinction is the subject, naming `引数` and `戻り値` may be clearer
than repeating receiving and returning verbs.

Do not move responsibility while making the wording specific. An execution
environment returning stdout or an error does not by itself assemble model
input. A service returning a display message does not necessarily display it;
a UI may own that step. A cancellation signal passed as an argument and its
later cancellation notification are separate events: changing receiving wording
must not move stopping to argument delivery. Preserve negation, modality,
conditions, data formats, and ownership; obtain missing implementation evidence
rather than inventing a receiver, transport, exception, or approval step.

## Distinguish input, transmission, delegation, inheritance, and handoff

Compare `渡す`, `受け渡す`, `受け渡し` and related inflections with the actual
operation. Identify the actor, source, destination, value and timing before
choosing a full-sentence alternative; understandable everyday wording alone
is not a reason to skip comparison.

| Context | Operation-specific comparison |
| --- | --- |
| Constructing model input | `ツール結果をモデル入力に追加します` describes input construction; use `送信します` only for the actual model API request. |
| A local function call | `取消シグナルを引数として指定します` describes an argument; it does not establish transmission or a later cancellation notification. |
| Configuration | `接続先を設定します` describes configuration; a declaration can specify its purpose without claiming that the type executes configuration. |
| Event delivery | `購読者にイベントを通知します` names notification; transmission does not establish reception, processing, or acknowledgment. |
| Delegating work | `子エージェントへ処理を委譲します` describes responsibility for execution; supplying a value alone does not establish delegation. |
| Continuing with existing history or state | `再開時に会話履歴を引き継ぎます` describes continuity; do not add persistence, full history, ownership transfer, or automatic resumption. |
| Output used by a later stage | `工程の出力を次の工程の入力として指定します` names the input/output relationship; do not infer shared mutable state. |
| Delivering an artifact or request to a next owner | Compare `成果物を後続の担当へ引き渡します` when delivery is the subject; do not imply ownership release, acceptance, or completed downstream work. |
| Cooperation between components | Compare `連携します` only when cooperation is the subject; name input, transmission or notification when describing a particular data operation. |
| A general or bidirectional interface contract | Compare a concrete operation before retaining `データの受け渡し`; retain a general contract when a one-way verb would narrow its scope. |

Preserve capability, conditions, negation, recipients, responsibility and order.
In particular, `送信しません` must not become `受信しません`, and `入力できます`
must not become an assertion that input occurs. `引き継ぐ` and `引き渡す` are
contextual alternatives, not universal technical synonyms. Keep code identifiers,
reference IDs and URLs. Check authorized tables, figures and alternative text
against the revised prose, recording protected or out-of-scope proposals separately.
Record the original, actual alternative and reason for each revise or keep decision.
These advisory comparisons add no detector or automatic replacement rule. Saved
sessions retain their original criteria; mechanical verification keeps
`meaning_verified: false`. AI proofreading improvement has not been measured.

## Distinguish communication responses from function returns

Classify the operation before changing `返す`: responding to a communication
request, generating model output, returning an internal value, or reporting
failure. Honor the author's terminology preference while preserving the actor,
recipient, data and timing. Request/response wording need not replace an accurate
function return, and ordinary return wording is not inherently unsuitable for
technical prose.

| Wording to inspect | Operation-specific comparison |
| --- | --- |
| HTTPは受付の結果を202で返します | `HTTPでは、受付結果をステータスコード202で応答します` names the HTTP response and status code; do not imply that accepted work has completed |
| ACPでは停止理由を返します | `ACPでは、停止理由を含む応答を元の要求に対して送信します` distinguishes the final response from intermediate notifications; retain the documented completion condition |
| MCPの接続先が結果を返します | `MCPの接続先が処理を実行し、その結果を応答として送信します` names the remote response; do not assign that transport operation to a local tool function or adapter |
| 接続先が返したトークン使用量 | `接続先の応答に含まれるトークン使用量` identifies response data; preserve missing values as unmeasured, without treating an absent field as an unreceived response |

For `モデルがデータを返します`, compare `モデルがデータを生成します`
when generation is the subject. An adapter converting that output and a function
returning `Message`, `ToolResult`, `RunHandle` or `Promise` are different stages.
For an internal return, compare an explicit recipient or `戻り値` when useful,
without adding communication, display or a model invocation. Do not replace every
`返す` with `応答する` or `応答として送信する` merely to vary sentence endings.

For `エラーを返します`, check whether the implementation returns an error value,
throws an exception, or rejects a Promise before choosing `例外を送出します`
or describing rejection. Preserve a normal failure result as a return value;
never infer throw, rejection or a received error response from the word error alone.
Book-specific choices between equally accurate response expressions remain with
the book. These examples are advisory comparisons, not replacement rules or
semantic verification.

## Distinguish arrival wording by the actual operation

Treat `届く` as an advisory cue, not a banned verb or a replacement instruction.
Identify the actor, source, destination, data and timing before comparing a full
sentence. Receiving a notification, passing an input, obtaining a call result,
settling an operation and finding a missing report are different stages.

| Wording to inspect | Operation-specific comparison |
| --- | --- |
| 進捗が届かない | 進捗通知を受信しない when notification reception is the subject; preserve optional notifications and the inability to infer stopping or failure |
| 外部から届くJSON | 外部から入力されるJSON when runtime input validation is the subject; do not invent network reception for a local value |
| parseで届いた値を検査する | parseで入力値を検査する when the value is a function argument; preserve validation and conversion responsibilities |
| 停止後に届いた回答 | 停止後に取得したモデル応答 when describing the result of a model call; preserve the stop check and whether the response is added to the conversation |
| 遅れて届く結果 | 遅れて確定する結果 only when pending operations settle later; reception alone does not establish settlement or completion of recording |
| 報告が届かなかった枠 | 対応する試行の報告がない枠 when comparison searches supplied records; do not infer an unreceived message, an unsubmitted report or an unexecuted trial |
| 後から届いた証拠 | 後から追加された証拠 when evidence is added to a report; distinguish evidence addition from communication or new discovery |

Do not replace every arrival with `受信する`. Preserve unsolicited events instead
of turning them into active retrieval, and do not turn transmission into receipt.
A cancellation notification arriving after a response and a signal passed as an
argument are different events. Keep missing reports distinct from confirmed
non-execution and retain planned trial counts. Literal physical arrival can remain;
compare a faithful alternative before retaining technical arrival wording.
These criteria do not authorize automatic replacement. Old sessions retain their
saved rules and criteria; verification remains mechanical, with meaning_verified
false. Effectiveness of AI proofreading has not been measured by these examples.

## Distinguish classification, responsibility sharing, branching, and partitioning

Compare `分かれます` and related inflections with the relationship actually
explained. Types, purposes, responsibilities, execution paths, and partitions
are different claims; do not replace them all with `分類できます`.

| Context | Faithful comparison |
| --- | --- |
| Organizing tools by purpose | `組み込みツールは、用途に応じて検索、読み込み、変更、コマンド実行に分類できます` names the classification axis without claiming a runtime classifier. |
| An established category definition | `仕様では、要求を読み込みと変更に分類しています` describes a defined classification; do not weaken it to a possible reader classification. |
| Assignment of responsibilities | `実行と採点、記録の検査、結果の比較は、次の担当が分担します` names responsibility sharing; retain each owner and operation. |
| Execution-path branching | `判定処理が両方を返すと、処理が二つの工程へ分岐します` retains the condition and both destinations. |
| Partitioning conversation content | `要約対象と原文で保持する範囲をターンの区切りで分割します` names the two ranges and split boundary. |
| Different loading routes | `ユーザー全体の指示は、プロジェクトの指示とは異なる経路で読み込みます` states the route relationship, not a category. |
| A table of checks and targets | `次の表に、検査対象と各検査で確認する内容を示します` introduces the correspondence without asserting successful checks. |

State the classification axis: purpose, type, or response after failure, for
example. Reader classification (`分類できます`) does not establish that a
program classifies values. Retain actual classification behavior, a defined
category scheme, and available classification capability separately. Terms such
as `分類されます` or `次の種類があります` must match that sentence's role;
modality alone does not establish a runtime actor.

Do not turn responsibility sharing into classification or independence. Do not
turn branching into a reader capability, exclusive choice, or guaranteed parallel
execution. Preserve both destinations when both are selected, branch conditions,
counts, order, and join conditions. Partitioning is a boundary within one object;
it does not imply duplication, deletion, or classification of that object.
Name actual route differences without inventing isolation. Table introductions
should name their targets and correspondence rather than promise successful
inspection. Retain literal separation or other established uses after a concrete
comparison when classification, branching, or partitioning would misstate them.

These comparisons add no detector or automatic replacement rule. Existing
sessions retain their saved criteria; new sessions capture the updated criteria.
Manual comparison labels and prompt-delivery tests do not measure AI proofreading
accuracy or establish semantic correctness.

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

Keep completed changes, current behavior or policy, and future plans distinct.
`上限を3回へ変更しました` reports a completed change; `最大3回再送します`
can describe current behavior; `変更する予定です` describes a plan. Do not
change tense merely to vary endings. Current behavior alone does not establish
that it was introduced or changed in this revision. Report a change only when
the source establishes it; do not invent an earlier state or improvement.

Preserve plain or polite style unless the author requests a change or the book's
explicit style requirements call for one. A technical topic alone does not
require polite style. Resolve unintended style mixing separately from each
sentence's function; changing `する` to `します` must not change advice into
an asserted operation. Do not vary endings just to make these functions uniform.

## Compare terminology independently of modality

Preserve whether a sentence describes a capability, actual behavior, a condition,
or an obligation while independently choosing the most accurate wording.
`選べます → 選択できます` preserves capability; it is not the same change as
`選べます → 選びます`. When the operation is technical selection, prefer
`選択できます`, especially when the author requests technical terminology.
An alternative need not change the facts to improve terminological consistency.
"Same meaning" and "the referent is clear" alone do not justify keep. An explicit
terminology preference takes precedence over an otherwise acceptable plain synonym.

Compare the strongest faithful alternative, not an unsupported or shortened one
that is easy to reject. Rejecting `物理的に隔離する` does not justify keeping
`分ける` when `別の処理として実装する` explains the supported operation.
Do not remove conditions or information from an alternative and then use that
loss as the reason to retain the original. Compare full sentences or paragraphs
with the same facts, modality and author requirements.

| Wording | Operation-specific comparison |
| --- | --- |
| `次の操作を選べます` | `次の操作を選択できます` preserves the available choice and names the selection operation. |
| `データを複数の部分に分けます` | `データを分割します` describes partitioning one object; do not use it for every separation. |
| `許可判断と出力検査を分けています` | Identify both purposes and timings: `操作前の許可判定と、モデル入力前の出力検査を別の処理として実装しています`. Do not invent physical isolation. |
| `両者の実装言語を分けられます` | `呼び出し元を、実行基盤とは異なる言語で実装できます` states language independence. Languages themselves are not partitioned. |
| `固定した処理へ行動選択を組み込めます` | Name the workflow stage, the actor selecting operations, the input used for selection, and the limits on delegated operations. A vague `統合できます` or `実装できます` alone is not an improvement. |

`組み込む` is not a banned word. Library embedding can be an established operation
when the host application, API and integration method are specified. Retain a
plain verb only after comparing the faithful alternative and explaining a real
loss or a context-specific readability benefit consistent with author preferences.
A failed candidate comparison is pending, not evidence that the original is best.

## Review sentence endings by their role

Read the complete sentence and neighboring sentences before judging its ending.
First identify whether it announces the section's scope, describes an actual
operation, offers a capability, gives a checking procedure, or reports history
or a future expectation. Then name its actor, object, condition, and consequence.
Revise only when a more direct explanation preserves those relationships;
otherwise compare the wording independently of its sentence role before retaining it.

| Ending and context | Decision to consider |
| --- | --- |
| `注目します`, `明らかにします`, `確認します`, or `たどります` in an introduction | Keep useful subject and reading-order guidance, but separately assess its actor and predicate. A useful sequence alone does not justify retaining `確認します`; distinguish content guidance from an actual exercise or check and honor the author's explanatory voice. If it only repeats an announcement, state the supported subject directly without inventing its answer. |
| `戻します` or `組み立てます` in an operation description | Keep it when the transferred result, recipient, or constructed input is clear. Do not replace it with a noun or jargon merely to vary the ending. |
| `使えます`, `組み込めます`, `選べます`, or `作れます` | Preserve the available option and its conditions, not necessarily the original verb. Compare an equally potential technical expression or a concrete explanation; do not use the risks of `使います` or `選びます` to reject `適用できます` or `選択できます`. |
| `分かりません` | Identify whether the missing evidence prevents judgment, confirmation, or identification. Use `判断できません` or `確認できません` only when that operation fits; preserve what remains unknown. |
| `別です` or `同じではありません` | Name the compared objects and the property, purpose, or evidence that differs. Distinguish definite non-identity from insufficient evidence to infer a result. |
| `確認します` or `調べます` in a procedure | Keep an actual check, including its target, condition, and timing. Do not turn it into a capability or a claim that the check succeeded. |
| `移りました` or another past ending | Keep a supported historical transition distinct from current behavior or a future plan. |

For example, `会話形式の画面だけでは、実行できる操作の範囲は分かりません`
can become `会話形式の画面だけでは、実行できる操作の範囲を判断できません`.
Both retain the missing evidence and the same judgment target. By contrast,
`処理結果が分かりません` cannot become `処理は失敗しました`: an unknown
outcome is not an established failure.

`利用者は候補Aと候補Bから選べます` states an available choice;
`利用者は候補Aと候補Bから選択できます` retains that choice while using technical
selection wording. Compare this faithful alternative before keeping the plain verb.
`利用者は候補Aと候補Bから選びます` would instead assert that selection occurs. Retain
the verb `戻します` in `実行側はツール結果をモデルへ戻します` when it
accurately describes the transfer; assess `実行側` separately using the actor
criteria above. `実行結果のフィードバック` would lose the sentence's actor
and predicate.

Do not mechanically convert `別です` to `とは限りません`. For example,
`AはJSONを、BはCSVを受け付けます。両者の入力形式は別です` establishes a
definite difference. Changing the last sentence to `両者の入力形式が同じとは
限りません` weakens that claim. When an event merely fails to establish another
result, such as completion failing to establish test success, state that
inference limit while retaining the original scope and strength of negation.

Heading form and running-prose grammar are separate decisions. A project's
noun-phrase heading policy does not authorize nominalizing body sentences or
removing their predicates. A proposed ending alone cannot supply new subjects,
mechanisms, constraints, or guarantees; obtain those from the actual passage
and its evidence. Record meaningful keep decisions as well as revisions.

## Separate explanatory guidance from actual checks

Classify the complete sentence before choosing its verb: content guidance,
an actual checking procedure, runtime behavior, or a reader's learning objective.
The book explaining a subject, a reader checking evidence, and a program
validating state are different actors and actions. Read the whole paragraph and
neighboring sentences, including inflections such as `確認し`, before judging an
ending. Do not mix the book's explanation with the reader's `理解します` as if
the book performed that learning. Present a learning objective explicitly when
that is the sentence's purpose; do not mechanically rewrite every objective.

For content guidance, compare the whole paragraph, not only its last verb.
Adding `読者は` to `理解します`, or changing it to `理解できます`, does not by
itself repair a switch from the book's explanation to a reader outcome. State
what the book explains, presents or compares, and consolidate repeated guidance
without losing subjects, conditions or reading order. Do not assert that reading
necessarily produces understanding.

For a learning objective, identify the reader and what the knowledge is meant
to help them explain, distinguish or decide. Prefer a concrete goal over generic
`設計を理解することが目的です`, using only supported targets and conditions.
Express an intended objective rather than a guaranteed achievement; do not invent
an exercise or a decision merely to make it concrete. Retain actual learning
activities, reader-interest guides and research about understanding when that is
their subject. These criteria do not ban `理解`, `学ぶ` or `把握`.

When the author requests explanatory narration, compare `説明します`,
`示します`, or `比較します` for content guidance. For example, a chapter guide
such as `本章では、依頼の受付と結果の返却を確認します` can become
`本章では、依頼の受付と結果の返却を説明します`. A clear subject or useful
reading sequence does not resolve an ambiguous checking actor or justify keep.
Apply the book's voice rather than banning all uses of `確認` in introductions.
An actual exercise such as `この演習では、利用者が接続設定を確認します`
can retain its checking verb and explicit actor.

For genuine checks, identify the supported actor, target, conditions, and timing
from the passage. Compare equally faithful wording such as `照合します`,
`検査します`, `参照します`, or an explicit actor plus `確認します`; choose a
more specific operation only when evidence establishes it. Use preceding
sentences or table column roles when they already identify the actor, rather
than repeating subjects mechanically. Missing actor evidence stays unresolved;
do not invent automatic execution or assign responsibility from the book's topic.
Do not turn a program's runtime check into only a developer's test, a connection
owner's shutdown responsibility into a reader's observation, or an unknown
result into confirmed completion. Naming an actor adds no guarantee.

Choose `説明` and `解説` by their purpose and the author's terminology policy.
Content guidance can use `説明`, while in-depth background or design discussion
can use `解説`; do not make that distinction a universal replacement rule.
Preserve tool or Skill description data, formal titles, quotations, and code
identifiers. Compare the actual paragraph-level alternative before keeping it.

## Distinguish direct negation, partial negation, and inference limits

For `わけではありません`, `わけではなく`, and `わけではない`, compare
negating the actual operation directly. Identify the actor, target, condition,
and scope first; these expressions are review cues, not banned wording.

| Original wording | Faithful comparison |
| --- | --- |
| ツール定義を送信しても、実行関数のコードがモデル側へ送られるわけではありません。 | ツール定義を送信しても、実行関数のコードはモデル側へ送信されません。 |
| 入力にない読み取り結果を根拠として使えるわけではありません。 | 入力にない読み取り結果を根拠として使えません。 Preserve inability, not a claim that the actor chooses not to use it. |
| 定義を送信するだけでファイルが読み込まれるわけではありません。 | 定義を送信するだけではファイルは読み込まれません。 Keep the insufficient condition. |
| トークンは一文字と常に一致するわけではなく、語の一部になることもあります。 | トークンは一文字と必ずしも一致せず、語の一部になることもあります。 |
| 保存した会話を開き直しても、以前の作業環境がすべて復元されるわけではありません。 | 保存した会話を開き直しても、以前の作業環境のすべては復元されません。 |
| 応答を観測していないため、処理が終了したとは判断できません。 | Retain the inference limit; absence of observation does not establish that the operation never finishes. |

Distinguish an operation that does not occur, an unavailable capability, a
condition that is insufficient, and a conclusion that evidence does not support.
Do not turn `できません` into `しません`, or missing evidence into a claim of
non-implementation, impossibility, failure, or completion. Preserve negation scope
and strength: `常に`, `すべて`, `だけで`, `自動的に`, and `そのまま` can change
what is denied. Use `必ずしも`, `すべては`, or `とは限りません` when needed for
partial negation; never turn partial negation into total denial. A known operation
must not be weakened into an uncertain inference merely to sound cautious.
Keep actors, responsibility, timing, and supported conditions. Do not introduce
an inspection, enforcement mechanism, transport, or guarantee to justify a
stronger denial. Compare complete paragraphs and record the actual alternative
and reason, including a necessary retained inference limit.

## Distinguish identification from conceptual separation

Compare `区別できます` and related forms with the actual capability. Use
`判別できます` when evidence such as an ID, origin, or recorded content lets
someone tell which object or state is involved. Use `識別` for identity assigned
or resolved through an identifier, `判定` for success or another outcome judged
against a criterion, and `個別に確認` when two stages or results are checked
separately. These are contextual comparisons, not mandatory substitutions.

| Wording to inspect | Faithful alternative when supported |
| --- | --- |
| 同じツールへの複数の要求も、呼び出しIDで区別できます。 | 同じツールへの複数の要求も、呼び出しIDで判別できます。 Preserve the ID as evidence and the capability. |
| フォルダ名だけでは、同じフォルダを使う二つの作業を区別できません。 | フォルダ名だけでは、同じフォルダを使う二つの作業を識別できません。 Describe identity resolution without inventing a new identifier. |
| 本文の有無と処理の成否を区別できます。 | 本文の有無とは別に、処理の成否を判定できます。 Use this only when the result carries the success/error evidence. |
| 受付応答と完了応答から、記録の受付と書き込み完了を区別できます。 | 受付応答と完了応答から、記録の受付と書き込み完了を個別に確認できます。 Both stages may occur; do not turn them into exclusive states. |

Retain `区別` when separating concepts, responsibilities, or contributing
influences is the actual purpose. For example, `条件をそろえなければ、手順の
変更による効果と課題の難しさを区別できません` concerns separation of effects,
not identification of an object. Compare the proposed alternative and record why
it preserves or changes that purpose. An author preference for identification
wording does not authorize replacing every conceptual distinction.
Preserve who can judge what, the evidence used, uncertainty, negation and timing.
Do not turn `判別できます` into asserted automatic identification, add inspection
or classification, or claim that an unknown outcome is a failure. Keep differing
response stages and inference limits explicit. Record the source, alternative,
and passage-specific reason even when a detector does not emit a candidate.

## Compare directory hierarchy terms with concrete locations

In directory descriptions, translations of ancestor, descendant, child and
grandchild can produce `祖先ディレクトリ`, `子孫ディレクトリ`, `子` and
`孫ディレクトリ`. Compare natural location-based wording even when the original
referent is recoverable; these are contextual alternatives, not banned words.

| Original wording | Faithful comparison when supported |
| --- | --- |
| ファイルシステムのルートまで祖先ディレクトリをたどります。 | ファイルシステムのルートまで上位ディレクトリをたどります。 Preserve the endpoint and traversal direction. |
| 子孫ディレクトリを再帰的に探索します。 | 下位ディレクトリを再帰的に探索します。 Retain recursion and whether the starting directory is included. |
| 孫ディレクトリだけを対象にします。 | 2階層下のディレクトリだけを対象にします。 Bare 下位ディレクトリ would lose the exact depth and the restriction. |
| 子の設定で省略した値を親の設定から引き継ぎます。 | 下位ディレクトリの設定で省略した値を上位ディレクトリの設定から引き継ぎます。 Name the locations rather than an unspecified priority rank. |
| 親から子へ指示を並べます。 | 上位から下位のディレクトリの順に指示を並べます。 Preserve application order separately from discovery order. |

Keep `親ディレクトリ` or `直上のディレクトリ` when exactly one level above is
intended; compare `子ディレクトリ` with `直下のディレクトリ` when exactly one
level below matters. Do not broaden direct children to all descendants or
grandchildren to every lower level. Preserve exclusions, depth limits, roots,
starting locations, traversal order, inheritance and override conditions.
Do not infer recursion or a configuration priority merely from hierarchy.

Do not mechanically change `子プロセス`, `子エージェント`, tree nodes, conversation
record parent IDs, span parent-child relationships, or biological ancestry.
Those describe different relationships; compare their established terminology
in context. Preserve code identifiers such as parent, child and parent-model.
Synchronize authorized headings, tables, diagrams and alternative text with the
prose, recording each original, alternative and reason in the existing review
record. Detector hints do not determine which alternative to adopt.

## Make relationships explicit

Treat `区別します` and related forms as contextual review cues, not banned
words. Naming two objects alone does not explain their difference. Identify the
property, purpose, processing stage, recorded state, or decision condition that
differs, and compare a faithful sentence that states it directly. For content
guidance, name the comparison axis; for runtime behavior, state what the actor
processes, records, or decides. Do not merely substitute `分けます` or `異なります`.

| Wording to inspect | Concrete comparison when supported by context |
| --- | --- |
| 短い情報と詳細な記録を区別します | 短い案内を毎回の入力に含め、詳細な記録は必要なときだけ読み込みます。 State the different loading conditions. |
| 作業規則と許可規則を区別します | 作業規則はモデルの操作選択に用い、許可規則は選択された操作を実行してよいかの判定に用います。 State each rule's purpose. |
| 要求IDとprogressTokenを区別します | 取消通知は要求IDで対象を指定し、進捗通知はprogressTokenで途中経過を元の要求に対応づけます。 State each identifier's use. |
| 合格、不合格、証拠不足を区別します | 評価結果を合格、不合格、証拠不足に分類して記録します。 Describe classification only when recording those states is established. |
| 停止要求の受付と処理の終了を区別します | 停止要求を受け付けても、起動済みの処理が終了したとは判断できません。 State the limit of the inference rather than inventing an additional check. |

Retain an accurate distinction when its criterion and consequence are already
explicit, after comparing the direct alternative. Do not invent separate storage,
physical isolation, automatic classification, display, inspection, or approval
steps to make the wording concrete. Preserve the actors, conditions, modality,
negation, and technical scope. Read neighboring sentences and merge a repeated
explanation when the revision would otherwise state the same difference twice.
Record the original, concrete alternative, and passage-specific comparison.
Frequency alone does not establish a defect or authorize automatic replacement.


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

## Distinguish replacement from interpretation and permitted use

Compare `置き換えません` and related forms with what the passage actually denies.
Compare direct predicates for interpretation and evidence limits, including
`確認できません`, `判断できません`, `評価できません`, and `証拠にはなりません`.
Retain `みなしません` when it specifies a discretionary interpretation rule,
and use `扱えません` when it cannot serve a specified evaluation or check. Preserve
actual value, history, or implementation replacement when that is the operation.
These are contextual comparisons, not automatic substitution instructions.

| Original wording | Faithful comparison when supported |
| --- | --- |
| 画面を表示できなかったことを、利用者が承認したことに置き換えません。 | 画面を表示できなかったことを、利用者の承認とはみなしません。 Retain the rule against interpreting display failure as approval. |
| MCPの進捗通知は、この終了確認を置き換えません。 | MCPの進捗通知は、処理が終了したことの確認としては扱えません。 State the notice's use limit, not that the operation never finishes. |
| 固定応答でプログラムの分岐が通った結果を、モデルの判断品質の評価に置き換えません。 | 固定応答でプログラムの分岐が通った結果だけでは、モデルの判断品質は評価できません。 Keep fixed-response testing distinct from actual-model evaluation. |
| トークン数が取得できない場合は、未取得とし、使用量がゼロだったという測定値へ置き換えません。 | トークン数が取得できない場合は、未取得とし、使用量がゼロだったかは判断できません。 Preserve the missing record and the limit on inferring zero usage. |
| 印象評価でコードの実行可否やテストの成否の検査を置き換えません。 | 印象評価は、コードの実行可否やテストの成否を確かめる検査としては扱えません。 Preserve the need for the actual checks. |
| 要約だけで会話全体を置き換えず、保持範囲を組み合わせる方式です。 | Retain the actual history-replacement description: treating the summary as the whole conversation is a different claim. |

Compare `とはみなしません` and `とみなしません` with direct wording in the
complete paragraph. Prefer a faithful direct predicate when it clarifies what
cannot be confirmed, judged or evaluated, or what does not constitute evidence.
These expressions are review cues, not forbidden words. Examples:

| Original wording | Faithful comparison when supported |
| --- | --- |
| 実行結果が不明な操作は先に調査し、要約によって不明な状態を解消したとはみなしません。 | 実行結果が不明な操作は先に調査します。要約だけでは、操作の実行結果は確認できません。 Preserve the prior investigation and the summary-only limit. |
| 収集されなかった観測情報を、操作が行われなかった証拠とみなしません。 | 観測情報の未収集は、操作が行われなかった証拠にはなりません。 Missing observation does not prove a non-event. |
| この運用規則では、無回答を承認とはみなしません。 | Retain the explicit interpretation policy unless an equally faithful direct formulation improves it; do not rewrite it as an inability to determine approval. |

Do not turn an inference limit into a denial of the underlying event, a
nonzero measurement, or an unconditional inability to evaluate. Retain `だけでは`
and other conditions. A policy not to count something as approval differs from
insufficient evidence to determine whether approval occurred. Do not add automatic
classification, checks or enforcement. Honor explicit author preferences by
comparing the actual faithful alternative rather than retaining an indirect phrase
only because its meaning is recoverable. Record each comparison and disposition.

Distinguish a discretionary rule (`みなしません`) from an unavailable use
(`扱えません`) and from a data transformation that does or does not occur.
Do not change inability into a choice not to act, missing evidence into failure
or zero usage, or an actual replacement into an interpretation. Keep the actor,
target, conditions, negation strength, timing, and responsibility. Do not invent
an automatic check, classification, enforcement mechanism, or guarantee.
Compare the complete paragraph and record the actual alternative and reason;
an understandable original alone is not a reason to retain vague replacement
wording. Existing sessions retain their saved criteria.

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
- Preserve the comparison axis as well as the alternatives and rank. Calling
  a problem the most important does not establish that it is the most frequent
  or easiest to overlook. Keep an unresolved comparison unresolved.
- Distinguish the time an event occurred from when someone observed, learned,
  or reported it. `9月2日に、9月1日に障害が発生したと聞きました` must not
  become `9月2日に障害が発生しました`. Preserve attribution and distinguish
  reported evidence from direct observation.

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

## Keep source uncertainty separate from editorial questions

Retain an actual undecided or under-investigation state in the reader-facing
body, including its time and scope. A reviewer not understanding a phrase does
not establish that the author or implementation is uncertain. Do not add
`要確認`, questions, or editorial explanations to the manuscript; put reviewer
questions and proposed alternatives in the separate review report. Report missing
evidence without weakening an established operation or inventing a new actor.

When a state description is unclear but its associated action is known, preserve
both the source wording's scope and the known action in the body. For example,
`破綻したメッセージは隔離します` does not establish a signature failure, nor
does uncertainty about `破綻` authorize deleting the isolation operation. Retain
the term when a faithful alternative cannot be established and record the exact
question separately. Quoting the operation only in a confirmation item does not
preserve it in the manuscript. Keep source-provided `未定` or `調査中` statements;
do not turn them into reviewer notes or omit them as editing clutter.

These instructions do not authorize edits to protected content or new manuscript
annotations. Preserve the selected review scope and keep unreviewed items pending.

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
| 木 | ツリー構造・ツリー when referring to the data structure; preserve formal names such as モンテカルロ木探索 and literal or mathematical uses |
| 安全余白 | 安全マージン when naming the reserved allowance for estimation or counting differences; retain its unit, value, and calculation |
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

### Introduce figures and tables by their explanatory role

When a figure or table itself presents a structure, relationship or sequence,
compare a sentence with the figure or table as subject and a predicate describing
its contents. For example, compare `次の図では依頼がSessionから反復処理へ渡り、モデル要求がaiへ進む関係を示します。`
with `次の図は、依頼がSessionから反復処理へ渡り、モデル要求がaiへ進む関係を示しています。`.
The latter makes the subject and its relationship to the contents explicit;
it does not authorize changing the depicted operations or their actors.

Choose introductions by their role rather than forcing one sentence template:

| Role | Contextual comparison |
| --- | --- |
| Describe a figure's contents | `次の図は、依頼の受付から結果の保存までの処理順を示しています。` is appropriate only when those endpoints and that order appear in the figure. |
| Describe a table's comparison | Compare `次の表では設定値と適用範囲を示します。` with `次の表は、設定値とその適用範囲を示しています。` when the table presents that correspondence. |
| Define notation within a figure | Retain natural wording such as `図では、利用者をU、応答をRと表します。`; this explains notation rather than making the figure the actor. |
| Guide a comparison made by the text | `次の表では、3つの方式を比較します。` can naturally introduce the author's comparison; compare the surrounding paragraph before revising it. |
| Identify the kind of diagram | `次の図は、実行状態の遷移図です。` can be sufficient when the surrounding text explains its purpose and limits. |

Do not mechanically replace every `図では`, `表では` or `示します`. Compare
neighboring prose, the actual figure or table, captions and alternative text when
available. Preserve labels, conditions, omissions, reference IDs and the book's
reference convention. If the referenced content is unavailable, record the limit
and leave unsupported content claims unresolved.

An author-supplied good/bad example can establish a quality or tone benchmark
for the full assigned manuscript. Follow the declared assignment: a whole-text
proofreading request still covers grammar, subject-predicate agreement, modifiers,
terminology, sentence endings and redundancy in passages without similar wording
or detector candidates. A focused request remains focused. Apply the demonstrated
improvement by context rather than copying its wording into every passage.

File paths and type names belong where they help explain a specific operation;
avoid a list of identifiers before the reader knows their roles. Bibliographic
and implementation-file descriptions introduce the referenced material, rather
than narrating the author's research activity.

## Compare processing phases with timing and progressive disclosure

When the author proposes `段階 → フェーズ`, compare the actual processing or
work division with the same actor, conditions, order and scope. Use `フェーズ`
for named execution states such as `phase`, extraction and consolidation, or
preparation, execution and evaluation divisions when it matches the described
operation and the author's terminology preference. Do not require a factual
error to honor that preference; synonymy alone is not a keep reason.

| Source wording | Contextual comparison |
| --- | --- |
| `phaseは現在の実行段階です。` | `phaseは現在の実行フェーズです。` names the same execution-state field; preserve its values. |
| `抽出と統合を別段階で実行します。` | `抽出と統合を別のフェーズで実行します。` preserves the two operations without asserting independence or concurrency. |
| `会話の加工と形式変換の二段階を示します。` | `会話の加工と形式変換の2つのフェーズを示します。` retains the count and the two targets. |
| `保留入力がなくなった段階で終了フックを呼び出します。` | Compare the same conditional timing with `フェーズで`; retain `段階で` or use `時点で` when timing, rather than a named execution division, is intended. |
| `設定だけがある段階では保存を保留します。` | Retain the state condition; do not invent a dedicated setup phase or change the first-message saving trigger. |
| `必要に応じて本文と補助資料を段階的に読み込みます。` | Retain progressive disclosure; `フェーズ別に` must not impose fixed phases or mandatory loading of all material. |
| `論文は単一段階のツール利用を検証しています。` | Preserve the study's stated evaluation scope; do not infer repeated use or a new phase model from terminology alone. |

`段階` can also denote a point in progress, a degree or learning progression;
`フェーズ` is not a universal replacement. Compare the full passage before a
keep decision and record the author's actual alternative and the specific
benefit or loss. Do not add state transitions, checks, guarantees or runtime
mechanisms. Changing a label does not establish that an implementation has a
phase enum. Preserve identifiers, conditions, negation, phase count and order.

Follow accepted terminology into authorized headings, tables, figure labels and
alternative text using their own edit scopes. Do not rewrite historical records
or mutate existing session criteria. These are contextual prompt criteria, not
new detector rules or automatic replacement instructions.
