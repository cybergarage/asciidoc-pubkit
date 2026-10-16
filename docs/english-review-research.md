# English review support research and proposal

Research date: 2026-10-02. Repository inspected at `26cbb1e`, following release
0.8.1. The original survey and proposal below describe that historical checkout.
English review is now implemented in the unreleased 1.3.0.pre.1 checkout;
released 1.2.3 remains Japanese-only.

See the [implementation and book-skill assessment](#implementation-and-book-skill-assessment-2026-10-16)
for the current checkout assessment and proposed delivery sequence.

English review is a practical extension of the existing source-mapped review
workflow. The recommended first release combines conservative English phrase
and terminology candidates, contextual review prompts, and existing mechanical
verification. Grammar engines should remain optional until their accuracy,
source offsets, installation costs, and reproducibility have been evaluated.

## Implementation status (2026-10-16)

The initial implementation is documented in [English review](english-review.md)
and [English evaluation](english-evaluation.md). The historical proposal and
pre-implementation assessments below are retained as design context, not current
command references.

- Japanese defaults and schema 1 remain unchanged; English uses exact `en`,
  `english-lexical` (or explicitly selected literal matching) and strict schema 2.
- English prose, heading, list, outline and writing workflows save English
  criteria and retain mechanical preservation. Session schema 3 and exact tool
  version checks remain in force. Replacement still rejects English.
- Both languages retain the same candidate-density formula, with explicit units
  and no cross-language quality claim. The optional English readability rubric
  is separate from detection and preservation.
- The initial 120-paragraph corpus has 59 expected lexical candidates across
  disjoint development/evaluation document groups. Baseline precision, recall,
  F1 and location accuracy are 1.0 on these authored fixtures; they are not blind
  or independently human-reviewed evidence of production quality.
- Twenty-four revision cases and an imported-judgment evaluator test readability
  separately from source-fact retention. Normal tests use synthetic judgments
  to validate the harness. No actual model evaluation or measured editing
  improvement is claimed.
- Grammar adapters and a cybergarage-pub English review skill remain subsequent
  work. The existing translation skill's source-comparison guidance was updated
  separately before implementation. This gem implementation does not change
  manuscript files, translation states or publishing workflows.

## Scope and research method

The survey covers prose linters, grammar checkers, writing assistants, technical
style guides, grammatical error correction, simplification, editing benchmarks,
and model-based evaluation. Sources are official documentation, project
repositories, research publications, and author-hosted papers. Product claims
are descriptions of intended capabilities, not independently measured results.
Paper abstracts and available documentation establish the findings below;
this is not a reproduction of their experiments or a systematic review of every
publication. No external grammar tool was installed, no manuscript was sent to
one, and no model CLI was invoked. Commercial integrations and dataset licenses
have not been audited. The official ASD-STE100 site could not be retrieved, so
its current edition and requirements are not used as verified design inputs.

The requested English version is interpreted as reviewing English manuscripts,
including prose, headings, prompts, verification, and the scoring consequences.
The CLI and generated instructions already use English.

## Product landscape

The final column contains this project's engineering assessment, rather than a
claim made by the source.

| Product or framework | Verified capability and source | Application to pubkit |
| --- | --- | --- |
| Vale | Configurable YAML style linting with document scopes; primarily style rather than general grammar. [Overview](https://docs.vale.sh/) | Closest model for terminology, configurable rules, and separating prose from headings. |
| Vale AsciiDoc support | Uses external Asciidoctor; excludes code and URLs and addresses generated text. [AsciiDoc documentation](https://docs.vale.sh/formats/asciidoc) | Useful comparison for coverage and source mapping; retain pubkit's conservative mapping and preservation baseline. |
| textlint | Pluggable rules; Markdown and plain text built in, other formats through plugins; no bundled rules. [Repository](https://github.com/textlint/textlint) | Study rule isolation and diagnostics; Node and processor dependencies make it unsuitable as the mandatory Ruby backend. |
| write-good | Explicitly naive English linting for passive voice, repeated words, weak qualifiers, wordiness, and clichés. [Checks](https://github.com/btford/write-good#checks) | Candidate taxonomy and negative examples; avoid adopting its checks as universal defects. |
| proselint | Configurable editorial checks including clichés, hedging, terminology, and typography. [Repository](https://github.com/amperser/proselint) | Reference for phrase candidates and exceptions; necessary scientific uncertainty must survive. |
| RedPen | Technical-document proofreading with support including AsciiDoc. [Repository](https://github.com/redpen-cc/redpen) | Compare document validators and coverage; do not equate length thresholds with comprehension. |
| retext | Natural-language processing through plugins. [Repository](https://github.com/retextjs/retext) | Reference for modular language processing; not a reason to require JavaScript. |
| alex | Finds potentially insensitive or unequal wording and documents contextual limits. [Repository](https://github.com/get-alex/alex) | Optional terminology policy, with exceptions for official API names and historical quotations. |
| LanguageTool | Rule-based grammar/style infrastructure and a local HTTP server; its local basic server excludes cloud AI rules. [Developer docs](https://dev.languagetool.org/), [local server](https://dev.languagetool.org/http-server) | Strong optional grammar comparison. Evaluate local rules separately from commercial cloud behavior. |
| Harper | English grammar checker implemented in Rust with offline operation. [Repository](https://github.com/Automattic/harper) | Candidate optional local grammar backend; benchmark supported rules and interfaces before selecting it. |
| Grammarly | General grammar and writing suggestions. [Official product](https://www.grammarly.com/grammar-check) | User-experience comparison; no assumption of a suitable local, reproducible integration. |
| Hemingway | Highlights writing issues and offers grammar/tone assistance in its Plus product. [Official product](https://hemingwayapp.com/) | Compare presentation of review candidates; readability labels alone cannot validate technical meaning. |
| Acrolinx / Markup AI | Enterprise voice, style, and terminology governance; the retrieved site announces the Markup AI name. [Official site](https://www.acrolinx.com/) | Reference for audience-specific policies and glossary consistency, not an initial dependency. |

Vale should guide the static-rule design. LanguageTool and Harper should be
evaluated as optional grammar services. None of the reviewed descriptions is
evidence that a tool reproduces pubkit's particular baseline, protected-source,
and section-ID verification contract.

## Editorial foundations

| Source | Relevant guidance | Proposed treatment |
| --- | --- | --- |
| [Google guide highlights](https://developers.google.com/style/highlights) | Clear actors, global audience, conditions before instructions, descriptive organization. | Main starting point for English technical prose criteria. |
| [Google active voice](https://developers.google.com/style/voice) | Prefers active voice but explicitly permits passive exceptions. | Inspect missing actors in context; do not ban passive voice. |
| [Google present tense](https://developers.google.com/style/tense) | Present tense for general behavior; future tense has legitimate uses. | Distinguish automatic behavior, capability, and scheduled events. |
| [Google headings](https://developers.google.com/style/headings) | Task headings and conceptual headings can coexist; sentence case is its convention. | Keep mixed heading forms as default; make capitalization a book preference. |
| [Google word list](https://developers.google.com/style/word-list) | Usage depends on product, audience, and terminology conventions. | Preserve defined terms, API names, and glossary exceptions. |
| [Microsoft verbs](https://learn.microsoft.com/en-us/style-guide/grammar/verbs) | Precise verbs and contextual exceptions to active voice. | Cross-check criteria so one publisher's preferences do not become universal rules. |
| [Federal plain language guidance](https://digital.gov/guides/plain-language) | Audience-oriented plain language guidance. | Supplement the technical guides; retain the engineering audience and required technical precision. |
| [RFC 8174](https://www.rfc-editor.org/info/rfc8174/) | Distinguishes uppercase normative keywords from ordinary lowercase usage. | Protect normative force; do not normalize MUST, SHOULD, and MAY as stylistic synonyms. |

Proposed English criteria should retain the current common principles: identify
the paragraph's purpose, actors, conditions, referents, and consequences; connect
sentences; preserve terminology and evidence; avoid invented implementation
details. English-specific additions should cover ambiguous pronouns, noun
stacks, nominalizations, wordy framing, instruction versus capability, and
appropriate voice. These are review questions, not mandatory rewrites.

## Research foundations and limitations

The applications below are proposed adaptations. Learner essays, Wikipedia,
pedagogical texts, and chatbot answers do not establish performance on software
engineering manuscripts.

| Research | Finding relevant to this decision | Proposed application and limit |
| --- | --- | --- |
| Naber, 2003, [A Rule-Based Style and Grammar Checker](https://danielnaber.de/languagetool/download/style_and_grammar_checker.pdf) | Describes an English rule-based checker. | Historical basis for explicit grammar rules; not evidence about current LanguageTool accuracy. |
| Bryant et al., ACL 2017, [ERRANT](https://aclanthology.org/P17-1074/) | Extracts and categorizes edits between original and corrected sentences. | Use grammar error types in optional grammar evaluation, separate from contextual prose candidates. |
| [BEA 2019 shared task](https://www.cl.cam.ac.uk/research/nl/bea2019st/) | Provides grammatical error correction evaluation and error-type analysis. | Secondary grammar benchmark; record scorer version, because the official site documents a later version change. |
| Bryant et al., 2023, [Grammatical Error Correction survey](https://direct.mit.edu/coli/article/49/3/643/115846/Grammatical-Error-Correction-A-Survey-of-the-State) | Surveys GEC methods and evaluation; different scorers' F-scores are not interchangeable. | Keep grammar benchmark protocol explicit; do not label its score as manuscript readability. |
| Rao and Tetreault, NAACL 2018, [GYAFC](https://aclanthology.org/N18-1012/) | Evaluates formality, fluency, and meaning preservation separately. | Separate style preference from clarity; increased formality is not automatically an improvement. |
| Xu et al., TACL 2016, [SARI](https://aclanthology.org/Q16-1029/) | Evaluates simplification operations against source and references. | Possible development metric only; unavailable as a meaningful default score for a manuscript with no simplification references. |
| Alva-Manchego et al., ACL 2020, [ASSET](https://aclanthology.org/2020.acl-main.424/) | Covers multiple simplification transformations. | Secondary examples of splitting, paraphrasing, reordering, and deletion; technical preservation needs an additional corpus. |
| Sun et al., COLING 2020, [Document context](https://aclanthology.org/2020.coling-main.121/) | Investigates preceding and following context for simplification. | Preserve neighboring paragraphs and headings in the single review prompt. |
| Devaraj et al., ACL 2022, [Factuality in simplification](https://aclanthology.org/2022.acl-long.506/) | Finds factual errors not captured by existing evaluation metrics. | Annotate unsupported additions, omissions, and changed claims independently of readability. |
| Cardon et al., EMNLP 2022, [Linguistic annotation of ASSET](https://aclanthology.org/2022.emnlp-main.121/) | Uses linguistic annotations to analyze simplification evaluation. | Report performance by edit and candidate category, not only aggregate scores. |
| Raheja et al., Findings EMNLP 2023, [CoEdIT](https://aclanthology.org/2023.findings-emnlp.350/) | Uses task-specific editing instructions and studies composite instructions. | Make the requested review objective explicit; a rewrite model is not needed inside scan or verify. |
| Maddela et al., ACL 2023, [LENS](https://aclanthology.org/2023.acl-long.905/) | Learns a simplification evaluator from human ratings. | Candidate research comparator, requiring domain validation before use on technical prose. |
| Heineman et al., EMNLP 2023, [SALSA](https://aclanthology.org/2023.emnlp-main.211/) | Introduces fine-grained human evaluation at edit level. | Annotate whether each edit improves clarity and whether it introduces an error. |
| Cripwell et al., READI 2024, [Document simplification evaluation](https://aclanthology.org/2024.readi-1.1/) | Separates simplicity and meaning preservation at document level. | Keep sentence clarity, paragraph coherence, and preservation as distinct outcomes. |
| Alva-Manchego et al., TSAR 2025, [Readability-controlled shared task](https://aclanthology.org/2025.tsar-1.8/) | Targets CEFR levels and evaluates semantic similarity and level accuracy. | Reader-level control is a possible later feature; its educational target differs from engineering clarity. |
| Liu et al., 2023, [G-Eval](https://arxiv.org/abs/2303.16634) | Studies rubric-based LLM evaluation. | Use structured judgments and human calibration; reported NLG results do not validate pubkit's rubric. |
| Zheng et al., 2023, [MT-Bench and Chatbot Arena](https://arxiv.org/abs/2306.05685) | Examines position, verbosity, and self-enhancement biases in model judges. | Blind labels, swap comparison order, repeat trials, and compare with human judgments. |
| Bagaria et al., 2026, [Rubric artifacts](https://arxiv.org/abs/2609.02942) | Reports predictive signals in rubric wording and failures under counterfactual reversals. | Add meaning-changing counterexamples and rubric sensitivity checks. Consulted as an arXiv manuscript; it reports EMNLP 2026 acceptance. |

## Current implementation constraints

Source inspection identifies these concrete changes before English can be enabled:

| Component | Current behavior | Required design work |
| --- | --- | --- |
| `language.rb` | Writing and review accept only `ja`. | Add English only when each public workflow has a supported implementation. |
| `settings.rb` | Defaults to MeCab; accepts Japanese prose styles and loads rules by language. | Resolve a default backend after language selection; validate language/backend/style combinations. |
| `rule_set.rb` | Strict schema includes sahen predicates and Japanese compound nouns. | Introduce an explicit English schema while keeping Japanese schema 1 valid. |
| `rules.rb` | Japanese POS values, inflection/negation handling, endings, and substring matching. | Route language-specific detectors; share masking, finding locations, allow lists, and glossary infrastructure. |
| `heading_rules.rb` | Japanese predicate morphology helps judge configured heading form. | Separate English heading analysis; retain mapped plain ATX editing and mixed forms. |
| `writing.rb` | Reads criteria by language. | Add English prose and heading criteria; review currently also calls writing-language validation. |
| `session.rb` | Constructs MeCab directly; prompt wording names Japanese; saves both prose and heading criteria. | Resolve analysis through a shared factory, parameterize language wording, and preserve saved evidence. |
| `score.rb` | Japanese evaluator rubric; density per 1,000 non-space characters. | Language-specific rubric and explicit density units/calibration. |
| `document.rb` | Validates the document's explicit language against the selected language. | Preserve mismatch errors; decide regional-tag handling explicitly. |
| CLI and package | Japanese-only help, descriptions, and tests; data glob already includes language files. | Update help, README, gem metadata, packaging checks, and language tests when implementing. |
| Development benchmark | Fixed Japanese corpus and analyzer-specific trials. | Add an English corpus and analysis identities without changing the Japanese baseline. |

Merely adding `en` to the supported list and translating the rule YAML would
leave Japanese morphology, substring false positives, scoring assumptions, and
prompt language errors in place. `replace` also uses shared settings; it needs
regression coverage even if replacement is outside the English review scope.

## Proposed initial behavior

These commands illustrate the original target interface. They now work in the
unreleased English-capable checkout, but not in published 1.2.3:

```sh
asciidoc-pubkit review scan book.adoc --lang en
asciidoc-pubkit review prompt .pubkit/review --lang en
asciidoc-pubkit review verify .pubkit/review --lang en
asciidoc-pubkit review scan book.adoc --lang en --scope headings
asciidoc-pubkit review score book.adoc --lang en
```

Proposed defaults: `ja` keeps MeCab/IPADIC; `en` uses a deterministic built-in
English lexical backend, with an engine name to be settled during implementation.
This is an explicit language default, not a fallback from a missing analyzer.
Reject `en` with `mecab` and Japanese style options with a specific diagnostic.
Keep `literal` as an explicitly selected limited backend, with its limitations
documented separately. Do not claim full grammar analysis for either built-in
phrase matching or literal mode.

Start with `en`; preserve spelling and regional variants by default. Do not
silently identify `en-US` or `en-GB` as `en` while discarding regional policy.
Either support these tags deliberately or report them as unsupported. Language
selection continues to follow CLI, configuration, and existing document
validation; automatic language detection is outside the first release.

### Candidate rules

| Candidate | Initial detection proposal | Contextual exception or limit |
| --- | --- | --- |
| Glossary variant | Whole-token/phrase matching with explicit case policy. | Preserve official product names, identifiers, and legitimate distinct concepts. |
| Redundant framing | Limited phrases such as `it is important to note that`. | The phrase may introduce a real qualification; no automatic deletion. |
| Wordy expression | Limited phrases such as `due to the fact that`. | Review complete sentences; do not infer an equivalent rewrite in every context. |
| Vague degree | Phrases such as `very easy` or `significantly faster` invite evidence checks. | A stated measurement may justify the wording; do not warn on all `significantly` occurrences. |
| Repeated word | Adjacent duplicate lexical tokens. | Intentional quotations and grammatical sequences such as `had had` need exceptions. |
| Abstract referent or metaphor | Prompt criterion initially; limited high-value phrases only after annotation. | Words such as `contract`, `boundary`, and `robust` have valid technical meanings. |
| Missing actor, ambiguous pronoun, noun stack, nominalization | Contextual prompt initially; optional NLP later. | Regexes cannot reliably resolve reference or technical relationships. |
| Passive voice, hedging, modal verbs | Contextual prompt; grammar analysis may locate constructions. | Preserve justified passive voice, uncertainty, permission, obligations, and possibility. |

Use `hint` for contextual style candidates. No lexical candidate establishes an
error or authorizes replacement. Do not detect AI authorship from words such as
`delve` or `leverage`.

### Matching and source positions

Define English lexical boundaries using an explicit contract, not the existing
Japanese substring matching or replacement's JavaScript-compatible `\b` rules.
Test apostrophes, contractions, hyphens, Unicode letters, underscores, digits,
mixed Japanese/English text, and API identifiers. Keep original text intact;
matching normalization must retain a reversible span map. Case-insensitive
search must return original surfaces and original offsets.

Continue to report one-based Unicode character columns. Every external adapter
must specify and test its offset unit, including non-BMP characters and
combining marks; byte, code-point, and UTF-16 offsets cannot be assumed equivalent.
Do not adopt an external tool's AsciiDoc parse as the authority for editable
source spans. Analyze pubkit's selected text and validate every returned span.
Masking should preserve newlines and offsets; English quotes require a deliberate
policy rather than blindly treating every quoted phrase as protected content.

If sentence segmentation is introduced, test abbreviations (`e.g.`, `Dr.`),
versions (`1.2.3`), decimals, URLs, and code spans. Count lexical tokens rather
than assuming spaces are adequate word segmentation. Phrase matching across
physical line wraps must not cross paragraph or protected-span boundaries.

### Rules and analysis contracts

An English schema should expose language, match kind, case policy, boundary
policy, severity, question, and exceptions explicitly. Reject unknown keys and
unsupported schema versions. Preserve complete custom-rule replacement and
CLI/configuration/default precedence. Freeze resolved rules into sessions.

Factor analysis construction out of scan, headings, score, and verify. Separate
lexical tokenization from optional grammatical analysis. A future adapter should
return source spans and stable rule IDs, plus an identity containing engine,
version, dictionary/model identifiers, and effective configuration hashes.
Save relevant identity in the session and report drift during verification.
Changing the saved analysis representation needs an explicit session-schema
compatibility decision; changing the rule schema alone need not automatically
change the session schema. Existing sessions already require matching tool
version, so do not promise cross-release session compatibility without tests.

Keep one Markdown prompt, each selected paragraph once, neighboring context,
saved criteria, protected data fences, and paragraph decision tracking. Scans,
prompts, and verification remain local and never invoke a model CLI. Only the
existing explicit `review score --agent` path may invoke the configured CLI.
Keep `meaning_verified: false`, protected-content checks, exit codes, stale-source
checks, and safe session replacement. English heading edits must preserve
generated IDs as well as explicit IDs.

### Scoring

The current character-density score is a detector-dependent indicator. Adding
English rules changes candidate density even without changing writing quality.
Initially retain an explicitly labeled within-language indicator and prohibit
cross-language score comparisons. A later per-1,000-word English metric should
have a new scoring version and an explicit token-count definition; do not
silently change `candidate-density-v1` or reuse the Japanese penalty without
calibration.

Keep optional readability ratings separate from density and detection accuracy.
Parameterize the existing sentence-clarity and paragraph-coherence rubric for
English, preserving the familiar technical audience and ordinal scale. Neither
rating proves factuality or preservation. Flesch-style or CEFR indicators may be
supplementary research outputs, but should not become release gates for software
engineering manuscripts. A technical term's length is not evidence that it is
unnecessary. [Vale's readability check](https://docs.vale.sh/checks/readability)
is a relevant implementation comparison, not a calibration for pubkit.

## Alternatives and decision

| Approach | Advantages | Costs and limits | Recommendation |
| --- | --- | --- | --- |
| Built-in English rules and contextual prompt | Ruby installation stays simple; reproducible candidates and controlled source spans. | Limited grammar coverage; requires its own boundary rules and evaluation corpus. | First release. |
| Mandatory Vale | Mature style infrastructure and AsciiDoc support. | Additional executable/configuration, separate parsing, overlapping responsibilities. | Study and benchmark; do not make mandatory. |
| Optional LanguageTool or Harper | Reuses existing grammar checks. | Adapter work, rule selection, version drift, installation, and technical false positives. | Prototype after the initial corpus exists. |
| Mandatory spaCy or Stanza | POS, lemmas, dependencies, and sentence analysis. | Python runtime/model downloads; grammar structure is not an editorial judgment. | Later only if measured gains justify it. |
| Model-only scanning | Can judge broad context. | Nondeterminism, provider access, unstable locations, and conflicts with current invocation contracts. | Retain contextual review outside deterministic scanning. |

The NLP capabilities above are documented in
[spaCy linguistic features](https://spacy.io/usage/linguistic-features) and
[Stanza's overview](https://stanfordnlp.github.io/stanza/). Their practical cost
and benefit for this gem remain to be measured.

## Evaluation and delivery plan

1. Define English criteria, backend combinations, boundaries, dialect policy,
   and score semantics. Implement language dispatch while keeping Japanese
   behavior unchanged.
2. Add English prose and heading criteria and an independently authored rule
   set. Enable scan, prompt, and verify together, with complete saved evidence.
3. Add English scoring and its rubric, either preserving labeled character
   density or deliberately introducing a calibrated new score version. Enable
   writing-language support consistently because review currently loads writing
   criteria through that gate.
4. Evaluate optional grammar adapters on the same corpus before selecting one.
   Any new integration must be explicit; no cloud service becomes a default.

Proposed corpus size: 100–200 independently authored technical paragraphs,
expanded as error categories stabilize. Cover API reference, procedures,
architecture explanations, tradeoffs, failure analysis, and headings. Include
positive examples, legitimate exceptions, and difficult negatives for every
rule. Separate development and held-out documents; do not let neighboring
paragraphs from one document leak across that split. Public research datasets
are secondary comparators, not substitutes for technical prose annotations.

Annotate candidate category, exact source span, whether inspection is useful,
context, protected material, and source facts. Use two human reviewers for a
calibration subset and adjudicate disagreements. Report precision, recall, and
F-score per rule, together with false positives per 1,000 words and location
accuracy. Decide thresholds before tuning; a provisional target of at least
90% precision for lexical hints is a project proposal, not a literature result.
Rules missing the agreed target should remain opt-in or prompt-only.

Evaluate edited text separately: sentence clarity, paragraph coherence,
information omissions, unsupported additions, substitutions, changed negation,
conditions, units, comparisons, and modal force. Include readable but wrong
edits as calibration examples. If model judges are used in explicit development
trials, blind authorship, swap pair order, repeat runs, preserve model/rubric
identity, and compare against human labels. Similarity metrics cannot replace
these preservation checks.

Regression coverage must include language/backend mismatch, regional tags,
custom rules, saved-rule immutability, analyzer drift, Unicode columns, wrapped
phrases, inline exclusions, include mappings, all-paragraph prompts, fence
lengths, stale sources, safe replacement, heading-generated IDs, and unchanged
exit codes. Add explicit checks that default workflows never invoke model CLIs
or remote services. Run the full Ruby suite with real MeCab/IPADIC to preserve
Japanese coverage, then build the gem and inspect packaged English criteria
and rules. Update README and CHANGELOG only when behavior is implemented.

## Remaining decisions

Before implementation, settle the lexical backend's public name and supported
combinations, whether regional English tags belong in the first release, the
English custom-rule schema, score compatibility, and any session-schema changes.
Before optional integrations, measure installation/runtime costs, technical
false positives, offset units, and licensing. Keep foreign rule/data reuse
separate from conceptual inspiration: verify license and attribution requirements
before copying rule lists, style-guide prose, models, or evaluation datasets.

## Validation of this proposal

This proposal is based on repository source inspection and linked primary-source
research. It does not change executable behavior or claim implementation
readiness from tests. Product benchmarking, external integration checks,
full-paper experimental reproduction, and dataset redistribution review remain
future work.

## Implementation and book-skill assessment (2026-10-16)

Status: implementation proposal, not delivered functionality. This assessment
inspected pubkit at `628eab8` (source version 1.2.2) and the existing
cybergarage-pub skill files at working-tree base `5bf99342c2`. The latter has
unrelated local changes; no book or skill was modified. Published gem contents
and the manuscript project's installed CLI were not verified. The original
external-tool survey was not repeated.

### Feasibility and changes since the original proposal

Implement the built-in lexical approach first. The existing mapped-source,
baseline, protected-content and verification workflow is reusable. English
requires language-specific analysis and criteria rather than a second document
parser. Adding a grammar service is not a prerequisite.

The present implementation adds requirements absent from the original plan:

- `Settings` supports `prose`, `headings` and `lists`. Full English book review
  must include supported list items, using the same phase boundaries and
  protection rules as Japanese review.
- Heading sessions save `outline_criteria`; `Writing.outline_criteria` reads
  `data/writing/<language>/outline.md`. English needs this third criteria file,
  including outline diagnosis, depth limits and read-only body evidence.
- Session schema is now 3 and loading checks both schema and exact tool version.
  New work must preserve this contract rather than assume old sessions migrate.
- The bundled skill is Japanese-specific, including its description, `--lang ja`
  commands and contextual terminology guidance. CLI support alone would not
  make the current skill an English workflow.
- `Rules.mask` turns protected spans into spaces. An English phrase matcher
  that treats every whitespace run as a separator could falsely join words
  across masked code or links. Preserve exclusion intervals as matching barriers,
  while allowing ordinary physical line wraps within an eligible paragraph.
- `Score.run` changes top-level `score` and `score_type` when `--agent` is used.
  English tests must distinguish that readability result from the retained
  candidate-density fields, including empty-input behavior.

Current rejection was checked with
`bundle exec ruby -Ilib exe/asciidoc-pubkit writing criteria --lang en`:
exit 2, `Unsupported writing language "en"; supported: ja.` This is a language
gate check, not an English implementation test.

### Recommended initial decisions

These are proposed decisions for implementation, not existing CLI contracts.

| Area | Proposed initial contract |
| --- | --- |
| Language | Support exact `en`; keep `ja` as the default. Reject `en-US` and `en-GB` explicitly until regional tags are deliberately supported. Do not infer language from prose. |
| Backend | Name the deterministic backend `english-lexical`; choose it by default for `en`. Preserve `ja` with MeCab and explicitly selected literal mode. Reject mismatched backend/language combinations before loading resources. |
| Literal mode | Keep explicit `en --tokenizer literal` as limited matching with documented case and boundary behavior, no grammatical analysis, and a distinct saved identity. It must not route into Japanese detectors. |
| Style | English initially accepts `preserve`; reject `desu-masu` and `dearu`, including inherited configuration. Regional spelling and capitalization preferences remain book-owned. |
| Headings | Default to mixed forms. Support lexical/glossary and exact sibling-duplicate candidates. Keep action/nominal classification as prompt guidance; reject unsupported English rule options rather than pretending Japanese morphology can implement them. |
| Rules | Preserve Japanese schema 1. Introduce an English schema 2 with explicit `language: en`, stable IDs, match kind, case/boundary policy, severity, question and exceptions. Dispatch by schema and validate against the selected language. Specify a separate compatible English heading schema as well. |
| Sessions | Aim to retain schema 3 only if saved settings and analysis identity fit its existing semantics and all validators can handle them. Otherwise bump the schema explicitly. Retain exact-version rejection and do not migrate baselines automatically. |
| Scoring | Preserve `candidate-density-v1` arithmetic and character denominator, explicitly label units and lack of English calibration. Compare only the same language, rule set and analysis identity. Do not introduce word-based penalties or claim Japanese/English comparability. |
| External engines | Defer grammar adapters and model-based scanning. Only explicit `review score --agent` may invoke a model CLI. |

The English schema should initially admit literal token/phrase rules and a
dedicated repeated-word rule, not unrestricted executable rules or a broad NLP
DSL. Define matching semantics before publishing the schema. Required examples
include `can` versus `can't`, ASCII versus curly apostrophes, `foo_bar`,
hyphenated terms, versions, mixed scripts, combining marks and emoji before a
match. Preserve source surfaces and Unicode character offsets. Avoid whole-text
normalization unless it provides an exact source-span map. Repeated words must
not match across punctuation, protected spans or paragraph boundaries; legitimate
sequences such as `had had` need explicit exceptions and context review.

Use `hint` for English lexical candidates, including glossary variants whose
concept identity requires judgment. Start with a small independently authored
phrase set. Treat vague degree, passive voice, pronouns and noun stacks as
prompt criteria until annotated evidence supports a useful detector.

### Implementation units and acceptance evidence

| Unit | Owning code and resources | Acceptance evidence |
| --- | --- | --- |
| 1. Language-neutral dispatch | `language.rb`, `settings.rb`, `morphology.rb`; new shared analysis factory; call sites in `session.rb`, `rules.rb`, `heading_rules.rb`, `score.rb` | Existing Japanese behavior and explicit literal mode pass real MeCab/IPADIC tests. Incomplete English workflows stay unavailable. |
| 2. English matching | New lexical backend and English rule validator/detectors; `rule_set.rb`; `data/review-rules.en.yml`, `data/heading-rules.en.yml` | Boundary, case, exceptions, inline barriers, line wraps, Unicode locations, custom-rule replacement and identity drift tests pass. |
| 3. Complete review workflows | `writing.rb`, `session.rb`, language-aware heading rules; `data/writing/en/{criteria,headings,outline}.md` | Prose, headings, lists, outline/full views, diagnose/revise modes, saved criteria, all-entry prompts and generated heading IDs work together. No Japanese-only instructions leak into English prompts. |
| 4. Scoring and public interface | `score.rb`, CLI help, configuration validation, gem metadata, README and command guides | English rubric, explicit units, zero eligible prose, custom rules, mock evaluator responses, and no implicit external invocation tests pass. Update language gates only with complete public paths. |
| 5. Regression and packaging | Existing review/morphology/replacement/skill tests plus English fixtures | Full suite with MeCab/IPADIC, gem build and archive inspection confirm all three English criteria files, rules and skill resources are included. Exercise `replace` shared settings without silently broadening its supported languages. |
| 6. Editorial evaluation | Independently authored technical corpus and manually reviewed pilot copies | Report per-rule useful-candidate precision, difficult negatives and exact location accuracy separately from preservation, fluency and translation fidelity. Do not claim measured quality from regression success. |

Keep these as focused implementation commits, with the public language gate
enabled only when the complete supported interface is ready. Session verification
must use the shared factory and engine-neutral drift diagnostics; the present
message assumes every drift is a MeCab version/dictionary change. Prompt creation
must remain independent of analyzer availability.

The initial technical corpus should include API descriptions, procedures,
architecture, limitations, headings and simple lists. Use document-level splits
and predeclare the useful-candidate threshold before tuning. The earlier 90%
precision target remains provisional; a small pilot cannot establish general
English review quality. Public gem fixtures should be independently authored;
book excerpts and private review artifacts stay in the manuscript project.

### Proposed cybergarage-pub English review skill

Add a project-owned
`.agents/skills/review-english-technical-book/SKILL.md` after an English-capable
CLI is available through the project's chosen invocation. Suggested description:

> Review and revise an existing English AsciiDoc technical book with
> asciidoc-pubkit in separate verified heading, prose, and list sessions. Use for
> English proofreading and outline diagnosis; translation fidelity and release
> readiness remain with the English-edition workflow.

Keep the entrypoint concise. Add `references/review-workflow.md` only for the
substantial phase/resumption and translation handoff details. Do not copy the
Japanese skill's term-specific examples or create another English criteria
library: canonical English prose, heading and outline criteria belong in pubkit
and are frozen in each generated session prompt. Book-specific US spelling,
glossary, technical evidence and records remain in the book.

The existing skills have distinct responsibilities:

| Owner | Responsibility after the addition |
| --- | --- |
| pubkit bundled `review-asciidoc-manuscript` | General mapped-source review workflow. Generalize its language selection and condition Japanese-specific guidance when English ships; preserve managed registration protections. |
| cybergarage-pub `review-japanese-technical-book` | Existing Japanese project workflow; do not redirect it to English or remove Japanese criteria routing. |
| New `review-english-technical-book` | English editorial review of existing manuscripts, with project state, scope and checks. Works for English originals as well as translations. |
| Existing `publish-english-edition` | Japanese source baseline, translation fidelity, reference localization, translated assets, edition state and release checks. Invoke the English review workflow only for the assigned editorial pass. |

The new workflow should:

1. Inspect the target's instructions, working tree, entrypoint, existing review
   records and, for translated editions, manifest/glossary/style guide. Check the
   exact installed CLI version and English capabilities. Do not silently use
   `--lang ja`, substitute literal mode, install another tool or reset a session
   when English support is missing; report the dependency limitation.
2. Default a full review to headings, prose, then supported lists. Honor focused
   and diagnosis-only requests. For each phase, scan with `--lang en` into an
   unused session, generate its prompt before editing, review every selected
   entry with neighboring context, record decisions and verify before scanning
   the next phase. Use explicit `--only` only for a limited assignment.
3. Preserve mapped spans, protected content and exact permitted heading anchors.
   Record out-of-scope table, image, caption and complex-list concerns separately.
   A full review of the supported scopes is not review of every visible artifact.
4. Preserve obligations, permission, uncertainty, negation, quantities and actors.
   Record the actual alternative and reason for each assigned decision. Do not
   ban passive voice or technical words and do not use lexical clues to infer
   AI authorship. Keep unsupported factual corrections pending.
5. For translations, compare edited passages against the immutable Japanese
   source through the existing translation workflow. A passing English baseline
   does not establish fidelity to Japanese. Do not advance an artifact to
   `reviewed` without the existing source-comparison and technical checks, or to
   `complete`/`ready` without its applicable build and release checks. Reassess
   affected prior evidence after edits without resetting unrelated records.
6. Report phase results, reviewed/pending IDs, applied and unapplied proposals,
   scope exclusions, translation-check status and project checks separately.
   Keep `meaning_verified: false`; do not claim publication readiness from it.

Two inspected English editions (`ai-codex-en` and `ai-agent-en`) declare
`:lang: en`, while their translation manifests declare `target_language: en-US`
and `epub_language: en`. The shared manifest template uses the same distinction.
Thus the proposed exact `en` CLI can serve these examples without rewriting
their US-English policy. This is not a repository-wide language audit. A target
actually declaring `:lang: en-US` needs explicit regional support or a separately
agreed metadata decision; do not override parser attributes to hide the mismatch.

When implementing the skill, update cybergarage-pub's root routing instructions,
human-facing README and the existing translation-review reference to distinguish
standalone English proofreading from translation/edition work. Do not make a
translation manifest mandatory for an English-original manuscript. The custom
project skill is not an editable copy of the gem-managed skill; do not overwrite
it with `skill install` or alter registration hashes.

Validate the new skill's frontmatter and reference links, then exercise diagnosis,
scoped revision, full three-phase review, unsupported CLI, existing-session
resumption and translated-edition handoff on isolated fixtures. Verify that
review success cannot promote translation or publication state by itself. Run a
small authorized book pilot only after the CLI/package checks pass; keep pilot
quality findings distinct from mechanical checks.

### Delivery recommendation and validation of this assessment

First consider the existing translation-skill improvements below; they do not
depend on English CLI support. Then settle the contracts above, implement and validate pubkit,
make the validated version available to the manuscript project, add the project
skill and routing, then evaluate a scoped English-book pilot. Avoid installing a
discoverable skill that advertises unsupported `--lang en` review. An interim
manual editorial pass, if requested, must be labeled as manual review without
pubkit's English baseline verification.

This assessment changes documentation only. Source inspection, the current
English-language rejection check and documentation checks do not validate future
English behavior. No implementation, skill installation, manuscript review,
grammar-engine evaluation, model evaluation, package release or publication was
performed.

## Earlier adoption in the existing translation skill (2026-10-16)

Recommendation: incorporate a small source-comparison procedure into
cybergarage-pub's existing `publish-english-edition` before implementing English
pubkit support or adding a standalone English review skill. This section assesses
that change; it does not apply it. The existing skill, translation/review and
setup references, style template, and translation/review prompt templates were
inspected. No changes to those skill files were present in the inspected diff.

The skill already requires source fidelity, retained confidence, natural US
English, terminology consistency, immutable Japanese baselines, and separate
review/build gates. Its principal gap is operational detail for comparing
English wording against those requirements. Supplement the existing review
procedure rather than introduce a second translation workflow or state model.

### What can be adopted now

| Research finding | Existing coverage and proposed addition |
| --- | --- |
| Clear actors and referents | Natural English is required, but actor selection is not explained. Compare the source actor, action, object and pronoun referents with the target. Supply an English subject only when the source or established context supports it; record ambiguity instead of inventing responsibility. |
| Conditions and modal force | Confidence and qualifications are already protected. Make comparison concrete: negation, condition scope, capability versus permission, obligation versus recommendation, quantified comparisons, units and uncertainty. Do not treat `can`, `may`, `must` and `should` as interchangeable stylistic choices or automatically introduce uppercase normative keywords. |
| Contextual voice and tense | Preserve justified passive voice when the actor is unknown, irrelevant or deliberately unstated. Prefer an explicit actor when supported and useful. Distinguish general behavior from a future plan without converting the latter into an existing capability. |
| Wordiness and nominalization | Compare a more direct alternative against the full source proposition. Remove framing only when it carries no qualification or discourse function. Keep established technical noun phrases; do not replace terminology merely because a shorter ordinary word exists. |
| Paragraph coherence | Read adjacent source and target paragraphs and headings. Check that connectors express the same causal, conditional or contrastive relationship. Do not insert a plausible causal explanation absent from the source. |
| Heading purpose | Compare a heading with its source and section body. Retain appropriate task and conceptual forms; use the book's capitalization policy. Do not impose imperative headings, a universal length limit, or sentence case across existing projects. |
| Evidence-based evaluation | Separate fluency, fidelity and structural findings. For a material proposed revision, record the source/target locations, supported alternative, reason and disposition in existing review evidence. A readable target can still omit a condition or strengthen a claim. |

Apply these checks to assigned prose, headings, list text, table text and
reader-visible labels where the translation assignment includes them. The
current translation workflow is not limited to pubkit's mapped prose scopes;
do not import those exclusions and accidentally leave translated tables or
diagrams unreviewed. Retain artifact-specific structure and diagram checks.

### Boundaries and conflicts to resolve

- Preserve the current paragraph-boundary and AsciiDoc-structure requirements.
  Sentence-level wording can improve within those boundaries. Splitting or
  merging paragraphs, moving sections and adding explanations require separately
  assigned work; simplification research does not authorize such changes.
- Source comparison remains mandatory. Technical discrepancies continue through
  the existing source-defect procedure; English polishing must not silently
  repair the Japanese source or replace its claims with new implementation facts.
- Keep these as contextual review questions, not banned-word lists, mandatory
  active-voice rules, automatic replacements or claims of AI authorship.
- Do not add `--lang en` commands, an English analyzer prerequisite, numeric
  quality gates, or claims of pubkit verification before the implementation exists.
  Grammar engines, readability scoring and research benchmark thresholds remain
  outside this early skill update.
- Preserve existing `translated`, `reviewed`, `complete` and `ready` requirements.
  No new status columns or automatic promotion follows from checking the added
  editorial questions. Prompt instructions cannot establish publication readiness.

### Minimal change set for a subsequent implementation

| Existing skill file | Proposed change |
| --- | --- |
| `references/translation-and-review.md` | Own the concise source-to-target comparison procedure and contextual exceptions, next to the existing Review section. This is the main change. |
| `SKILL.md` | Add a short route to that procedure for translation and review; retain the current purpose, source ownership and completion model. |
| `assets/translate-adoc-prompt.md` | Route to the procedure for source-supported subjects, modality and connections. Replace the unqualified final demand for “publication-ready AsciiDoc” with valid translated AsciiDoc subject to the existing review/build gates. |
| `assets/review-adoc-prompt.md` | Route to the same procedure; request source/target evidence for material findings and distinguish fluency from fidelity and structural checks. |
| `assets/style-guide-template.md` | At most add a short reference to the common procedure. Keep locale, punctuation and book-owned style here; avoid copying the complete criteria. |

No change to release checks, the manifest schema, status template or discovery
metadata is needed for this limited addition. Template edits affect future
copies; do not overwrite customized prompts or style guides in existing books.
An existing book can use the revised shared procedure on its next assigned pass,
subject to that book's instructions. Earlier review results are not retroactively
validated by the new guidance.

Until pubkit supplies English criteria, keep this small translation-specific
procedure usable without installing pubkit or reading another repository by
absolute path. When English support ships, move general English wording criteria
to pubkit and retain translation fidelity, source-defect handling and edition
state in this skill. Audit the overlap then; do not copy the full research paper
survey or build a parallel general-purpose writing guide now.

Validate a subsequent update with skill frontmatter/reference checks and a small
set of independently authored bilingual cases: an omitted but recoverable actor,
an unknown actor requiring passive voice, permission versus capability, negated
conditions, future plans, legitimate technical noun phrases, and an apparently
fluent translation that omits a qualification. Include a request limited to one
file and a structural-change proposal to check scope handling. Judge actual
source/target decisions, not just whether prompt text contains these terms.
Do not claim a general translation-quality gain from this small calibration set.
