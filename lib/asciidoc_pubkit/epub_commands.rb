# frozen_string_literal: true

require 'open3'

module AsciidocPubkit
  # EPUB postprocessing is independent of manuscript review sessions and MeCab.
  class EpubCommands
    def self.run(command, args, out:, err:)
      raise Error, 'Unknown EPUB command. Use --help.' unless command == 'image-width'

      helper = File.expand_path('../../data/tools/epub_image_width.py', __dir__)
      stdout, stderr, status = Open3.capture3('python3', helper, *args)
      out.write(stdout)
      err.write(stderr)
      status.success? ? 0 : 2
    end
  end
end
