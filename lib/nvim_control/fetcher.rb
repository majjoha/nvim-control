# frozen_string_literal: true

require "json"

module NvimControl
  class Fetcher
    class << self
      def fetch
        context = build_context
        JSON.generate(context)
      rescue ConnectionError => e
        format_error("Connection failed", e.message)
      rescue OperationError => e
        format_error("Context extraction failed", e.message)
      rescue StandardError => e
        format_error("Unexpected error", e.message)
      end

      private

      def build_context
        Connector.new.connect do |client|
          {
            cursor: DataExtractor.cursor(client: client),
            file: DataExtractor.file(client: client),
            selection: DataExtractor.visual_selection(client: client),
            diagnostics: DataExtractor.diagnostics(client: client)
          }
        end
      end

      def format_error(error, details)
        JSON.generate({ error: error, details: details })
      end
    end
  end
end
