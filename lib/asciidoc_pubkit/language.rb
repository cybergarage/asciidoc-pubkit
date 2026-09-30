# frozen_string_literal: true

module AsciidocPubkit
  module Language
    WRITING = %w[ja].freeze
    REVIEW = %w[ja].freeze
    DEFAULT = 'ja'

    def self.validate!(value, operation:)
      supported = { 'writing' => WRITING, 'review' => REVIEW }.fetch(operation)
      return value if supported.include?(value)

      raise Error, "Unsupported #{operation} language #{value.inspect}; supported: #{supported.join(', ')}."
    end
  end
end
