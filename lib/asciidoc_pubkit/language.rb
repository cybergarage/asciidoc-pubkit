# frozen_string_literal: true

module AsciidocPubkit
  module Language
    WRITING = %w[ja en].freeze
    REVIEW = %w[ja en].freeze
    DEFAULT = 'ja'

    def self.name(language)
      { 'ja' => 'Japanese', 'en' => 'English' }.fetch(language)
    end

    def self.validate!(value, operation:)
      supported = { 'writing' => WRITING, 'review' => REVIEW }.fetch(operation)
      return value if supported.include?(value)

      raise Error, "Unsupported #{operation} language #{value.inspect}; supported: #{supported.join(', ')}."
    end
  end
end
