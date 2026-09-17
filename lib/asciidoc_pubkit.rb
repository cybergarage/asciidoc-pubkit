# frozen_string_literal: true

require 'asciidoctor'
require 'json'
require 'yaml'
require 'digest'
require 'fileutils'
require 'pathname'
require 'optparse'

module AsciidocPubkit
  VERSION = '0.2.0'
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

require_relative 'asciidoc_pubkit/settings'
require_relative 'asciidoc_pubkit/document'
require_relative 'asciidoc_pubkit/morphology'
require_relative 'asciidoc_pubkit/rules'
require_relative 'asciidoc_pubkit/session'
require_relative 'asciidoc_pubkit/cli'
