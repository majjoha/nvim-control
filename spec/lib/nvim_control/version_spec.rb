# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe NvimControl::VERSION do
  describe "VERSION" do
    it "is version 1.0.0" do
      expect(NvimControl::VERSION).to eq("1.0.0")
    end
  end
end
