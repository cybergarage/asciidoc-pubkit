# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = 'asciidoc-pubkit'
  spec.version = '0.6.0'
  spec.summary = 'Japanese writing and review tools for AsciiDoc books'
  spec.description = 'Generate Japanese technical writing prompts, review AsciiDoc prose, and verify protected manuscript content.'
  spec.authors = ['CyberGarage']
  spec.license = 'Apache-2.0'
  spec.homepage = 'https://github.com/cybergarage/asciidoc-pubkit'
  spec.metadata = { 'source_code_uri' => spec.homepage, 'changelog_uri' => "#{spec.homepage}/blob/main/CHANGELOG.md" }
  spec.required_ruby_version = '>= 3.2'
  spec.files = Dir['data/**/*.yml', 'data/**/*.md', 'lib/**/*.rb', 'exe/*', 'README.md', 'LICENSE', 'CHANGELOG.md', 'examples/**/*']
  spec.bindir = 'exe'
  spec.executables = ['asciidoc-pubkit']
  spec.require_paths = ['lib']
  spec.add_dependency 'asciidoctor', '~> 2.0'
  spec.add_dependency 'logger', '~> 1.0'
end
