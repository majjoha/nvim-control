# frozen_string_literal: true

require "json"
require_relative "../../spec_helper"

RSpec.describe NvimControl::Fetcher do
  let(:client) { instance_double(Neovim::Client) }
  let(:connector) { instance_double(NvimControl::Connector) }
  let(:context) do
    {
      cursor: { line: 1, col: 0 },
      file: "/path/to/file.rb",
      selection: nil,
      diagnostics: []
    }
  end

  describe ".fetch" do
    before do
      allow(NvimControl::Connector).to receive(:new)
        .and_return(connector)
      allow(connector).to receive(:connect).and_yield(client)
      allow(NvimControl::DataExtractor).to receive(:context)
        .with(client: client)
        .and_return(context)
    end

    it "returns the context as JSON" do
      expect(described_class.fetch).to eq(JSON.generate(context))
    end

    it "delegates to the data extractor" do
      described_class.fetch

      expect(NvimControl::DataExtractor).to have_received(:context)
        .with(client: client)
    end

    context "when connection fails" do
      before do
        allow(NvimControl::Connector).to receive(:new).and_raise(
          NvimControl::ConnectionError.new("Socket error")
        )
      end

      it "returns connection error as JSON" do
        expect(described_class.fetch).to eq(JSON.generate({
          error: "Connection failed", details: "Socket error"
        }))
      end
    end

    context "when context extraction fails" do
      before do
        allow(NvimControl::DataExtractor).to receive(:context).and_raise(
          NvimControl::OperationError.new("Build error")
        )
      end

      it "returns extraction error as JSON" do
        expect(described_class.fetch).to eq(JSON.generate({
          error: "Context extraction failed", details: "Build error"
        }))
      end
    end
  end
end
