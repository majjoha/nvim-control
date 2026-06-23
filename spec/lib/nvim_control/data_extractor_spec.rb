# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe NvimControl::DataExtractor do
  let(:client) { instance_double(Neovim::Client) }

  describe ".cursor" do
    let(:current) { instance_double(Neovim::Current) }
    let(:window) { instance_double(Neovim::Window) }

    before do
      allow(client).to receive(:current).and_return(current)
      allow(current).to receive(:window).and_return(window)
      allow(window).to receive(:cursor).and_return([1, 0])
    end

    it "returns the cursor position as a hash" do
      expect(described_class.cursor(client: client)).to eq({ line: 1, col: 0 })
      expect(window).to have_received(:cursor)
    end
  end

  describe ".file" do
    let(:current) { instance_double(Neovim::Current) }
    let(:buffer) { instance_double(Neovim::Buffer) }

    before do
      allow(client).to receive(:current).and_return(current)
      allow(current).to receive(:buffer).and_return(buffer)
      allow(buffer).to receive(:name).and_return("/path/to/file.rb")
    end

    it "returns the current file name" do
      expect(described_class.file(client: client)).to eq("/path/to/file.rb")
      expect(buffer).to have_received(:name)
    end
  end

  describe ".visual_selection" do
    let(:client) { double("client") }
    let(:expected_selection) do
      {
        start: { line: 1, col: 1 },
        end: { line: 1, col: 5 },
        text: "selected text"
      }
    end

    context "when in visual mode" do
      before do
        allow(client).to receive(:eval).with("mode()").and_return("v")
        allow(client).to receive(:eval).with("getpos(\"'<\")").and_return([0,
          1, 1, 0])
        allow(client).to receive(:eval).with("getpos(\"'>\")").and_return([0,
          1, 5, 0])
        allow(client).to receive(:eval).with("getline(1, 1)")
          .and_return(["selected text"])
      end

      it "returns selection info" do
        expect(described_class.visual_selection(client: client))
          .to eq(expected_selection)
        expect(client).to have_received(:eval).with("mode()")
        expect(client).to have_received(:eval).with("getpos(\"'<\")")
        expect(client).to have_received(:eval).with("getpos(\"'>\")")
        expect(client).to have_received(:eval).with("getline(1, 1)")
      end
    end

    context "when not in visual mode" do
      it "returns nil" do
        allow(client).to receive(:eval).with("mode()").and_return("n")
        expect(described_class.visual_selection(client: client)).to be_nil
        expect(client).to have_received(:eval).with("mode()")
      end
    end
  end

  describe ".diagnostics" do
    let(:client) { double("client") }
    let(:expected_diagnostics) do
      [
        { line: 1, col: 1, message: "Error", severity: 1 },
        { line: 2, col: 3, message: "Warning", severity: 2 }
      ]
    end

    before do
      allow(client).to receive(:eval).with("vim.diagnostic.get(0)").and_return([
        { "lnum" => 0, "col" => 0, "message" => "Error", "severity" => 1 },
        { "lnum" => 1, "col" => 2, "message" => "Warning", "severity" => 2 }
      ])
    end

    it "returns mapped diagnostics with adjusted line and column" do
      expect(described_class.diagnostics(client: client))
        .to eq(expected_diagnostics)
      expect(client).to have_received(:eval).with("vim.diagnostic.get(0)")
    end
  end
end
