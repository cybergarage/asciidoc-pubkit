# English review (unreleased)

The 1.3.0.pre.1 checkout supports English; released 1.2.3 does not. Run the
selected invocation's `--version` and help before using these commands.

```sh
asciidoc-pubkit writing criteria --lang en
asciidoc-pubkit review scan book.adoc --lang en --output .pubkit/en-prose --no-input
asciidoc-pubkit review prompt .pubkit/en-prose --lang en
asciidoc-pubkit review verify .pubkit/en-prose --lang en
asciidoc-pubkit review score book.adoc --lang en --json
```

Use separate `--scope headings`, `prose` and `lists` sessions. Complete and
verify each phase before scanning the next phase's current sources. Heading
prompts support `--view outline`, `--mode diagnose` and selection by `--depth`.
Existing mapping, protected-source, generated-ID and baseline rules still apply.
Only exact saved heading anchor additions are permitted. Verification is
mechanical and always reports `meaning_verified: false`. English support does
not add translation fidelity checks or publication approval.

## Language and analysis

Exact `en` selects `english-lexical`; exact `ja` retains MeCab/IPADIC. Explicit
`literal` also supports English using the same bounded lexical matching in this
release, with a distinct identity. Neither English backend provides POS tagging,
grammar correction, sentence segmentation or automatic rewriting. No model CLI
or network service runs by default. Only `review score --agent` invokes a model.
Regional tags such as `en-US` and `en-GB` are rejected rather than normalized.
Keep spelling policy in book instructions. Explicit document language must match
the selected language. English accepts `preserve` style and mixed heading forms
only; Japanese prose styles and the MeCab backend are rejected for English.
Replacement remains Japanese-only, even when review supports English.

Tokens contain Unicode letters, combining marks, numbers and underscores.
Internal straight/curly apostrophes, hyphens (ASCII, U+2010, U+2011) and dots bind
parts into a token, protecting contractions, compounds, identifiers and versions
from substring matches. Matching never normalizes the source. Case-insensitive
rules compare downcased token surfaces while retaining original spans and text.
No Unicode composition normalization or apostrophe equivalence is performed.
Columns count Unicode characters, not bytes, UTF-16 units or grapheme clusters.

Phrases may cross whitespace and physical line wraps within one selected entry.
They cannot cross punctuation, paragraphs or protected inline spans, even where
masking would leave whitespace. Ordinary English quotation marks remain reviewable;
existing AsciiDoc protected spans and Japanese quoted spans retain their exclusions.

## English rule schema

Custom rules replace the complete default set. CLI `--rules` takes precedence
over `review.rules`, then packaged defaults; resolved rules are saved in sessions.
Japanese schema 1 remains valid for Japanese. English requires schema 2:

```yaml
schema_version: 2
language: en
rules:
  - id: wordy-expression
    match: phrase
    terms: [due to the fact that]
    case: insensitive
    boundary: lexical
    severity: hint
    question: Compare a direct alternative without changing the causal claim.
    exceptions: []
```

Every shown key is required; unknown keys/versions are rejected. IDs must be
unique lowercase identifiers. `match` is `phrase` or `repeated-word`; the latter
requires empty `terms`. `case` is `sensitive` or `insensitive`; `boundary` is
`lexical`, and severity is `hint`. Terms and exceptions are nonempty lexical
phrases separated by whitespace. Exceptions suppress the exact token sequence
under the rule's case policy, not a surrounding context or regex. For repeated
words they can exempt sequences such as `had had` or `that that`. Default
repeated-word exceptions also include `is is` for metalinguistic use.

English heading rule sets use the same keys plus `fixed_titles` (exact strings),
`duplicate_siblings` (boolean), and `style: mixed`. Packaged heading rules flag
only exact sibling duplicates; contextual title/body judgment lives in criteria.
Glossary variants match case-sensitive lexical phrases; unsupported punctuation
in glossary phrases is rejected. Official literals can instead remain protected
inline code. An allow entry suppresses an exact surface or a phrase-rule term
under that rule's case policy. It does not grant edit permissions.

## Scores and preservation

Both languages use the existing character-based candidate-density formula. See
[scoring](scoring.md). Results are not calibrated measures of writing quality,
and cannot be compared across languages, rule sets or backends. English rubric
ratings keep sentence clarity and paragraph coherence separate. They do not
establish technical correctness or source-language fidelity.

Sessions retain schema 3 because settings, criteria and analysis identity fit
its existing representation. Exact tool versions still must match. The English
identity records engine, language, implementation version and boundary policy;
verification reports drift. Prompt generation uses saved criteria and findings
without constructing an analyzer. Retain old sessions with their original tool;
never rescan to hide a failed preservation check.
