# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = 'asciidoc-pubkit'
  spec.version = '1.0.0'
  spec.summary = 'Document inspection, replacement, and Japanese review tools for AsciiDoc books'
  spec.description = 'Inspect AsciiDoc outlines, book metadata, and local cross-references, generate English document-title indexes, and generate Japanese technical writing prompts, review AsciiDoc prose, section headings, and list text separately, verify protected manuscript content, and explicitly apply prose-only mechanical replacements.'
  spec.authors = ['CyberGarage']
  spec.license = 'Apache-2.0'
  spec.homepage = 'https://github.com/cybergarage/asciidoc-pubkit'
  spec.metadata = { 'source_code_uri' => spec.homepage, 'changelog_uri' => "#{spec.homepage}/blob/main/CHANGELOG.md" }
  spec.required_ruby_version = '>= 3.2'
  spec.files = Dir['data/**/*.yml', 'data/**/*.md', 'lib/**/*.rb', 'exe/*', 'README.md', 'docs/**/*.md', 'LICENSE', 'CHANGELOG.md', 'examples/**/*']
  spec.bindir = 'exe'
  spec.executables = ['asciidoc-pubkit']
  spec.require_paths = ['lib']
  spec.add_dependency 'asciidoctor', '~> 2.0'
  spec.add_dependency 'logger', '~> 1.0'
end
