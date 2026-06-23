# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe "NvimControl::VERSION" do
  it "is the current gem version" do
    expect(NvimControl::VERSION).to eq("1.0.0")
  end
end
