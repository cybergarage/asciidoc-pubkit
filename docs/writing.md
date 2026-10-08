# Writing commands

`writing criteria` prints the packaged common criteria. `writing prompt` adds
task instructions around those same criteria. Neither command needs an AsciiDoc
file, a review session, MeCab, or network access. Both accept `--lang ja` and
`--output FILE`; output defaults to stdout, and an existing output file is never
overwritten. The prompt asks the agent to read project instructions and evidence;
it does not supply source facts or authorize edits. Book-specific voice and
format still come from the book. The OSS-only prose style profile remains with
the book workflow, not the shared default.

The criteria also ask reviewers to compare source and revision for
modifier targets, condition and exception scope, quantities and their targets,
parallel relationships, and required order. Preserve each sentence's function
(including advice, obligations, plans, and actual behavior) separately from plain
or polite style. Keep the author's style unless a change is requested or the
book explicitly requires one. Sentence splitting and punctuation changes must
retain the original relationships; these are contextual review instructions,
not automatic semantic checks. Saved sessions retain the criteria from their scan.

The criteria also preserve the comparison axis, completed changes,
current behavior, future plans, and the distinction between event dates and
observation or report dates. An unclear state term does not authorize deleting
its known action. Keep source-provided undecided or investigation status in the
body; put reviewer doubts and questions in the separate report, without adding
editing markers to the manuscript.

The shared criteria also distinguish human roles from human-versus-AI
comparisons. Terms such as `開発者`, `利用者`, `評価担当者`, and `文書の作成者`
are evidence-based alternatives to `人`, not a replacement dictionary. Preserve
general populations and established research concepts, and do not introduce
new permissions or imply that different roles require different people.
Heading criteria connect terminology changes with the section's body and
separately proposed table, figure, and alternative-text synchronization.

```sh
asciidoc-pubkit writing criteria --lang ja
asciidoc-pubkit writing prompt --lang ja --output writing-prompt.md
```

For example, `--lang en` exits with an unsupported-language error. No English
review or writing criteria are shipped in 1.1.0.

For a small trial, use `examples/book.adoc` as the scan input. Its Japanese
paragraphs deliberately contain review candidates; its code block must remain
unchanged.

[Back to README](../README.md)
