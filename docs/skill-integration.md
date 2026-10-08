# Integrate manuscript review into an agent skill

Use the [CLI tutorial](agent-review-tutorial.md) to try individual commands first.
A skill makes the same process reusable: the agent selects the manuscript,
executes the commands, reads the generated prompt, edits within scope, verifies
and records progress. Pubkit still performs parsing and preservation checks;
it does not discover skills or launch a reviewer.

## Responsibilities

```mermaid
flowchart TD
    U["Author: assignment and edit authorization"] --> K["Agent reads the review skill"]
    I["Author instructions and optional review records"] --> K
    K --> S["Agent runs pubkit scan"]
    S --> B["Saved session and baseline"]
    B --> P["Agent runs pubkit prompt"]
    P --> R["Agent reads saved criteria and manuscript evidence"]
    R --> E["Agent reviews or edits the assigned scope"]
    E --> V["Agent runs pubkit verify"]
    B --> V
    V --> C["Agent records decisions, results and pending work"]
    C --> N["Next assigned phase after successful verification"]
```

| Owner | Responsibility |
| --- | --- |
| Author and book instructions | Readers, style, technical evidence, assignment and publication decisions |
| Review skill | Scope selection, phase order, tool invocation, resumption and progress recording |
| Generated pubkit prompt | Criteria frozen at scanning, selected entries, candidates and edit permissions |
| Codex or Claude reviewer | Evidence-based decisions, authorized edits and unresolved proposals |
| Pubkit verification | Mechanical preservation against the saved baseline |

Keep shared prose and heading criteria in pubkit instead of copying them into
each skill. Skill instructions should explain when and how to use the tool,
while book instructions retain book-specific terminology and technology versions.

## A minimal reusable example

The gem includes [review-asciidoc-manuscript/SKILL.md](../examples/skills/review-asciidoc-manuscript/SKILL.md).
It is a standalone example, not an automatically installed skill. Read it before
adapting it to your project. It supports full review, single-scope review and
diagnosis without adding publication or external-message permissions.

Store the example wherever your project keeps reusable agent instructions.
One possible layout is:

```text
manuscript-project/
  book.adoc
  AGENTS.md                 # Optional project instructions
  .agents/skills/review-asciidoc-manuscript/SKILL.md
```

The `.agents/skills` path above is an example, not a pubkit requirement.
Skill discovery and installation depend on your agent and project. Use the
location configured for that environment; pubkit does not install the example.
When automatic discovery is unavailable, explicitly ask Codex or Claude to read
the file and follow it. This file-based handoff needs no agent-specific CLI flags.

Example request for either reviewer:

```text
Read .agents/skills/review-asciidoc-manuscript/SKILL.md and the project's
instructions, if present. Review book.adoc in headings, prose and supported
list phases. Use the author's requested style and terminology.
Use a new pass named review-book-02, preserve previous baselines and unrelated
edits and verify each phase before the next scan. Update an existing review
record if available; otherwise save decisions alongside each session.
Report applied changes, reviewed/pending IDs and coverage limits.
```

For outline diagnosis only:

```text
Read .agents/skills/review-asciidoc-manuscript/SKILL.md. Diagnose book.adoc's
headings through parsed level 2 using a fresh review-toc-02 session and an outline
prompt. Do not edit the manuscript. Record title/body agreement, reading order,
keep/revise/needs-evidence decisions and separate structural proposals.
```

The agent checks the installed tool before using 1.1.0 options. A new session
does not upgrade an old baseline or certify preservation against it.

## Commands the skill orchestrates

For a heading-only assignment, the agent runs the following from the manuscript
directory, reading the prompt and completing the assigned review between prompt
and verify. Substitute unused pass names and the project's CLI invocation.

```sh
asciidoc-pubkit --version
asciidoc-pubkit review scan --help
asciidoc-pubkit review scan book.adoc --scope headings --lang ja \
  --output .pubkit/review-book-02-headings --no-input
asciidoc-pubkit review prompt .pubkit/review-book-02-headings --view outline \
  --mode revise --output .pubkit/review-book-02-headings/prompt.md
# Agent reads the prompt, records decisions and applies authorized title edits.
asciidoc-pubkit review verify .pubkit/review-book-02-headings \
  --output .pubkit/review-book-02-headings/verification-01.json
```

For a full review, proceed to fresh prose and list sessions only after the
preceding phase is finished and verifies. The [CLI tutorial](agent-review-tutorial.md#4-review-prose-then-list-text)
contains those command sequences. Do not scan all phases first: the later
baseline must capture earlier authorized edits. A pending integrity or
preservation failure blocks that phase boundary, not unrelated read-only work.

Use generated criteria rather than a second writing prompt. Keep the session's
four baseline artifacts immutable; adding prompt, decision and verification
reports beside them is permitted. Existing output files cannot be overwritten.

## Adapt the skill to your project

Provide the book's entrypoint and the source files covered by the assignment.
For a multi-file book, derive reading order from active includes rather than
assuming a `chapters` directory or fixed filenames. A chapter-limited request
uses the publication entrypoint with `--only`; a whole-book request uses that
entrypoint without the filter. The [CLI tutorial](agent-review-tutorial.md#6-apply-the-workflow-to-your-own-book)
shows an included-chapter example.

The author supplies the intended readers, style, terminology and technical
evidence. Read existing project instructions when available; a file named
`AGENTS.md` and dedicated plan, structure or progress files are optional.
Use the project's existing review records if available. Otherwise save a
local decision report alongside each session, keeping the four baseline
artifacts unchanged. Do not introduce a competing record into a project that
already has one. Pubkit does not prescribe or validate report filenames.

Select the project's installed invocation, such as `asciidoc-pubkit` or
`bundle exec asciidoc-pubkit`. Record its version. Use the author's publishing
attributes and base directory; do not rewrite include conventions merely to
make a scan succeed. The example requires Japanese review support and MeCab
with UTF-8 IPADIC by default. It does not enable review in other languages.

Adapt checks to the actual project: inspect diffs, validate local references,
and run existing lint or build commands when requested. No particular Make
targets, EPUB tooling or publishing service are required by the skill. Keep
mechanical preservation, editorial completion, book build checks and publication
approval as separate recorded results. Applying the example does not authorize
publishing the book or changing another project's files.

[CLI tutorial](agent-review-tutorial.md) · [Review reference](review-workflow.md) ·
[Back to README](../README.md)
