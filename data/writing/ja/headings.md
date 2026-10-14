# Japanese technical heading criteria

## Identify the section's role

Determine whether the section explains a concept, structure, operation,
comparison, principle, problem, or learning direction before suggesting a title.
Term labels, noun phrases, definition questions, action phrases, principles,
conclusion statements, and reader questions are all valid heading forms.
The form alone is not a defect. A nominal action label can also describe a procedure.

## Match the title to the evidence

Use the corresponding section body, descendants and neighboring context to
check the promised subject and scope. Do not add guarantees, implementation
mechanisms, actors, causes, superlatives, or benefits absent from the source.
Preserve conditions, negation, technical distinctions and exact terminology.
If supporting body text is missing or insufficient, record needs-evidence.
A table of contents alone cannot establish agreement with the section body.

For a title such as `手動圧縮の入口` or `画像・分類モデルへの入口`, apply the
shared role-metaphor criteria to the section evidence. Consider `起動方法` or
`呼び出しAPI` only when that is what the body explains. Naming a subject does
not by itself explain the operation. If a better title would change a generated
section ID, use the exact permitted_id_anchor only when the saved session explicitly
authorizes it. Otherwise record the proposed title and ID concern for separate
authorized preservation. Protection does not justify an editorial keep decision.

## Distinguish comparison subjects from distinguishing actions

For headings containing `区別`, establish whether the section explains a
difference between subjects or an action that tells them apart or treats them
separately. Compare `違い` or `相違` for differences in properties, behavior,
purposes or evaluation targets. Both are noun phrases; nominal headings do not
require `相違`. Follow the book's preferred tone instead of imposing the more
formal word on every book.

When the section explains source correspondence, compare `関係`; when it explains
what observations establish, name the supported confirmation scope. Recheck the
comparison subjects themselves against the body. Replacing only the final word
can preserve an inaccurate comparison. Retain `区別` when distinguishing or
separate treatment is the actual action, including an established technical term.
These comparisons do not ban `区別` or authorize uniform replacements in prose.

| Source heading | Contextual comparison and supporting section content |
| --- | --- |
| 修正案の提示と編集実行の区別 | 修正案の提示と編集実行の違い: the user applies a suggested edit, while a program checks permission and applies a requested edit. |
| 構成検証と作業品質の区別 | 構成検証と作業品質評価の違い: compare configuration checks with evaluation of the resulting artifact, making the second evaluation target explicit. |
| 共有知識と元の履歴の区別 | 共有知識と元の履歴の関係: the section explains an edited excerpt and its reference to the original message. |
| 観測形式と実行証拠の区別 | 観測情報から確認できる範囲: the section explains missing spans and the limits of inferring execution, test success or saved history from observations. |
| 証拠の欠落と新規測定の区別 | 評価処理の検証と新規測定の違い: compare tests using modified records with new task executions that measure artifacts and resource use. |
| 型タグによる正常値とエラー値の区別 | Retain when the section explains using a type tag to tell value variants apart; changing it to 型タグによる正常値とエラー値の違い would promise a different topic. |
| 停止要求と処理終了の違い | Keep the comparison when the body says a stop request does not establish termination. 停止要求による処理終了の保証 adds an unsupported guarantee. |

Record the actual alternative and body evidence even when no candidate is emitted.
Leave body text, tables, figures and alternative text unchanged in a heading-only
session; report any separately needed synchronization. These advisory examples
add no detector or automatic replacement rule. Saved sessions retain their original
heading criteria. Mechanical verification does not evaluate these comparisons
or measure AI proofreading quality.

## Compare headings with the same role

Read the complete outline and compare parent, sibling and child headings.
Align granularity and naming for sections with the same role; do not impose one
form on every heading at the same level or throughout the book. Conceptual
sections and procedures can intentionally use different forms.
Repeated official terms and fixed section names are valid. Check duplicate
siblings for ambiguity, without treating all repetition as a defect.

## Follow terminology changes through the section

When a heading introduces a technical term or clarifies a human role, check
that the body uses it for the same operation and scope. Compare headings with
the same role without making every section equally technical or equally long.
Apply the shared human-actor criteria: `人の確認` may refer to a user's approval,
an evaluator's review, or a general human-versus-AI distinction. Do not choose
`開発者` solely from the book's subject. In a heading session, body text remains
read-only; record needed body, table, figure, or alternative-text updates as
separate proposals rather than changing them with the title.

## Respect the book's format

The book owns preferred nominal or action forms, questions, fixed titles,
length expectations and numbering. The default accepts mixed forms, without a
universal character limit. Style candidates are advisory and admit exceptions.
Do not mechanically nominalize action headings or replace plain language with
abstract technical-sounding nouns. Do not reorganize, merge, split or reorder
sections during title correction.

## Record decisions and preservation concerns

Review every selected heading, including headings without machine candidates.
Record revise, keep or needs-evidence with a reason for each heading. Compare
original and proposed titles separately for information loss and unsupported
additions. Keep source identifiers, references and protected inline syntax.
Mechanical verification does not establish agreement with the body or semantic
correctness; meaning_verified remains false.
