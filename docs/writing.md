# Writing commands

`writing criteria` prints the packaged common criteria. `writing prompt` adds
task instructions around those same criteria. Neither command needs an AsciiDoc
file, a review session, MeCab, or network access. Both accept `--lang ja` and
`--output FILE`; output defaults to stdout, and an existing output file is never
overwritten. The prompt asks the agent to read project instructions and evidence;
it does not supply source facts or authorize edits. Book-specific voice and
format still come from the book. The OSS-only prose style profile remains with
the book workflow, not the shared default.

The unreleased criteria also ask reviewers to compare source and revision for
modifier targets, condition and exception scope, quantities and their targets,
parallel relationships, and required order. Preserve each sentence's function
(including advice, obligations, plans, and actual behavior) separately from plain
or polite style. Keep the author's style unless a change is requested or the
book explicitly requires one. Sentence splitting and punctuation changes must
retain the original relationships; these are contextual review instructions,
not automatic semantic checks. Saved sessions retain the criteria from their scan.

```sh
asciidoc-pubkit writing criteria --lang ja
asciidoc-pubkit writing prompt --lang ja --output writing-prompt.md
```

For example, `--lang en` exits with an unsupported-language error. No English
review or writing criteria are shipped in 1.0.0.

For a small trial, use `examples/book.adoc` as the scan input. Its Japanese
paragraphs deliberately contain review candidates; its code block must remain
unchanged.

[Back to README](../README.md)
