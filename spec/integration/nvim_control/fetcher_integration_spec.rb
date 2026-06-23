# frozen_string_literal: true

require "English"
require "fileutils"
require "json"
require "open3"
require "rbconfig"
require "timeout"
require_relative "../../spec_helper"

RSpec.describe NvimControl::Fetcher do
  let(:socket_path) do
    File.expand_path("spec/integration/nvim-control.sock")
  end
  let(:test_file) do
    File.expand_path("spec/integration/test_file.rb")
  end
  let(:expected_context) do
    {
      "file" => File.expand_path(test_file),
      "cursor" => { "line" => 5, "col" => 4 }
    }
  end
  let(:expected_ex_response) do
    {
      "ok" => true,
      "action" => "ex",
      "command" => "call cursor(2, 4)",
      "result" => nil,
      "context_after" => {
        "cursor" => { "line" => 2, "col" => 3 },
        "file" => File.expand_path(test_file),
        "selection" => nil,
        "diagnostics" => []
      }
    }
  end
  let(:expected_keys_response) do
    payload = ":call cursor(3, 5)\r"

    {
      "ok" => true,
      "action" => "keys",
      "keys" => payload,
      "result" => payload.bytesize,
      "context_after" => {
        "cursor" => { "line" => 3, "col" => 4 },
        "file" => File.expand_path(test_file),
        "selection" => nil,
        "diagnostics" => []
      }
    }
  end

  around do |example|
    skip "Neovim not installed" unless system("which nvim > /dev/null 2>&1")

    neovim_pid = nil

    begin
      FileUtils.rm_f(socket_path)

      neovim_pid = Process.spawn(
        "nvim",
        "--listen", socket_path,
        "--headless", test_file,
        "-c", "call cursor(5, 10)",
        out: "/dev/null",
        err: "/dev/null"
      )

      wait_for_socket(socket_path)
      example.run
    ensure
      teardown_neovim(neovim_pid)
      FileUtils.rm_f(socket_path)
    end
  end

  it "retrieves the context from the running Neovim instance" do
    output, = run_cli(socket_path)

    expect(JSON.parse(output)).to include(expected_context)
  end

  it "executes Ex commands against the running Neovim instance" do
    output, = run_cli(socket_path, "ex", "call cursor(2, 4)")

    expect(JSON.parse(output)).to eq(expected_ex_response)
  end

  it "sends key input to the running Neovim instance" do
    output, = run_cli(socket_path, "keys", expected_keys_response["keys"])

    expect(JSON.parse(output)).to eq(expected_keys_response)
  end

  def wait_for_socket(socket_path)
    Timeout.timeout(5) do
      sleep(0.05) until File.exist?(socket_path)
    end
  end

  def teardown_neovim(neovim_pid)
    return unless neovim_pid

    Process.kill("TERM", neovim_pid)
    Process.wait(neovim_pid)
  rescue Errno::ECHILD, Errno::ESRCH
    nil
  end

  def run_cli(socket_path, *)
    Open3.capture3(
      { "NVIM_CONTROL_SOCKET" => socket_path },
      RbConfig.ruby,
      "bin/nvim-control",
      *
    )
  end
end
