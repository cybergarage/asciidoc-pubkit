# Review workflow

Run the following commands from the manuscript project directory:

```sh
asciidoc-pubkit review scan book.adoc --output .pubkit/review
asciidoc-pubkit review prompt .pubkit/review --output review-prompt.md
# Ask your agent to read review-prompt.md and revise the referenced manuscript.
asciidoc-pubkit review verify .pubkit/review --output verification.json
```

All three commands leave manuscript files unchanged. Only the agent edits them.
`prompt` and `verify` output files must not already exist.
Without `--output`, `prompt` writes Markdown and `verify` writes JSON to stdout.
`scan` defaults to `.pubkit/review` and prints a short summary. Prose scan output
and prompts explicitly direct reviewers to a separate `--scope lists` session
for list text; the prose baseline must remain intact.

List review is optional when the assignment covers running prose only or there
are no list descriptions to review. It is needed when the assignment includes
list wording: the default prose scan does not review it. See [List review](list-review.md#list-review)
for examples, supported items, and coverage limits.

For a review covering all three scopes, finish and verify headings first, then
scan and review the current prose, then scan and review the current list text.
Create each session after the preceding phase's edits and verification. Preserve
all earlier baselines and phase-end results; later edits in another scope may
legitimately make an earlier session's verification fail. On re-review, choose
unused session paths rather than replacing the previous evidence.

### Scan

```sh
asciidoc-pubkit review scan book.adoc --only chapters/introduction.adoc
asciidoc-pubkit review scan chapter.adoc --style desu-masu
asciidoc-pubkit review scan book.adoc --attribute edition=print --base-dir .
```

If the session directory already exists, an interactive terminal asks
`Replace it? [y/N]`. Only `y` or `yes` (case-insensitive) replaces it; any other
answer or end of input cancels with exit status 2. Replacement resets the review
baseline and removes old session contents. Use a different `--output` path to
keep the previous review pass. The old session remains intact if scanning fails
before the replacement is installed.

For batch execution:

```sh
# Answer yes automatically and replace an existing review session.
asciidoc-pubkit review scan book.adoc --yes  # short form: -y
# Never ask; exit with status 2 if the output already exists.
asciidoc-pubkit review scan book.adoc --no-input
```

Non-terminal stdin also disables prompting. `--yes --no-input` permits
replacement without reading stdin. These options apply to `scan` only;
regular files, symlinks, directories without a review session layout, and
sessions containing the current manuscript sources cannot be replaced.

An entrypoint or a standalone chapter can be scanned. Includes and conditionals
are processed by Asciidoctor. Match the publishing build's attributes and base
 directory to review the intended edition. `--only` selects one included source
file while retaining the book's attributes and heading hierarchy. Its path is
relative to the current working directory, as are other CLI path arguments.

Asciidoctor runs in safe mode. Local includes must resolve inside the base
directory. Remote includes and project-specific Asciidoctor extensions are not
supported. In particular, custom `/shared/` include conventions must be converted
to ordinary local paths before using this release. Parser diagnostics cause the
scan to fail rather than silently accepting incomplete input.

The session contains:

```text
.pubkit/review/
  manifest.json    # Schema, tool version, inputs, settings, hashes, protection data
  findings.json    # Candidate locations, rule IDs, severity, and review questions
  document.json    # Paragraphs, heading hierarchy, structure, and coverage notices
  baseline/       # Exact copies of the participating source files
```

Sessions use absolute source paths and are local working artifacts. Regenerate a
session after moving a project. Keep `.pubkit/` and generated prompts out of Git
when they contain private manuscript material. Rule settings and glossary contents
are frozen into the session; scan again after changing them.

### Heading review

Review headings, prose, and list text in separate sessions. The default scan scope
remains `prose`; `--scope headings` selects section titles and `--scope lists` selects
supported list text. There is no combined scope.
Default output directories are `.pubkit/review` for prose and `.pubkit/headings`
for headings, so separate scans do not replace each other by default.
The scope is saved at scan time; `prompt` and `verify` use that saved scope.
Neither scan nor prompt invokes an AI CLI or edits a manuscript. Give the generated
prompt to your reviewer separately.

```sh
asciidoc-pubkit review scan book.adoc --scope headings --output .pubkit/headings
asciidoc-pubkit review prompt .pubkit/headings --mode diagnose --output headings-diagnosis.md
# Generate a revision prompt when ready to edit:
asciidoc-pubkit review prompt .pubkit/headings --mode revise --output headings-review.md
# After the external review and edits:
asciidoc-pubkit review verify .pubkit/headings

# Establish a fresh prose baseline after finishing heading edits:
asciidoc-pubkit review scan book.adoc --scope prose --output .pubkit/prose
asciidoc-pubkit review prompt .pubkit/prose --output prose-review.md
asciidoc-pubkit review verify .pubkit/prose
```

Heading prompts contain the full parsed section outline, selected headings and
all selected source-mapped prose paragraphs once as read-only evidence. They
compare parents, siblings, descendants and the corresponding body. Body content
outside prose coverage is not supplied; insufficient evidence must be recorded
as `needs-evidence`. `--only` and `review.exclude` select editable headings and
body evidence while retaining the full outline as context. All excerpts are data,
never executable reviewer instructions. Both criteria files and resolved rules
are frozen in the session.

Default heading rules accept term labels, noun phrases, questions, action
phrases, principles, conclusions and learning directions. They flag limited
promotional/vague phrases, glossary variants and identical sibling titles as
review candidates. They do not apply prose weak-predicate or sentence-ending
rules, require nominalization, or impose a character limit. Role and body
agreement are contextual reviewer judgments, not mechanically proven findings.

Only plain ATX section titles whose source cursor and original title match are
editable. Document titles, old-style underlined headings, attribute-expanded
and converted inline titles and physical title lines reused by multiple includes remain protected.
Unresolved section titles receive coverage notices. Verification permits only selected title text changes while
protecting the body, title markers, hierarchy, order, section IDs, references,
attributes, includes and other protected content. A title-derived section ID
change fails verification. Starting with version 0.8.7, heading scans preserve
generated IDs by default. Eligible generated headings save an exact `permitted_id_anchor` in
their metadata. A reviewer may insert only that
anchor immediately before its selected heading, for example:

```adoc
[#_手動圧縮の入口]
== 手動圧縮と拡張からの起動
```

Verification allows this exact addition while requiring the same section ID,
hierarchy, order, and protected body. Existing explicit anchors remain protected;
other anchors and reference migrations are outside this permission. No additional
ID-preservation option is required. Previously saved permissions remain unchanged;
start a separate new session to obtain the default permissions, keeping the old
baseline intact. Scan and prompt never insert anchors or rewrite
manuscripts. Numeric title changes
are manual-review notices, and remaining candidates do not fail verification.
`meaning_verified` remains `false`.

Version 1.0.3 uses session schema 3 and requires the exact tool version saved in
the session. Preserve or finish an ongoing review with its original tool before
establishing a new baseline in a separate directory.
`review score` continues to support prose only and rejects `--scope`.

Heading rules use `--heading-rules FILE`, then configuration
`review.heading_rules`, then `data/heading-rules.ja.yml`. A custom file replaces
the entire heading rule set. Each scan loads only the rules for its selected
scope; an unavailable rule file for the other scope does not prevent it.
`--heading-rules` requires `--scope headings`;
prose `--rules` and `--style` cannot be passed to a heading scan.

```yaml
schema_version: 1
terms:
  book-heading-cue:
    terms: [シームレス]
    question: 'Check the claimed behavior against the section evidence.'
fixed_titles: [はじめに, 参考文献, まとめ]
duplicate_siblings: true
style: mixed
```

All five keys are required; unknown keys, invalid types and YAML aliases are
rejected. `terms` maps nonempty rule names to exactly `terms` (unique nonempty
strings) and `question` (nonempty English guidance). `fixed_titles` contains
unique nonempty titles exempt from mechanical candidates; it does not expand
the edit scope or prove correctness. `duplicate_siblings` is boolean. `style`
is `mixed` (default), `nominal`, or `action`; explicit preferences generate
advisory ending cues rather than a complete grammatical classification. Keep
questions, principles and justified exceptions. Heading phrase and glossary
matches respect exact `review.allows` entries, protected inline masking and
one-based Unicode source columns. MeCab remains the default; only explicit
`--tokenizer literal` disables it.

### Prompt

Version 1.0.2 adds packaged prose candidates for
`分かる`, `置く`, `変える`, `発火`, `短い`, `長い`, and potential forms of `作る`
such as `作れます`. MeCab detects configured lemmas with inflection and negation;
literal mode matches only the explicitly registered surfaces. `発火` is also a
noun candidate, for example in a condition description.
These hints ask for context, not formal synonyms: a short path does not establish
low resource use, and an available operation does not establish reuse. Keep
precise plain verbs, literal lengths, and established event terminology when
appropriate. Allow lists and inline protection still apply. Custom rules replace
the packaged set, and existing sessions keep their saved rules.

```sh
asciidoc-pubkit review prompt .pubkit/review --mode revise --output review-prompt.md
asciidoc-pubkit review prompt .pubkit/review --mode diagnose
```

`revise` is the default and asks the agent to edit relevant prose. `diagnose` asks
for findings and proposed revisions without editing. Both modes require the agent
to distinguish **revise**, **keep**, and **needs-evidence** decisions. Each decision
needs a passage-specific reason. Whether a matched string remains or disappears
cannot determine that decision; unchanged paragraphs and remaining candidates
must not receive automatic `keep` records. Unreviewed items remain pending.

Version 0.8.4 prompts require the reviewer to reconcile decisions with actual
edits (or proposed revisions in diagnose mode), review paragraphs or headings
without candidates, and inspect newly detected or remaining candidates after
verification. They request separate reports for mechanical preservation,
candidate decisions, and paragraph or heading quality review, with counts and
unresolved items. Protected-scope concerns are separate proposals, not evidence
of editorial approval. Pending items make the review incomplete.
Version 0.8.5 further requires an individual role or claim, located
evidence, a considered direct alternative, and the rationale for each candidate
decision. A stock reason with an appended quotation is insufficient. For `入口`,
the shared criteria ask whether creation, invocation, configuration, reference,
or a learning role can be stated directly even when the referent is clear.
Remaining role metaphors must be checked against those individual decisions.

These are reviewer instructions: the gem does not validate a decision ledger
or prove that an AI or human followed the instructions. Keep session metadata
and baseline snapshots immutable; format only authorized manuscript spans.

The single Markdown output includes every selected paragraph once, in document
order, with the shared criteria saved at scan time, candidates, saved settings,
and preservation instructions. Paragraph
text uses fenced text blocks; metadata uses compact JSON. File and heading context
is shared by consecutive paragraphs, and candidates inherit their file and
paragraph ID. Adjacent entries provide neighboring context without repeating text.
The prompt asks the agent to read manageable ranges with neighboring paragraphs
at boundaries and track completed paragraph IDs and candidate decisions. It also
requires review of paragraphs with no machine matches. Large manuscripts can
still exceed a context window if the entire prompt is loaded at once. Initial
support is for local prose correction, not chapter reorganization.

Source hashes are checked before generating a prompt. Modified sources, modified
session artifacts, and incompatible session versions require a fresh scan.
`review scan`, `review prompt`, and `review verify` accept `--lang ja`; prompt and
verify check the value against the session language. A non-Japanese language in
`--lang`, `review.language`, or an explicit AsciiDoc `:lang:` attribute is rejected.
An omitted `:lang:` attribute uses the selected review language.

### Verify

```sh
asciidoc-pubkit review verify .pubkit/review
```

For prose sessions, verification compares the current source set, document structure, content outside
reviewed paragraphs, and recognized protected inline tokens with the baseline.
It reports remaining candidates and numeric changes separately. Existing candidates
do not make verification fail. Numeric changes require manual review but do not
by themselves fail mechanical verification.

Non-prose comparison ignores empty separator lines and trailing whitespace;
listing, literal, and passthrough block content is additionally compared as parsed
lines. Inline protection is heuristic, not a complete AsciiDoc inline parser.
Successful verification does not prove meaning preservation, technical accuracy,
or release readiness: `meaning_verified` is always `false`. Verification does
not read candidate decision records or certify editorial completion. A passing
mechanical result must be reported separately from the reviewer's quality and
completion assessment.

| Exit code | Meaning |
| --- | --- |
| `0` | Command completed; verification found no mechanical violations |
| `1` | Verification found protected-content, structure, source, or parsing issues |
| `2` | Invalid arguments, configuration, session, scan input, or output failure |

[Back to README](../README.md)
