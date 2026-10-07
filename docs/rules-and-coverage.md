# Rules and coverage

| Rule | Severity | Purpose |
| --- | --- | --- |
| `abstract-reference` | hint | Ask what an abstract noun refers to |
| `weak-predicate` | hint | Ask whether an operation's purpose or result is clear |
| `contextual-phrase` | hint | Check whether a qualification changes interpretation or action; preserve necessary negation |
| `generic-framing` | hint | Check whether an introduction or recap adds a claim, scope, or consequence |
| `vague-degree` | hint | Ask what depth, level, scope, or comparison is intended |
| `repeated-ending` | info | Identify three consecutive sentences with the same detected ending |
| `glossary-variant` | warning | Identify project-specific terminology variants |
| `style-candidate` | hint | Check selected polite/plain endings against an explicit style |

MeCab mode matches noun and adjective tokens and dictionary forms of verbs.
Sahen predicates are matched as a noun followed by `する` or the potential
`できる`; standalone sahen nouns are not treated as verbal predicates. A configured
sahen predicate takes precedence over a matching standalone noun rule. Auxiliary sequences retain
negation, past tense, passive forms, and progressive forms in the reported surface.
The added reach predicate is negative-only; the existing handling predicate is
reviewed in both affirmative and negative forms. Glossary variants and generic
framing phrases continue to use literal matching. Contextual phrases suppress
overlapping morphological candidates. Except for the four predicate patterns
described below, they use literal matching. Compound
nouns are matched across adjacent noun tokens. Selection and narrowing verbs
include potential forms; predicate surfaces also preserve causative auxiliaries.

Default terms group components, actors, relationships, and resources under
`abstract-reference`; operations under `weak-predicate`; and compressed noun
relationships, referents, sufficiency, and negative qualifications under
`contextual-phrase`. `木` and `余白` invite a context-dependent katakana terminology
review, not mandatory replacement. `明示選択` and `欠落理由` invite checking whether
`明示的選択` and `欠落した理由` clarify the intended relationship. Shared phrases such
as `ではありません` cover longer qualifications without listing every sentence.
`generic-framing` also flags `このように` and `要するに` as possible recaps.
These are candidates for contextual review, not banned expressions. A necessary
condition, uncertainty, or distinction must survive a revision; a redundant
disclaimer can instead be removed or folded into a more precise main claim.

Version 0.8.5 extends the existing `入口` question and shared criteria
without adding another prose matcher. A known referent alone does not justify
vague role wording; direct alternatives are evaluated against the actual
operation, conditions, and technical usage. The heading `heading-vague-topic`
rule also includes `入口`; proposed title changes must preserve generated IDs
or be reported for a separate authorized migration. Lists remain excluded and
are not included in prose or heading body evidence. Reports about outside-scope
concerns cover only content actually inspected, not unreviewed excluded blocks.
If baseline or artifact integrity fails, preserve the evidence and stop editing;
never update snapshot hashes or replace the baseline to claim a successful review.

Version 0.8.3 also includes scoped candidates such as `構築入口`,
`エラーを回収する`, `ツールを呼ぶ`, `したりできます`, and `設計の肝`.
These additions use the exact surfaces listed in the YAML in both modes;
they do not add general inflection coverage or ban everyday verbs. Existing
`木`, `持つ`, `書く`, `別です`, and `ではありません` rules cover related examples.
The shared criteria explain context-dependent terminology, precise operations,
direct predicates, and objective tone. They distinguish invocation from
execution, configuration text from configuration changes, assumptions from
requirements, and collecting errors from catching them. Suggested alternatives
are not automatic replacement rules. Start a new review session to include
updated rules and criteria; existing sessions retain their saved versions.

Version 0.8.4 also configures `呼ぶ`, `読み取る`, `拾う`, and the sahen predicate
`回収する` as weak-predicate candidates. MeCab matches their inflections for
any object, including `指示と宣言を読み取ります` and `最後のdetailsを拾います`.
This broadens review cues, not mandatory terminology changes; everyday and
technically valid uses can be retained with a specific reason. Literal mode
matches only the selected surfaces in the YAML. Longer contextual phrases take
precedence. `木全体` is an explicit contextual phrase in both modes because
IPADIC can parse `木全` as a surname; this narrowly addresses that segmentation
case without treating all names or compounds containing `木` as trees.

Version 0.8.5 additionally reviews `拡張点`, `使えます`, `積み重なります`,
`開放しています`, `見落とします`, `扱えます`, `使っています`, and selected indirect
phrases. Existing tracking rules cover `追えます`. MeCab uses configured lemmas
for use, potential handling, accumulation, oversight, and sahen opening;
literal mode uses the listed surfaces. The shared examples distinguish an
extension point from its mechanism, layers from a stack, system detection from
human oversight, and processing from control. Revisions preserve actors,
capabilities and obligations, sequence, visibility, counts, and distribution.
These additions need a fresh scan and are contextual review guidance.

Metaphorical-operation candidates include limited exact surfaces of
`地味に効く`, `静かに壊れる`, `時間を溶かす`, and `側に倒す`, including selected polite,
past, and connective forms listed in the packaged YAML. They use contextual
phrase matching in both tokenizers; this is not complete inflection coverage or
syntactic analysis. Bare verbs such as `効く`, `壊れる`, `溶かす`, and `倒す` are
not added as general metaphor candidates. Identify the actual effect, policy,
work, or failure state from evidence rather than applying a fixed replacement.
Keep valid technical meanings and necessary negation.

Version 0.6.2 additionally matches these four phrases with MeCab/IPADIC
verb lemmas and adjacent predicate auxiliaries. For example, `地味に効かなかった`,
`静かに壊れていた`, `時間を溶かしてしまった`, and `側に倒しました` retain their
complete surfaces and polarity. A pattern is enabled only when its canonical
phrase (`地味に効く`, `静かに壊れる`, `時間を溶かす`, or `側に倒す`) is present in
the resolved `contextual-phrase.terms`. Removing those canonical entries from
custom rules disables their morphological patterns; remaining exact surfaces
still work. No YAML schema change is required. Allow lists accept the canonical
phrase or exact detected surface. The most specific overlapping phrase wins,
including allowed phrases. Masked inline content, unknown tokens, and paragraph
boundaries cannot bridge a pattern. This remains a limited contextual heuristic,
not a syntactic or semantic determination of metaphor. Literal mode retains
exact surfaces and does not acquire this inflection coverage.

In version 0.6.2, a `repeated-ending` candidate points to the ending
of the third sentence in the first consecutive run within each paragraph.
A sentence without a matching ending interrupts the run. The candidate remains
informational because precise technical repetition can be necessary.

The shared criteria distinguish reader instructions, actual system behavior,
and available capabilities. They also separate readability from checks for
missing information and unsupported additions. Sentence length, punctuation,
and list density are contextual cues, not fixed acceptance thresholds. These
updates are included in 0.6.2; start a new session to use updated criteria and rules.

Literal term matching suppresses matches strictly contained in a longer matched
term, across categories. The longer term also suppresses contained matches when
it is allowed; separate occurrences remain candidates. Glossary and style checks
are independent. In MeCab mode, predicates outside a contextual phrase can still
be reported separately.

Morphological candidates include `lemma`, `part_of_speech`, `negative`, and
`detector` alongside the original `match`, line, and column. Negation detection
covers common IPADIC negative auxiliaries; it is not full semantic analysis of
negation scope or double negatives. Unknown tokens are not guessed. Kana/kanji
variants of the alignment and gathering verbs have explicit canonical mappings;
other spelling variants are not automatically normalized.

The session records the MeCab version and dictionary file hashes. Verification
reports analyzer changes instead of treating results from different dictionaries
as directly comparable. Prompt generation uses saved evidence and does not need
MeCab. Changed rules or dictionary settings require a new scan.

Version 1.0.3 uses session schema 3.
Sessions with a different schema or tool version cannot be loaded. Keep the original baseline for
an ongoing review and finish it with the original version, or start a new review
pass in a different directory:

```sh
asciidoc-pubkit review scan book.adoc --output .pubkit/review-1.0.3
```

Severity describes review priority, not proof of an error. There is no AI-authorship
score and no requirement to eliminate every match.

In the default prose scope, only source-mapped running-prose paragraphs are reviewed. Headings, list items and
their continuations, tables, quotations, code, and passthrough blocks are excluded
from prose review. Common inline literals, macros, attribute references, URLs, and
Japanese quotation spans are masked. Complex inline syntax can exceed the masking
heuristic; review its diagnostics with care.

Source locations are checked against original lines because Asciidoctor block
locations can be inaccurate at include boundaries. If a location cannot be matched
unambiguously, the paragraph is skipped with a coverage notice. Columns are
one-based Unicode character positions, not byte offsets or display widths.
An empty findings array does not establish full coverage or good prose.

[Back to README](../README.md)
