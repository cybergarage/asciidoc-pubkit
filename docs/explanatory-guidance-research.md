# Explanatory guidance and checking actors: research and proposal

Status: implemented for v1.2.2 on 2026-10-12. Release authorized separately after the source update.
The proposal below is retained as design evidence. Shared criteria, the judge
rubric, eight affected calibration examples (seven new, one narrowed), tests,
and bundled/publisher-local skill instructions were updated. Detector rules,
installed gem/skill versions, old sessions and manuscripts were not changed.
Validation results are recorded separately from the original proposal.
Research date: 2026-10-12. Pubkit baseline: `095b06d` (v1.2.1).
Publisher evidence: cybergarage-pub commit `909de49833`, limited Orbit review.

This proposal separates a book's description of its contents from a reader's
checking procedure and a program's runtime checks. The first implementation
should update shared criteria, calibration examples, and review-workflow
instructions without changing detector rules, automatic replacement behavior,
verification semantics, or installed skills.

## Evidence and limits

The Orbit pass reviewed 193 source lines containing `確認します` across its
active manuscripts. It revised 49 matching lines, retained 144 after individual
comparisons, and revised two neighboring lines containing `確認し` and
`理解します`. These are author-specific editorial decisions from one book,
not measured detector accuracy or proof that another book needs the same edits.
The target expressions span 129 selected prose paragraphs and 56 protected
table lines. Book guidance, user approval, runtime checks, and test procedures
must not receive one lexical replacement rule.

The owning sources inspected in pubkit are:

- `data/writing/ja/criteria.md`, "Review sentence endings by their role": it
  already distinguishes scope announcements, operations, capabilities, checks,
  and history, but recommends keeping useful scope/reading-order guidance for
  introductory `確認します`. This does not explicitly assess a switch from the
  book's explanatory voice to a reader's learning or checking activity.
- `test/fixtures/prose_evaluation.ja.json`, `ending-scope-guide-kept`: the source
  and accepted unchanged revision are `本節では、接続設定、依頼の送信、終了確認の順に手順を確認します。`.
  Its reason rewards concrete reading order without resolving who performs a
  check. This example should be narrowed rather than teaching unconditional keep.
- `test/prose_benchmark_test.rb`: fixture integrity, required axes, and unchanged
  keep pairs are checked. These tests do not measure an AI's editorial judgment.
- `benchmark/prose.rb` and `docs/prose-evaluation.md`: optional AI trials keep
  detector scores separate from readability and preservation. The judge receives
  editorial constraints without gold dispositions or reasons. Changed rubric or
  calibration fingerprints require a fresh compatible evaluation baseline.
- `data/review-rules.ja.yml`: generic framing already includes `本章では`, but
  a candidate is not a diagnosis of an ambiguous actor. Adding every occurrence
  of `確認` would also flag legitimate operational checks.

The publisher's review workflow already requires neighboring context, faithful
alternatives, individual decisions, and separate scopes. Its missing operational
step is to record whether a targeted sentence is content guidance, an actual
procedure, runtime behavior, or a learning objective before choosing its verb.

## Proposed shared-criteria change

Keep the existing sentence-role section and revise its introductory-ending row.
Do not add a banned-word list. Suggested English instruction:

> Keep useful subject and reading-order guidance, but separately assess its actor
> and predicate. Distinguish the book explaining a subject from a reader checking
> evidence and a program validating state. When the author requests explanatory
> narration, prefer `説明します`, `示します`, or `比較します` for content guidance.
> A useful sequence alone does not justify retaining `確認します`. Preserve a
> genuine exercise, checking instruction, or runtime check with its supported
> actor, target, conditions, and timing.

Add a paragraph-level check for transitions among `説明します`, `確認します`,
`理解します`, and related inflections. A reader's learning objective is valid
when presented as an objective; it must not be treated as an operation performed
by the book. Read neighboring sentences and table column roles before adding
an actor. Do not repeat subjects where the context already identifies them.

For actual checks, compare equally faithful alternatives such as `照合します`,
`検査します`, `参照します`, or an explicit actor plus `確認します`. Use a more
specific operation only when the source establishes it. A configuration review
must not become automatic validation; a connection owner's shutdown check must
not become only a developer's test. Do not turn an unknown result into confirmed
completion or add a guarantee from naming a checking actor.

Treat `説明`/`解説` as contextual choices: content guidance can use `説明`, while
in-depth background or design discussion can use `解説`. Do not rename tool or
Skill description data, formal titles, quotations, or identifiers for variety.
The exact preference remains with the author and the book.

## Proposed calibration cases

Use original, compact fixtures instead of importing a manuscript or private
review session. Include full paragraph context and explicit editorial constraints
when the expected choice depends on the author's voice.

| Case | Source and proposed revision | Expected judgment and purpose |
| --- | --- | --- |
| Content guidance revised | `本章では、依頼の受付と結果の返却を確認します。` -> `本章では、依頼の受付と結果の返却を説明します。` | Accept under an explicit author preference for explanatory narration; preserve both subjects. |
| Ambiguous guidance retained | The same content-guidance source remains unchanged under that preference. | Reject the editorial decision; do not excuse it because its subjects are concrete. |
| Paragraph viewpoint repaired | A paragraph begins with `本章では…説明します` and ends with a reader's `役割を理解します` / `仕組みを確認します`; revise to presenting roles and explaining mechanisms. | Accept when the paragraph is entirely a content guide; retain all subjects and reading order. |
| Reader exercise retained | `この演習では、利用者が接続設定、依頼の送信、終了状態を順に確認します。` remains unchanged. | Accept: an explicit actor actually performs an exercise. Use this to narrow the current `ending-scope-guide-kept` example, retaining its historical identifier. |
| User check retained | `利用者は、変更するファイルと内容を確認してから編集を承認します。` remains unchanged. | Accept: preserve actor, target, order, and approval. |
| Runtime check made exposition | `実行側は、承認後にも対象の変更を検査します。` -> a sentence merely explaining changes to the reader. | Reject: runtime behavior was replaced with exposition. |
| Owner responsibility made test | `接続を生成した側は、終了後の資源の状態を確認します。` -> only a developer checks shutdown during a test. | Reject: the connection owner's runtime responsibility was lost. |
| Unsupported actor assignment | A check whose neighboring evidence cannot identify its performer is rewritten as an Agent's automatic check. | Needs-evidence: do not invent automatic execution or assign ownership. |

Keep the legitimate keep cases. The change should reduce ambiguous guidance
without rewarding mechanical replacement of every check. Adjust fixture counts,
required axes, judge rubric, and evaluation documentation together. Do not
compare the expanded calibration's scores directly with the old calibration.

## Proposed skill changes

Use pubkit as the single source of prose criteria. Add the following workflow
step to its bundled `examples/skills/review-asciidoc-manuscript/SKILL.md` and the
publisher's `review-japanese-technical-book/references/review-workflow.md`:

1. For a targeted ending, classify the sentence's role before judging its verb.
2. Read the complete paragraph and neighboring sentences; inspect table context
   separately when it is outside the selected prose scope.
3. Record the supported actor, target, condition, actual alternative, comparison,
   and disposition. Do not derive keep from the presence of a concrete subject
   or a useful reading sequence.
4. Apply author preferences from the current project instructions. Leave factual
   uncertainty unresolved instead of inventing an actor or mechanism.

The publisher's `japanese-technical-writing/SKILL.md` only needs a routing note
that paragraph viewpoint is assessed using the saved common criteria; do not
copy the new criteria there. Its OSS prose style profile can point to the same
criteria if needed. Book-specific AGENTS.md remains the owner of the exact
`説明`/`解説` preference. Do not impose Orbit's wording on sibling books.

Update the publisher-local skills as a separately scoped change. Do not use
`skill upgrade` to replace locally customized skills or modify old review
sessions during this work. Skill changes are not an installed gem release.

## Recommended implementation and validation order

1. Revise shared criteria and add/narrow calibration examples; align the judge
   rubric and evaluation guide. Add focused regression assertions for prompt
   delivery, contextual axes, and retained actual-check controls.
2. Update the bundled and publisher-local workflow instructions with the role
   classification step, keeping prose criteria in pubkit.
3. Run `bundle exec rake test` with real MeCab/IPADIC, relevant skill tests,
   reference checks, and `git diff --check`. Preserve old sessions and their
   saved criteria. Tests prove plumbing and fixture integrity, not improved AI
   proofreading.
4. If AI evaluation is explicitly requested, fix the expanded calibration and
   rubric first. Compare old/new criteria using that same setup and identical
   agent/model settings. Record per-case judgments; distinguish ambiguity repair,
   preservation failures, and needless changes to valid checks. Keep logs and
   treat a small fixture set as diagnostics rather than a general ranking.
5. Consider detector hints only after evaluating remaining missed cases and
   review noise. A later hint must be advisory, cover supported inflections and
   exclusions, preserve positions, and have MeCab/literal regression tests.
   It must never authorize automatic replacements or semantic verification.

The original research proposal did not authorize a version bump, publication,
installed-skill upgrade, old-session mutation, new manuscript edits or external
model invocation. The author subsequently requested the implementation and
v1.2.2 release as separate steps. Old sessions and manuscript sources remain
outside the release work.

## Implementation validation (2026-10-12)

- The full suite passed with Homebrew Ruby 4.0.7 and real MeCab/IPADIC:
  247 tests, 3,625 assertions, no failures, errors or skips.
- The bundled review skill and both affected publisher-local skill directories
  passed skill-creator's structural validator. This validates skill structure,
  not the quality of an agent's judgments.
- Fixture integrity, explicit author constraints and unchanged valid-check
  controls are covered. Shared criteria reach writing and all review scopes;
  saved sessions retain their original criteria.
- No external model evaluation was run. No measured AI proofreading improvement
  or publication readiness is claimed.
- At the source-update checkpoint, the installed gem remained v1.2.1 and no
  version bump, publication, commit or push had been performed. The subsequent
  author-authorized release targets v1.2.2.
