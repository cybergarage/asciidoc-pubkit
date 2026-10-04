# Score an AsciiDoc manuscript

Pass any AsciiDoc entry file directly; no review session or gold annotations are
required. Output defaults to a short English report with a score out of 100.

```sh
asciidoc-pubkit review score book.adoc
asciidoc-pubkit review score book.adoc --json --output score.json
asciidoc-pubkit review score book.adoc --agent codex
asciidoc-pubkit review score book.adoc --agent claude --json
```

Without `--agent`, the report shows a mechanical candidate-density indicator.
With `--agent`, it shows a model readability rating and retains the mechanical
score in JSON. See [How review and scoring work](architecture.md#how-review-and-scoring-work)
for the analysis pipeline, formulas, and interpretation of these different scores.
Successful scoring exits 0 regardless of the score; input, configuration,
analyzer, evaluator, or output failures exit 2. No scoring mode establishes
technical accuracy or meaning preservation; `meaning_verified` remains `false`.

Scoring uses the same configuration discovery, custom rules, glossary, allows,
style, language, base directory, include handling, and prose coverage as scanning.
It accepts `--only`, `--config`, `--rules`, `--base-dir`, `--tokenizer`, `--style`,
`--lang ja`, and repeated `--attribute` options. Excluded, unmapped, and protected
blocks are not prose-scored. Coverage notices remain important when interpreting
a score. MeCab/IPADIC is the default; literal mode must be selected explicitly.

AI evaluation requires an installed, authenticated Codex or Claude CLI, and may
send the selected paragraph text and headings to its configured provider and
consume account usage. It receives no candidate findings or source file paths.
`--model` selects the evaluator model, and `--timeout` sets the invocation timeout
(default 300 seconds); both require `--agent`. Temporary evaluation files are
removed after scoring. Use `--json --output FILE` to retain the result. Output
files are never overwritten, and existing output is rejected before invoking an
evaluator. A file with no unmasked prose is not sent to an evaluator.

[Back to README](../README.md)
