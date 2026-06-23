# frozen_string_literal: true

module NvimControl
  class DataExtractor
    def self.context(client:)
      {
        cursor: cursor(client: client),
        file: file(client: client),
        selection: visual_selection(client: client),
        diagnostics: diagnostics(client: client)
      }
    end

    def self.cursor(client:)
      cursor = client.current.window.cursor
      { line: cursor[0], col: cursor[1] }
    rescue StandardError => e
      raise OperationError,
            "Failed to get cursor info: #{e.message}",
            e.backtrace
    end

    def self.file(client:)
      client.current.buffer.name
    rescue StandardError => e
      raise OperationError,
            "Failed to get file info: #{e.message}",
            e.backtrace
    end

    def self.visual_selection(client:)
      return nil unless visual_mode?(client)

      marks = visual_marks(client)
      text = selected_text(client, marks)
      build_selection_info(marks, text)
    rescue StandardError
      nil
    end

    def self.diagnostics(client:)
      client.eval("vim.diagnostic.get(0)").map do |diagnostic|
        {
          line: diagnostic["lnum"] + 1,
          col: diagnostic["col"] + 1,
          message: diagnostic["message"],
          severity: diagnostic["severity"]
        }
      end
    rescue StandardError
      []
    end

    class << self
      private

      VISUAL_BLOCK_MODE = "\x16"
      private_constant :VISUAL_BLOCK_MODE

      def visual_mode?(client)
        ["v", "V", VISUAL_BLOCK_MODE].include?(client.eval("mode()"))
      end

      def visual_marks(client)
        {
          start: client.eval("getpos(\"'<\")"),
          end: client.eval("getpos(\"'>\")")
        }
      end

      def selected_text(client, marks)
        start_line = marks[:start][1]
        end_line = marks[:end][1]
        client.current.buffer.get_lines(start_line - 1, end_line, true)
      end

      def build_selection_info(marks, text)
        {
          start: { line: marks[:start][1], col: marks[:start][2] },
          end: { line: marks[:end][1], col: marks[:end][2] },
          text: text.join("\n")
        }
      end
    end
  end
end
