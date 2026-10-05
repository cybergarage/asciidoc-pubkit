# Development

```sh
bundle install
bundle exec rake test
bundle exec ruby -Ilib exe/asciidoc-pubkit --help
gem build asciidoc-pubkit.gemspec
```

The tests exercise include-boundary mapping, inline masking, configuration,
contextual prompts, stale inputs, protected-content verification, and real MeCab
analysis of inflections, negative predicates, Unicode positions, and long lines.
Install MeCab and UTF-8 IPADIC before running the complete test suite.
GitHub Actions is configured for Ruby 3.2, 3.3, 3.4, and 4.0 on Linux.

## Prose evaluation

The checkout includes fixed Japanese prose fixtures, detector regression tests,
and an optional rewrite-and-judge runner. See [Prose evaluation](prose-evaluation.md)
for the corpus, metrics, test coverage, before/after procedure, and result
interpretation. Normal `rake test` runs do not invoke an AI CLI.

[Back to README](../README.md)
