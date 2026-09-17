# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = 'asciidoc-pubkit'
  spec.version = '0.1.1'
  spec.summary = 'Review and publishing tools for AsciiDoc books'
  spec.description = 'Review Japanese AsciiDoc prose, generate contextual AI review prompts, and verify protected manuscript content.'
  spec.authors = ['CyberGarage']
  spec.license = 'Apache-2.0'
  spec.homepage = 'https://github.com/cybergarage/asciidoc-pubkit'
  spec.metadata = { 'source_code_uri' => spec.homepage, 'changelog_uri' => "#{spec.homepage}/blob/main/CHANGELOG.md" }
  spec.required_ruby_version = '>= 3.2'
  spec.files = Dir['lib/**/*.rb', 'exe/*', 'README.md', 'LICENSE', 'CHANGELOG.md', 'examples/**/*']
  spec.bindir = 'exe'
  spec.executables = ['asciidoc-pubkit']
  spec.require_paths = ['lib']
  spec.add_dependency 'asciidoctor', '~> 2.0'
  spec.add_dependency 'logger', '~> 1.0'
end
