# Prose replacements

The replacement commands apply author-supplied mechanical replacement rules without MeCab or an AI
CLI. Review candidates and glossary variants remain advisory and are never
implicitly applied. Replacement rules are separate from review rules.

```sh
asciidoc-pubkit replace check book.adoc --rules replacements.yml
asciidoc-pubkit replace diff book.adoc --rules replacements.yml
asciidoc-pubkit replace apply book.adoc --rules replacements.yml
```

`check` reports original text, proposed text, rule IDs (`rule-1`, etc.), source
paths, one-based Unicode lines/columns, and a coverage-notice count. Its exit code
is 1 when replacements are available, 0 otherwise. `diff` previews unified diffs
without editing; it requires the external `diff` command. `apply` explicitly
authorizes source replacement without prompting. Successful diff/apply commands
return 0; invalid rules, conflicts, unsafe edits, and input/output failures return
2. Check/diff accept `--output` for a new file only; apply rejects `--output`.

Starting with version 0.8.2, invalid rule files report their original YAML file
and one-based line number on the first error line, followed by the existing
reason on the next line. Imported files and entries in pattern arrays retain
their own source locations. For example:

```text
Error: /path/to/prh.yml:162
Unsupported regex flags; only optional i is supported (all matches are collected).
```

Rules are validated before any manuscript is replaced. All replacement commands
stop with exit code 2 on invalid rules, including errors found in imported files.

All three accept `--lang ja`, `--base-dir`, `--config`, and `--only` (an included
source file). Normal configuration discovery and `review.base_dir`, `language`,
`attributes`, and `exclude` control parsing and selection. `--rules` is required;
`review.rules` and glossary entries do not supply replacement rules. There are
no built-in replacement rules and no automatic search for `prh.yml`.

### Limited prh-format rules

The supported format is a strict subset of [prh](https://github.com/prh/prh):

```yaml
version: 1
rules:
  - expected: '®'
    pattern: '&reg;'
  - expected: '($1)'
    pattern: '/（([^（）\r\n]+)）/'
    specs:
      - from: '設定（任意）'
        to: '設定(任意)'
  - expected: '/'
    patterns:
      - '／'
```

The root requires `version: 1` and accepts optional `rules` and `imports` arrays.
Starting with version 0.8.1, omitted arrays default to empty. Version 0.8.0
requires `rules` and rejects `imports`. Each rule requires a string
`expected` (empty strings permit deletion) and exactly one of `pattern` (a
nonempty string or, starting with version 0.8.1, a nonempty array of nonempty
strings) or `patterns` (a nonempty array of nonempty strings). Array-valued
`pattern` is equivalent to `patterns`; specifying both keys is rejected. Optional
`specs` is an array of exact `from`/`to` string pairs, validated on load. Specs
exercise the rule on plain text, not AsciiDoc selection or inline protection.

Strings not beginning with `/` match literally. `/.../` denotes a regex; the
version 0.8.1 also accepts `/.../i` for Ruby case-insensitive matching.
Version 0.8.0 rejects all flags. All occurrences are collected. The implementation
uses Ruby regexes with
a timeout and accepts a limited common syntax: character classes, ordinary
captures, noncapturing groups, lookarounds, alternatives, anchors, quantifiers,
and the escapes `\n`, `\r`, `\t`, `\d`, `\D`, `\s`, `\S`, `\w`, `\W`
and escaped punctuation. Ruby regex character-class behavior applies; this is
not a JavaScript regex engine or a promise of full prh equivalence. Engine-specific
groups/escapes and flags other than a single `i` are rejected. A leading literal slash must be expressed
as an escaped regex, for example `/\//`. Zero-length matches are rejected.

Replacement strings support `$1` through `$99` for existing capture groups and
`$$` for a literal dollar sign. Unsupported dollar references are rejected when
matched. Missing optional captures expand to empty strings. YAML single quotes
are recommended to keep backslashes literal. Unknown fields, including
`options` and `regexpMustEmpty`, and omitted patterns are rejected rather than
ignored. prh's automatic pattern generation is not supported.

For example, version 0.8.1 also accepts:

```yaml
version: 1
rules:
  - expected: 'ハードウェア'
    pattern:
      - 'ハードウエア'
      - 'ハードウェアー'
```

Each array entry uses the same literal/regex syntax and validation as a single
pattern. Arrays do not change supported flags or overlap handling.

### Limited ECMAScript boundary compatibility

Version 0.8.1 translates `\b` and `\B` outside character classes into Ruby
lookarounds with ECMAScript word-character semantics, following prh's default
Unicode mode. Word characters are ASCII letters, digits, and underscore; Japanese
characters are non-word characters. Thus `/\bTips\b/` matches `Tips` in
`前Tips後`, but not in `Tips2`, `_Tips`, or `ATips`.
With `/i`, long s (`ſ`) and Kelvin sign (`K`) also count as word characters under
ECMAScript Unicode case folding. The generated assertions add no capture groups
and preserve original match offsets. Inside a character class, `\b` means a
backspace character; `\B` there is rejected. Escaped literal backslashes are
preserved.

Only the boundary assertions emulate ECMAScript. `/i` uses Ruby's
`Regexp::IGNORECASE`; Unicode case folding can differ from JavaScript (for
example multi-character folds). Other constructs, including whitespace classes,
retain Ruby semantics. This is limited prh compatibility, not full ECMAScript
conformance. Flags `g`, `m`, `s`, `u`, `y`, `d`, and `v` and duplicate `i` are
rejected; all occurrences are already collected independently of `g`.

### Importing replacement rules

Version 0.8.1 supports nested `imports`; version 0.8.0 does not. For example:

```yaml
version: 1
imports:
  - ../../rules/prh.yml
  - path: ./terminology.yml
rules:
  - expected: '®'
    pattern: '&reg;'
```

Each entry is a nonempty local file path string or a mapping containing exactly
`path`. Relative paths resolve from the importing YAML file, including nested
imports, independently of the working directory and manuscript base directory.
Absolute local paths are also accepted; URL imports are rejected. An import-only
file may omit `rules`. A file containing only `version: 1` is also valid and
contributes no rules. With no imported or local rules, `check`, `diff`, and
`apply` succeed without changing manuscript sources, and `diff` emits no patch.
Starting with version 0.8.1, a bare `rules:`, `rules: null`, and `rules: ~`
also contribute no local rules, just like omission or `rules: []`; imported rules
are still loaded. Other non-array values remain invalid. This normalization
applies only to `rules`, not to `imports` or individual rule fields.
Every imported file must use version 1 and pass the same
strict rule validation and specs as the entry file.

Imports are loaded in listed order, recursively before each file's own rules.
Each physical file is loaded once per plan, including repeated paths, symlink
aliases, and shared dependencies. Rule IDs are assigned across the flattened
set. Cycles (including symlink aliases), missing files, and import chains deeper
than 100 files fail rather than silently omitting rules. Imported and local rules
are combined, not overridden: overlapping replacement candidates remain errors
and replacements are still calculated only against the original text.

Import options such as `ignoreRules` and `disableImports` remain unsupported and
are rejected. Source selection and protection are unchanged by imports.

### Selection and preservation

Only unambiguously source-mapped running prose in the existing default review
scope is eligible. Headings, lists, tables, quotations, listing/source, literal,
and passthrough blocks are excluded. Recognized inline code, quotations, URLs,
macros, and attribute references are protected by the existing conservative
inline heuristic, not a complete inline parser. A match overlapping any protected
span is skipped; matching is performed on the original text, never on blanked
placeholders. Backtick-to-bold and list-marker conversions are outside this scope.

Candidates are calculated once against the original sources; replacement results
are not searched again. Overlapping edits are conflicts, not resolved by rule
order. Matches/results containing line breaks are rejected. Source files retain
UTF-8 bytes, original line endings, and unrelated content; repeated include
occurrences must not create overlapping edits.

Before presenting a plan, the complete captured source set is copied to temporary
staging and reparsed. Parsing diagnostics, structural changes, new/deleted protected
inline tokens, and protected-content/source-membership changes reject the plan.
Relative includes within the base directory are supported. Absolute includes and
includes whose paths depend on the original filesystem may fail staged validation;
they are not rewritten or silently accepted. Symlink entrypoints are rejected.

Apply stages all changed files beside their destinations, checks all captured
source bytes against the plan, and renames the prepared files into place while
preserving permission bits. An ordinary installation error restores sources
already installed. This is not a crash-atomic transaction across multiple files;
keep manuscripts under version control and avoid concurrent edits during apply.
No review session is created or replaced. Existing sessions retain their original
baselines; applying replacements can make a session stale for prompt generation.
Mechanical validation does not establish semantic correctness.

[Back to README](../README.md)
