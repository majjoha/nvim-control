# frozen_string_literal: true

require "json"

module NvimControl
  class Controller
    class << self
      def run(action:, payload:)
        return invalid_action_response unless supported_action?(action)

        JSON.generate(action_response(action: action, payload: payload))
      rescue ConnectionError => e
        format_error("Connection failed", e.message)
      rescue OperationError => e
        format_error("Control action failed", e.message)
      rescue StandardError => e
        format_error("Unexpected error", e.message)
      end

      def supported_action?(action)
        ACTIONS.key?(action)
      end

      def supported_actions
        ACTIONS.keys
      end

      private

      def action_response(action:, payload:)
        Connector.new.connect do |client|
          execute_action(client: client, action: action, payload: payload)
        end
      end

      def execute_action(client:, action:, payload:)
        action_metadata = ACTIONS.fetch(action)

        {
          ok: true,
          action: action,
          action_metadata.fetch(:payload_key) => payload,
          result: action_metadata.fetch(:runner).call(client, payload),
          context_after: DataExtractor.context(client: client)
        }
      end

      def invalid_action_response
        JSON.generate(
          ok: false,
          error: "Unsupported action",
          details: "Supported actions: #{supported_actions.join(', ')}"
        )
      end

      def format_error(error, details)
        JSON.generate({ ok: false, error: error, details: details })
      end

      ACTIONS = {
        "ex" => {
          payload_key: :command,
          runner: ->(client, payload) { client.command(payload) }
        }.freeze,
        "keys" => {
          payload_key: :keys,
          runner: ->(client, payload) { client.input(payload) }
        }.freeze
      }.freeze
      private_constant :ACTIONS
    end
  end
end
