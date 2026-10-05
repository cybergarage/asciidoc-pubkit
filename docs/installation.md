# Install from RubyGems

Install the CLI from [RubyGems](https://rubygems.org/gems/asciidoc-pubkit):

```sh
gem install asciidoc-pubkit
asciidoc-pubkit --version
asciidoc-pubkit --help
```

Ruby 3.2 or later is required. RubyGems installs the required Ruby dependencies;
no repository clone or Node.js installation is needed. MeCab and IPADIC must be
installed separately when using Japanese review or scoring in the default mode.

Inspect the document, apply explicit replacement rules, and start the review
workflow from your manuscript directory:

```sh
asciidoc-pubkit document toc book.adoc --depth 2 --numbered
asciidoc-pubkit document info book.adoc --json
asciidoc-pubkit document check-xrefs book.adoc
asciidoc-pubkit replace check book.adoc --rules replacements.yml
asciidoc-pubkit replace diff book.adoc --rules replacements.yml
asciidoc-pubkit replace apply book.adoc --rules replacements.yml
# Start a new review baseline after completing mechanical replacements.
asciidoc-pubkit review scan book.adoc --output .pubkit/review
asciidoc-pubkit review prompt .pubkit/review --output review-prompt.md
# Ask your agent to review the prompt and edit the referenced manuscript.
asciidoc-pubkit review verify .pubkit/review --output verification.json
```

To update an existing installation:

```sh
gem update asciidoc-pubkit
```

### Use Bundler in a manuscript project

Add the gem to your project's `Gemfile` to manage its version with Bundler:

```ruby
source 'https://rubygems.org'
gem 'asciidoc-pubkit', '~> 1.0.2'
```

Then install dependencies and run the CLI through Bundler:

```sh
bundle install
bundle exec asciidoc-pubkit document toc book.adoc
bundle exec asciidoc-pubkit replace diff book.adoc --rules replacements.yml
bundle exec asciidoc-pubkit replace apply book.adoc --rules replacements.yml
bundle exec asciidoc-pubkit review scan book.adoc --output .pubkit/review
bundle exec asciidoc-pubkit review prompt .pubkit/review --output review-prompt.md
bundle exec asciidoc-pubkit review verify .pubkit/review --output verification.json
```

Commit `Gemfile` and `Gemfile.lock` in the manuscript project to keep the selected
version reproducible. Use `bundle update asciidoc-pubkit` to update it deliberately.

## Install from source

```sh
git clone https://github.com/cybergarage/asciidoc-pubkit.git
cd asciidoc-pubkit
bundle install
gem build asciidoc-pubkit.gemspec
gem install ./asciidoc-pubkit-1.0.2.gem
asciidoc-pubkit --version
```

The gem name and CLI name are `asciidoc-pubkit`; the Ruby require path is
`asciidoc_pubkit`, and the namespace is `AsciidocPubkit`.

## Run from a local checkout

Use the `run` Make target to execute the checkout without installing the
asciidoc-pubkit gem. Ruby dependencies and, for the default tokenizer, MeCab and
UTF-8 IPADIC must already be installed.

```sh
make run ARGS="--version"
make run ARGS="review scan examples/book.adoc"
make run ARGS='review scan "manuscripts/my book.adoc"'
```

With no `ARGS`, `make run` displays CLI help. Set `RUBY` to choose another Ruby
executable. `ARGS` is shell command-line text; quote paths containing spaces and
use only trusted arguments.

To run from a manuscript directory, select the checkout's Makefile with `-f`.
Relative manuscript paths and output paths remain relative to your current
working directory:

```sh
make -f "$HOME/Src/asciidoc-pubkit/Makefile" run ARGS="review scan book.adoc"
```

Use `ARGS` instead of `make review scan book.adoc`: Make interprets positional
words as build targets, not CLI arguments. Avoid `make -C` when manuscript paths
should remain relative to the current directory, because it changes directories.

## Install the morphological analyzer

On macOS with Homebrew:

```sh
brew install mecab mecab-ipadic
mecab -D
```

On Ubuntu or Debian:

```sh
sudo apt-get update
sudo apt-get install mecab mecab-ipadic-utf8
mecab -D
```

Use a UTF-8 IPADIC dictionary. If the default dictionary is different, configure
`review.mecab_dictionary` with the IPADIC directory reported by your package
manager. UniDic and other feature layouts are rejected explicitly. MeCab and
IPADIC are separately installed dependencies, not bundled inside this gem.

The tool checks MeCab availability, dictionary encoding, and feature layout.
It never silently falls back to literal matching. To deliberately run without
morphological analysis:

```sh
asciidoc-pubkit review scan book.adoc --tokenizer literal --output .pubkit/literal-review
```

[Back to README](../README.md)
