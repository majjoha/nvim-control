# frozen_string_literal: true

require "neovim"

module NvimControl
  class Connector
    def initialize(client: nil)
      @socket_path = ENV["NVIM_CONTROL_SOCKET"] || DEFAULT_SOCKET_PATH
      @client = client || begin
        Neovim.attach_unix(socket_path)
      rescue StandardError => e
        raise ConnectionError,
              "Failed to connect to Neovim socket: #{e.message}",
              e.backtrace
      end
    end

    def connect
      yield client if block_given?
    rescue StandardError => e
      raise OperationError,
            "Failed during Neovim operation: #{e.message}",
            e.backtrace
    end

    private

    attr_reader :client, :socket_path

    DEFAULT_SOCKET_PATH = File.expand_path("nvim-control.sock")
    private_constant :DEFAULT_SOCKET_PATH
  end
end
