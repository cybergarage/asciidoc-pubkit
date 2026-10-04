# Document commands

Version 1.0.0 provides four read-only document commands. They require neither
MeCab nor an AI CLI, accept documents in any language, and do not create review
sessions or change manuscripts.

```sh
asciidoc-pubkit document toc book.adoc --depth 2 --numbered
asciidoc-pubkit document info book.adoc --json
asciidoc-pubkit document check-xrefs book.adoc --json
asciidoc-pubkit document index . --output index.adoc --title "Index"
```

All four require exactly one input. Use `--help` for command-specific options.
Output defaults to stdout. `--output FILE` creates a new file and rejects existing
files and symlinks. Diagnostics go to stderr. These commands do not discover
`.asciidoc-pubkit.yml` or load review rules. Use repeatable `-a NAME=VALUE` options
for Asciidoctor attributes and `--base-dir DIR` for the local include boundary.
The default boundary is the input file's directory, or the scanned directory for
`index`. Local includes and conditional directives are parsed normally; source
files and symlink targets must remain within that boundary. Remote includes are
rejected. `/shared/` has no special mapping or automatic exclusion: migrate such
references to local includes within the configured boundary.

`toc` prints parsed section titles in document order, with two spaces per nesting
level. It includes book parts and their child chapters, but excludes the document
title and apparent headings inside code blocks. `--numbered` uses outline
positions (`1.`, `1-1.`, etc.), independently of Asciidoctor's publication
numbering. `--depth` must be a positive integer and limits the Asciidoctor section
level: chapters are level 1 and book parts are level 0. It does not generate or
rewrite heading text.

`info` prints `key: value` lines or a JSON object with `--json`. Its fields are
`doctitle`, `subtitle`, `description`, `keywords`, `lang`, `uuid`, `author`,
`producer`, and `creator`. Missing attributes become empty strings. Metadata is
extracted from the parsed document, including active local includes.

`check-xrefs` reports unresolved local `xref:ID[]` and `<<ID,label>>` references,
including fragments targeting the entry document or an included file. It
recognizes explicit and generated IDs and attribute-expanded targets. It scans
macro-enabled block text, list items, table cells, and titles; comments and
ordinary code blocks are excluded. References to separate documents and remote
URLs are outside its scope. This is a limited syntax scan, not complete rendered
link validation: complex inline passthroughs and custom macros are not analyzed.
Text output has `file:line`, a tab, and the missing ID; JSON output is an array of
`refid`, `file`, and `line` objects. Locations use Asciidoctor source cursors;
table cells, list continuations, and multiline titles may identify the enclosing node's start
rather than the exact token line. Duplicate occurrences of one ID on the same
source line are reported once.

`index` recursively scans lowercase `.adoc` files, skips hidden subdirectories
and its output path, and uses each document's ID and title. It produces an
AsciiDoc alphabetical cross-reference list for English names: parenthesized
text and subtitles after `:` or `：` are removed; remaining titles must be ASCII
and contain a letter. Documents without IDs are omitted. Titles are deduplicated
case-insensitively, preferring the shallowest relative path and then lexical path
order. `--title` adds a document title with `[#book-index]`; alphabetical groups
use discrete level-2 headings (`=== A`). This indexes document titles, not all
section headings. The generated references are useful when those documents are
included in the consuming book; the command does not verify that membership.

Success returns 0. `check-xrefs` returns 1 when local references are unresolved.
Invalid inputs/options, include or parse errors, and output failures return 2;
no output file is created on a parse error. Warnings remain visible on stderr.
Unlike the original directory index script, an input parse error fails the whole
index instead of silently omitting the file.

[Back to README](../README.md)
