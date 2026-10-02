# frozen_string_literal: true

require 'asciidoctor'
require 'json'
require 'yaml'
require 'digest'
require 'fileutils'
require 'pathname'
require 'optparse'

module AsciidocPubkit
  VERSION = '0.8.5'
  class Error < StandardError; end

  def self.hash_text(text)
    Digest::SHA256.hexdigest(text)
  end

  def self.read_text(path)
    text = File.binread(path).force_encoding(Encoding::UTF_8)
    raise Error, "File is not valid UTF-8: #{path}" unless text.valid_encoding?
    text
  end
end

require_relative 'asciidoc_pubkit/language'
require_relative 'asciidoc_pubkit/writing'
require_relative 'asciidoc_pubkit/rule_set'
require_relative 'asciidoc_pubkit/heading_rules'
require_relative 'asciidoc_pubkit/settings'
require_relative 'asciidoc_pubkit/document'
require_relative 'asciidoc_pubkit/morphology'
require_relative 'asciidoc_pubkit/rules'
require_relative 'asciidoc_pubkit/session'
require_relative 'asciidoc_pubkit/local_evaluator'
require_relative 'asciidoc_pubkit/score'
require_relative 'asciidoc_pubkit/replacement'
require_relative 'asciidoc_pubkit/cli'
