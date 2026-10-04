# Configuration

`scan` and `score` search upward from the entrypoint directory for the nearest
`.asciidoc-pubkit.yml`. Use `--config FILE` to select a different file. CLI options
override configuration values; unspecified values use built-in defaults.
The CLI loads one configuration file, not merged book/repository files.

```yaml
review:
  language: ja
  style: desu-masu
  tokenizer: mecab
  # heading_rules: heading-rules.yml  # Separate heading rule set
  # Optional overrides (dictionary paths are relative to this file):
  # mecab_command: /opt/homebrew/bin/mecab
  # mecab_dictionary: /opt/homebrew/lib/mecab/dic/ipadic
  base_dir: .
  glossary: glossary.yml
  exclude:
    - generated/**
  allows: []
  attributes:
    edition: print
```

Configuration paths are relative to the configuration file. Without configuration,
the base directory is the entrypoint's directory. Exclusion patterns match source
paths relative to the base directory; excluded files can still supply attributes
and are preserved by verification. The default style is `preserve`; explicit
alternatives are `desu-masu` and `dearu`. Only `ja` is currently supported.

A glossary maps canonical terms to variant strings:

```yaml
JavaScript:
  - Javascript
  - Java Script
```

Variants are review candidates, not automatic replacement instructions. In MeCab
mode, `allows` can suppress a canonical dictionary form (all its inflections) or
an exact matched surface (that occurrence's form only). In literal mode it
suppresses exact dictionary entries. It does not disable glossary checks.
Regex patterns are not interpreted in glossary or allow-list entries. Unknown
configuration keys are rejected. A bare `mecab_command` is resolved through PATH;
use an absolute path for an explicit executable override.

[Back to README](../README.md)
