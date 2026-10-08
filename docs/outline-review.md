# Outline review

Version 1.1.0 extends document inspection and heading sessions for reviewing
a book's table of contents. These commands do not invoke an AI CLI or rewrite
the manuscript. Provide the generated prompt to your external reviewer.

## Inspect the outline

```sh
asciidoc-pubkit document toc book.adoc --depth 3
asciidoc-pubkit document toc book.adoc --depth 3 --json --output toc.json
```

Depth is the maximum parsed Asciidoctor section level, not a chapter count or
indentation count. Parts can be level 0; include offsets affect actual levels.
Inspect the outline before selecting a depth. Discrete headings and apparent
titles inside code blocks are excluded from the section outline.

JSON has `schema_version: 1`, the absolute `entry` path, requested `depth` (null
when unlimited), and a flat `headings` array in document order. Each entry contains:

| Field | Meaning |
| --- | --- |
| `index`, `parent_index` | Zero-based position and parent position within this output; roots have a null parent |
| `level`, `nesting` | Parsed section level and zero-based outline nesting |
| `number` | Outline position such as `1-2`, independently of publication numbering |
| `section_id`, `title` | Parsed ID and title after attribute/inline processing |
| `file`, `line` | Source cursor location; unavailable positions are null |
| `source_title` | Original plain ATX title text, including unexpanded attributes; null when unavailable |

`--numbered` affects text output only; JSON always contains `number`. Positions
and outline numbers are local to that report, not durable review identifiers.
Source locations and raw titles are informational: JSON does not grant editing
permission or prove that a title is unambiguously editable. Use heading sessions
for source mapping, reuse checks, saved anchor permissions and verification.
Document inspection accepts any language and requires neither MeCab nor an AI.
Output must be new. Existing files and symlinks are rejected.

## Select a heading depth

```sh
asciidoc-pubkit review scan book.adoc --scope headings --depth 3 \
  --output .pubkit/toc-review --no-input
```

`--depth` accepts a positive integer and is valid only for heading scans. Without
it or configuration, all eligible levels are selected as before. A book can set
`review.heading_depth` in `.asciidoc-pubkit.yml`; the CLI overrides that value.
This configuration applies only to heading sessions, not prose or lists.

The effective limit is saved as `settings.heading_depth`. The full outline and
existing mapped prose context remain reference evidence, including deeper
sections. Deeper titles stay protected and get coverage notices. `--only`,
exclusions and source-mapping restrictions still apply. Reuse is checked before
depth filtering, so a title reused deeper cannot become editable by hiding that
occurrence. A scan with no eligible titles still reports outline and coverage;
it does not establish successful editorial review.

## Generate an outline-oriented prompt

```sh
asciidoc-pubkit review prompt .pubkit/toc-review --view outline \
  --mode diagnose --output toc-diagnosis.md
asciidoc-pubkit review prompt .pubkit/toc-review --view outline \
  --mode revise --output toc-revision.md
# After the external review and authorized title edits:
asciidoc-pubkit review verify .pubkit/toc-review --output toc-verification.json
```

`--view full` remains the default. Outline view requires a heading session. It
displays a numbered, indented outline with source positions and
`editable`/`reference-only` labels, selected mapped headings and findings, and
the same read-only body context once per paragraph in the same Markdown file.
Only selected-heading metadata grants title/anchor permissions. All excerpts
stay fenced as data, even when titles contain backticks.

Additional criteria consider reader prerequisites, subject coverage, reading
order, parent/child correspondence, sibling granularity, terminology and the
book's specified style. A nominal preference is advisory and must retain
conditions, order and technical distinctions. It does not impose a common chapter
pattern, keyword list or fixed title length. The existing heading-rule
`style: nominal` preference can be used without a new style rule.

The outline cannot establish agreement with the body by itself. Reviewers must
read supplied context and record missing evidence, including omitted tables,
figures and code. They record selected heading IDs, current/proposed titles,
`keep`/`revise`/`needs-evidence`, reasons, evidence and separate synchronization
proposals. These are reviewer instructions, not automatic decision validation
or a semantic score.

## Preservation and existing sessions

Outline criteria are saved as `manifest.outline_criteria` at scan time and do not
change when installed criteria later change. Older sessions without that field
continue to support full prompts and their original verification, subject to
the exact tool-version requirement. For outline view, create a fresh session in
a different directory; do not replace an ongoing baseline or modify its artifacts.

Changing views does not change selection or verification. Only selected plain
ATX title spans and exact saved ID anchors may be edited. Body, unselected and
attribute-expanded titles, IDs, hierarchy, order and includes remain protected.
Moves, merges, splits and new sections are separate structure proposals, not
permitted edits. Body/table/figure synchronization requires its own authorized
scope and verification. Baseline integrity and stale-source checks still apply.
Verification remains mechanical and keeps `meaning_verified: false`; success
does not establish editorial completeness, semantic correctness or EPUB readiness.

For an end-to-end agent handoff, see the [agent review tutorial](agent-review-tutorial.md).

[Back to README](../README.md)
