# frozen_string_literal: true

require "json"

module NvimControl
  class CLI
    class << self
      def run(argv:, stdout: $stdout)
        case argv
        in [] | [READ_ACTION]
          read_context(stdout: stdout)
        in [action, payload] if Controller.supported_action?(action)
          run_control(action: action, payload: payload, stdout: stdout)
        else
          write_invalid_arguments(stdout: stdout)
        end
      end

      private

      def read_context(stdout:)
        write_response(Fetcher.fetch, stdout: stdout)
      end

      def run_control(action:, payload:, stdout:)
        response = Controller.run(action: action, payload: payload)

        write_response(response, stdout: stdout)
      end

      def write_invalid_arguments(stdout:)
        stdout.puts(
          JSON.generate(
            ok: false,
            error: "Invalid arguments",
            details: usage
          )
        )
        ERROR_EXIT_CODE
      end

      def write_response(response, stdout:)
        stdout.puts(response)

        successful_response?(response) ? SUCCESS_EXIT_CODE : ERROR_EXIT_CODE
      end

      def successful_response?(response)
        payload = JSON.parse(response)

        return false unless payload.is_a?(Hash)
        return false if payload.key?("error")
        return false if payload["ok"] == false

        true
      rescue JSON::ParserError
        false
      end

      def usage
        actions = ([READ_ACTION] + Controller.supported_actions).join("|")

        "Usage: nvim-control [#{actions}] [payload]"
      end

      READ_ACTION = "read"
      SUCCESS_EXIT_CODE = 0
      ERROR_EXIT_CODE = 1
      private_constant :READ_ACTION,
                       :SUCCESS_EXIT_CODE,
                       :ERROR_EXIT_CODE
    end
  end
end
