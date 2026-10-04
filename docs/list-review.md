# List review

List review checks wording in unordered and ordered list items, including
reference-list descriptions. For example, the description following this link
is list text and is excluded from the default running-prose review:

```adoc
* link:https://example.com/cli[CLI documentation]: printとJSON/RPCの入口を説明しています。
```

AsciiDoc parses list items separately from ordinary paragraphs. The tool keeps
these review scopes separate to map editable text and verify preservation of
list markers, nesting, links, and inline syntax. This is a scope and preservation
choice, not a claim that list descriptions are outside the book's body or an
exclusion made to improve processing speed.

Use this optional phase when list descriptions are part of the requested review,
including a whole-book editorial pass. Omit it for an explicitly prose-only or
heading-only assignment, or when there is no eligible list text. Report omitted
and unsupported list content as unreviewed; successful prose verification does
not establish that lists were reviewed. A zero-item list scan still requires
inspection of coverage notices.

Use a separate session:

```sh
asciidoc-pubkit review scan book.adoc --scope lists --output .pubkit/lists
asciidoc-pubkit review prompt .pubkit/lists --output lists-review.md
# Ask the reviewer to read the prompt and edit only selected list text.
asciidoc-pubkit review verify .pubkit/lists
```

The default output directory is `.pubkit/lists`. This scope reuses prose rules,
glossary, style, analyzer, and shared writing criteria. It does not include running
prose or edit headings. Each selected item appears once with heading context;
read additional evidence separately when its technical role cannot be established.

Only exact source-mapped, single-line simple unordered or ordered item text is
editable, including supported nested outline lists. Multiline, description,
checklist, compound, ambiguous, and reused-source items remain protected with
coverage notices. List markers, nesting, structure, links, and other inline tokens
remain protected. Candidate columns include the source marker and indentation.
Session JSON retains the `paragraphs` and `paragraph_id` keys, with
`kind: list-item` and source `column`, `prefix`, and `suffix` metadata.

Default prose scanning, scoring, and mechanical replacement keep their existing
prose scope. Heading body evidence continues to omit lists. A successful verify
checks preservation and does not establish editorial completion.

[Back to README](../README.md)
