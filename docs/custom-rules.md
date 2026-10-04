# Customize review rules

The UTF-8 YAML file [`data/review-rules.ja.yml`](../data/review-rules.ja.yml) is
included in the gem and loaded by default. Edit that file when running a local
checkout, or copy it to a project-owned file for custom rules. No Ruby changes
are required to update candidate terms.

```sh
asciidoc-pubkit review scan book.adoc --rules ./review-rules.yml
make run ARGS="review scan book.adoc --rules ./review-rules.yml"
```

For an installed gem, copy the default file with:

```sh
ruby -rasciidoc_pubkit -e 'puts File.read(AsciidocPubkit::RuleSet::DEFAULT_PATH)' > review-rules.yml
```

Alternatively, configure a path in `.asciidoc-pubkit.yml`:

```yaml
review:
  rules: review-rules.yml
```

Precedence is `--rules`, then `review.rules`, then the packaged default.
CLI paths are relative to the current working directory; configuration paths
are relative to the configuration file. A custom file replaces the entire rule
set; it is not merged with defaults. Start by copying the standard file.

### Rule file format (schema version 1)

All top-level fields below are required. Unknown keys and invalid types are
rejected. YAML aliases and object tags are not supported.

| Field | Format and behavior |
| --- | --- |
| `schema_version` | Integer `1` |
| `terms` | Mapping containing all five categories listed below |
| `verbs` | Mapping from canonical verb forms to nonempty arrays of MeCab/IPADIC dictionary forms; each dictionary form belongs to only one canonical form |
| `sahen` | Array of nouns matched with a following `する` or potential `できる` verb |
| `negative_only` | Array of canonical predicates restricted to negative forms; use the noun plus `する` for sahen predicates |
| `compound_nouns` | Array of terms matched across contiguous noun tokens; each must also appear in `abstract-reference.terms` |

Each `terms` category must contain `terms` (an array of unique nonempty strings)
and `question` (a nonempty review instruction string). The required categories
are `abstract-reference`, `weak-predicate`, `vague-degree`, `contextual-phrase`,
and `generic-framing`. Empty term arrays disable that category's literal
candidates. Empty `verbs`, `sahen`, and `compound_nouns` collections disable their
respective morphological matchers. Keep `negative_only` consistent with the
configured predicates.

In literal mode, all category term lists use exact phrase matching. In MeCab
mode, abstract nouns and degree adjectives use dictionary forms, while predicates
use `verbs` and `sahen`; add a predicate's desired literal surface to
`weak-predicate.terms` as well if literal mode should detect it. Contextual and
generic framing phrases use literal matching in both modes, with the
MeCab exception for the four configured contextual predicate patterns described
in [rules and coverage](rules-and-coverage.md). Questions apply to
both detectors. Glossary, style, repeated-ending checks, inline exclusions, and
morphological suffix handling remain implemented in Ruby.

A scan saves the resolved rule contents and source path in `manifest.json`.
Prompt generation and verification use the saved contents, even if the original
YAML file is subsequently edited or removed. Start a new session to apply rule
changes. Sessions require the same tool version that created them; preserve old
baselines and start a separate new session when upgrading.

[Back to README](../README.md)
