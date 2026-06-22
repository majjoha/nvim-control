$LOAD_PATH.unshift(File.expand_path("lib", __dir__))

require "nvim_control/version"

Gem::Specification.new do |s|
  s.name                  = "nvim-control"
  s.version               = NvimControl::VERSION
  s.summary               =
    "Bridge between running Neovim instances and agentic coding tools."
  s.description           = <<~DESCRIPTION
    `nvim-control` bridges running Neovim instances and agentic coding tools
    via Unix socket connections. It reads live editor state (cursor position,
    current file, visual selections, and diagnostics) as JSON and runs explicit
    control actions such as Ex commands and key input. This lets agents both
    answer questions like "What does this line do?" and drive the editor on
    request.
  DESCRIPTION
  s.author                = ["Mathias Jean Johansen"]
  s.email                 = "mathias@mjj.io"
  s.files                 = Dir["lib/**/*.rb", "bin/*", "LICENSE", "*.md"]
  s.executables          << "nvim-control"
  s.homepage              = "https://github.com/majjoha/nvim-control"
  s.license               = "ISC"
  s.required_ruby_version = ">= 4.0.0"

  s.add_dependency "neovim", "~> 0.10.0"
  # Extracted from Ruby's default gems in 4.0; required transitively by neovim.
  s.add_dependency "logger", "~> 1.7"

  s.metadata["rubygems_mfa_required"] = "true"
  s.metadata["source_code_uri"] = "https://github.com/majjoha/nvim-control"
  s.metadata["changelog_uri"] = "https://github.com/majjoha/nvim-control/blob/main/CHANGELOG.md"
  s.metadata["bug_tracker_uri"] = "https://github.com/majjoha/nvim-control/issues"
end
