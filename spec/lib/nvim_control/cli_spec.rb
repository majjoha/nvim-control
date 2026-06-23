# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe NvimControl::CLI do
  describe ".run" do
    it "reads context by default" do
      allow(NvimControl::Fetcher).to receive(:fetch).and_return("{\"ok\":true}")

      expect(run_cli).to eq([0, "{\"ok\":true}\n"])
    end

    it "reads context when the read subcommand is used" do
      allow(NvimControl::Fetcher).to receive(:fetch).and_return("{\"ok\":true}")

      expect(run_cli("read")).to eq([0, "{\"ok\":true}\n"])
    end

    it "returns an error exit code when context reading fails" do
      allow(NvimControl::Fetcher).to receive(:fetch)
        .and_return(read_error_response)

      expect(run_cli).to eq([1, "#{read_error_response}\n"])
    end

    it "returns an error when the read subcommand has extra arguments" do
      expect(run_cli("read", "extra")).to eq([
        1,
        "{\"ok\":false,\"error\":\"Invalid arguments\"," \
        "\"details\":\"Usage: nvim-control [read|ex|keys] [payload]\"}\n"
      ])
    end

    it "runs control actions for supported subcommands" do
      allow(NvimControl::Controller).to receive(:run)
        .with(action: "ex", payload: "write")
        .and_return("{\"ok\":true}")

      expect(run_cli("ex", "write")).to eq([0, "{\"ok\":true}\n"])
    end

    it "returns an error exit code when a control action fails" do
      stub_control_action(response: control_error_response)

      expect(run_cli("ex", "write")).to eq([1, "#{control_error_response}\n"])
    end

    it "returns an error when a control subcommand has no payload" do
      expect(run_cli("keys")).to eq([
        1,
        "{\"ok\":false,\"error\":\"Invalid arguments\"," \
        "\"details\":\"Usage: nvim-control [read|ex|keys] [payload]\"}\n"
      ])
    end

    it "returns an error for unsupported subcommands" do
      expect(run_cli("lua")).to eq([
        1,
        "{\"ok\":false,\"error\":\"Invalid arguments\"," \
        "\"details\":\"Usage: nvim-control [read|ex|keys] [payload]\"}\n"
      ])
    end
  end

  def run_cli(*argv)
    stdout = StringIO.new
    exit_code = described_class.run(argv: argv, stdout: stdout)

    [exit_code, stdout.string]
  end

  def read_error_response
    "{\"error\":\"Connection failed\",\"details\":\"Socket error\"}"
  end

  def control_error_response
    "{\"ok\":false,\"error\":\"Connection failed\"," \
      "\"details\":\"Socket error\"}"
  end

  def stub_control_action(response:)
    allow(NvimControl::Controller).to receive(:run)
      .with(action: "ex", payload: "write")
      .and_return(response)
  end
end
