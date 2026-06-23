# frozen_string_literal: true

require "json"
require_relative "../../spec_helper"

RSpec.describe NvimControl::Controller do
  let(:client) { double("client") }
  let(:connector) { instance_double(NvimControl::Connector) }
  let(:context_after) do
    {
      cursor: { line: 3, col: 1 },
      file: "/tmp/example.rb",
      selection: nil,
      diagnostics: []
    }
  end
  let(:parsed_context_after) { JSON.parse(JSON.generate(context_after)) }
  let(:write_response) do
    {
      "ok" => true,
      "action" => "ex",
      "command" => "write",
      "result" => nil,
      "context_after" => parsed_context_after
    }
  end
  let(:keys_response) do
    {
      "ok" => true,
      "action" => "keys",
      "keys" => ":w\r",
      "result" => 3,
      "context_after" => parsed_context_after
    }
  end

  before do
    allow(NvimControl::Connector).to receive(:new).and_return(connector)
    allow(connector).to receive(:connect).and_yield(client)
    allow(NvimControl::DataExtractor).to receive(:context)
      .with(client: client)
      .and_return(context_after)
  end

  describe ".run" do
    it "executes Ex commands and returns JSON with the new context" do
      allow(client).to receive(:command).with("write").and_return(nil)

      expect(parsed_response(action: "ex", payload: "write")).to eq(
        write_response
      )
    end

    it "executes key input and returns JSON with the new context" do
      allow(client).to receive(:input).with(":w\r").and_return(3)

      expect(parsed_response(action: "keys", payload: ":w\r")).to eq(
        keys_response
      )
    end

    it "returns an error JSON payload for unsupported actions" do
      expect(parsed_response(action: "lua", payload: "1 + 1")).to eq({
        "ok" => false,
        "error" => "Unsupported action",
        "details" => "Supported actions: ex, keys"
      })
    end
  end

  def parsed_response(action:, payload:)
    JSON.parse(described_class.run(action: action, payload: payload))
  end
end
