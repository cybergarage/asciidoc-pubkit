RUBY ?= ruby
ARGS ?= --help
PUBKIT_ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

.PHONY: run
run:
	@$(RUBY) -I "$(PUBKIT_ROOT)lib" "$(PUBKIT_ROOT)exe/asciidoc-pubkit" $(ARGS)
