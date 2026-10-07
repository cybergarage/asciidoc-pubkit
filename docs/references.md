# References

The shared criteria and default questions draw on the following editorial
sources. Their stylistic choices differ, including whether headings should state
conclusions. Candidate detection therefore leaves contextual judgment, document
structure, and final edits to the reviewer.

- [natural-japanese](https://github.com/coji/natural-japanese): separates mechanical
  detection from contextual judgment and identifies repetitive framing. Applied
  here: candidate findings feed a contextual review prompt, while phrases such as
  `重要なのは` and `このように` invite inspection rather than automatic deletion.
- [yomiyasu](https://github.com/nanaism/yomiyasu):
  informs evidence-based review of
  metaphorical operations, distinctions between instructions and capabilities,
  and separate assessment of meaning preservation and readability. Applied here:
  four limited metaphor patterns and third-sentence repetition locations inform
  candidate detection; the shared criteria require evidence for concrete rewrites.
  The 1.0.1 update adapts the structural comparison and sentence-function
  guidance from [v1.0.6, commit 4075fc3](https://github.com/nanaism/yomiyasu/commit/4075fc34fb0333ca1fe42d32cd619338f4a138ba):
  compare modifier and quantity targets, condition scope, parallel relationships,
  and order before and after revision; preserve sentence function separately
  from plain or polite style. The new examples are original project fixtures.
  Markdown-specific bold fixes and numeric style thresholds are not imported.
  The 1.0.3 update adapts [v1.0.8, commit 9b9a847](https://github.com/nanaism/yomiyasu/commit/9b9a84757ade524ef9d477f75c6ea13190079f97)
  for comparison axes, tense and event/report dates, and retaining known actions
  when state terms are unclear. Source uncertainty remains in the manuscript;
  editorial questions remain in the separate report. Regression tests preserve
  paragraph boundaries and ordinary line wrapping. These are project-authored
  examples; Markdown-specific scanner and updater implementations are not imported.
- [日本語技術文書の文章規範](https://gist.github.com/k16shikano/fd287c3133457c4fd8f5601d34aa817d):
  informs paragraph logic, evidence scope, and meaningful uncertainty. Applied
  here: the shared criteria start from each paragraph's technical purpose and
  preserve necessary conditions, uncertainty, and exact terminology.
- [AI臭い文章とは何なのか](https://speakerdeck.com/nasuvitz/ai-kusai-bunshou-toha-nanina-no-ka):
  provides examples of unnecessary contrast, abstract referents, and paired short
  sentences. Applied here: the shared criteria ask reviewers to inspect these
  patterns in context and recover concrete referents and connected explanations.

The development evaluation adapts ideas from the following primary research;
its engineering audience, corpus, and rubric do not reproduce those benchmarks.
Research texts and datasets are not redistributed here.

- [Evaluation of Document-Level Text Simplification in Japanese](https://aclanthology.org/2026.lrec-1.85/)
  (Yamashita et al., LREC 2026): separates information preservation from sentence
  and document simplicity and evaluates LLM judgments against human annotations.
  Its elementary-school audience and Wikipedia corpus differ from this project.
  Applied here: the scoring rubric separates sentence clarity from paragraph
  coherence, and the development judge evaluates fact retention independently.
- [Evaluating Factuality in Text Simplification](https://aclanthology.org/2022.acl-long.506/)
  (Devaraj et al., ACL 2022): distinguishes insertion, deletion, and substitution
  errors. Applied here: development trials check each source fact and report
  unsupported additions and substitutions separately; a readable rewrite can
  still fail preservation review.
- [Evaluating Document Simplification: On the Importance of Separately Assessing Simplicity and Meaning Preservation](https://aclanthology.org/2024.readi-1.1/)
  (Cripwell et al., READI 2024): motivates separate readability and preservation
  scores. Applied here: readability dimensions and preservation outcomes remain
  separate in benchmark reports; the direct manuscript score makes no
  preservation claim. SARI-style overlap metrics are not adopted.

[Back to README](../README.md)
