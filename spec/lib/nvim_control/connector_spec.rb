# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe NvimControl::Connector do
  let(:client) { instance_double(Neovim::Client) }

  describe "#initialize" do
    context "when no client is provided and attach fails" do
      before do
        allow(Neovim).to receive(:attach_unix)
          .and_raise(StandardError.new("Socket not found"))
      end

      it "raises a `ConnectionError` error" do
        expect do
          described_class.new
        end.to raise_error(NvimControl::ConnectionError,
                           /Failed to connect to Neovim socket/)
      end
    end
  end

  describe "#connect" do
    let(:connector) { described_class.new(client: client) }

    context "when operation succeeds" do
      it "yields the client" do
        expect { |block| connector.connect(&block) }.to yield_with_args(client)
      end

      it "does not raise an error" do
        expect { connector.connect }.not_to raise_error
      end
    end

    context "when operation fails" do
      before do
        allow(client).to receive(:eval)
          .and_raise(StandardError.new("Lua error"))
      end

      it "raises an `OperationError` error with a message" do
        expect do
          connector.connect { client.eval("bad lua") }
        end.to raise_error(NvimControl::OperationError,
                           /Failed during Neovim operation/)
        expect(client).to have_received(:eval).with("bad lua")
      end
    end
  end
end
