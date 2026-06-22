# `nvim-control`
![CI](https://github.com/majjoha/nvim-control/workflows/CI/badge.svg)
[![Gem Version](https://badge.fury.io/rb/nvim-control.svg)](
https://badge.fury.io/rb/nvim-control)

`nvim-control` is a bridge between running Neovim instances and agentic coding
tools. By default, it extracts context from the editor via a Unix socket
connection and outputs JSON with the cursor position, current file, visual
selection and diagnostics. It can also execute explicit control actions such as
running Ex commands or sending key input back to Neovim.

It allows agentic coding tools running outside Neovim to answer questions such
as:
- What does this line do?
- Can you convert the current line to uppercase?
- What does the method under my cursor do?
- Are these lines idiomatic Ruby?

## Motivation
While the Neovim community provides several plugins for integrating agentic
coding assistants into the editor (see the [AI section in the Awesome Neovim
repository](https://github.com/rockerboo/awesome-neovim?tab=readme-ov-file#ai)),
it seems that few tools offer a way to let any agentic coding tool running
*outside* Neovim retrieve the state of the editor in an agnostic manner.

The goal with `nvim-control` is to separate concerns, so Amp Code, Claude Code,
Codex, etc., can query the current state of a Neovim session by calling this
tool. When editor mutations are needed, they must go through explicit control
subcommands instead of piggybacking on the default read-only flow. See the
[Integration with agentic tools](#integration-with-agentic-tools) section below
for suggestions on how to set this up.

## Installation
```sh
gem install nvim-control
```

## Setup
When starting Neovim ensure that you open it using the `--listen` flag and pass
a path to the socket as follows:

```sh
nvim --listen $(pwd)/nvim-control.sock
```

Alternatively, you can set the `NVIM_CONTROL_SOCKET` environment variable to
specify the socket path:

```sh
export NVIM_CONTROL_SOCKET=/tmp/nvim-control.sock
nvim --listen $NVIM_CONTROL_SOCKET
```

If no environment variable is set, the tool defaults to `nvim-control.sock` in
the current directory.

## Usage
### Read context
Once Neovim is running, you can retrieve the current context by running
`nvim-control` or `nvim-control read`.

This will output JSON containing the current file, cursor position, visual
selection (if any), and diagnostics in this format:

```json
{
  "cursor": {
    "line": 43,
    "col": 3
  },
  "file": "/path/to/current/file.rb",
  "selection": null,
  "diagnostics": []
}
```

### Control Neovim explicitly
Control actions are opt-in subcommands. They also return JSON, including a
`context_after` snapshot so agents can verify what changed.

Supported control subcommands:
- `nvim-control ex "..."` runs an Ex command.
- `nvim-control keys "..."` sends raw key input.

Example response:
```json
{
  "ok": true,
  "action": "ex",
  "command": "write",
  "result": null,
  "context_after": {
    "cursor": { "line": 43, "col": 3 },
    "file": "/path/to/current/file.rb",
    "selection": null,
    "diagnostics": []
  }
}
```

### Useful examples
Read the current editor state:
```sh
nvim-control
```

Save the current buffer:
```sh
nvim-control ex "write"
```

Open the quickfix list after diagnostics or a grep:
```sh
nvim-control ex "copen"
```

Open a vertical split:
```sh
nvim-control ex "vsplit"
```

Open a diff split against another file:
```sh
nvim-control ex "diffsplit other.rb"
```

Send keys to write the file from command-line mode:
```sh
nvim-control keys $':write\r'
```

Send keys to open the quickfix list:
```sh
nvim-control keys $':copen\r'
```

### Integration with agentic tools
#### Amp Code
```sh
amp skill add majjoha/nvim-control/nvim-read
amp skill add majjoha/nvim-control/nvim-control
```

#### Claude Code
```sh
# Add the repository as a marketplace
/plugin marketplace add majjoha/nvim-control

# Install the plugin
/plugin install nvim-control@nvim-control
```

The plugin provides the `nvim-read` skill which gives Claude Code access to
your live Neovim editor state. Install the `nvim-control` skill as well if you
want the agent to run explicit Neovim commands.

#### Codex
```sh
$skill-installer install \
  https://github.com/majjoha/nvim-control/tree/main/.codex/skills/nvim-read
$skill-installer install \
  https://github.com/majjoha/nvim-control/tree/main/.codex/skills/nvim-control
```

#### Gemini
TBD.

#### OpenCode
<details>
<summary><code>~/.config/opencode/command/nvim-read.md</code></summary>
<pre>
---
description: Show current Neovim context
---

!`nvim-control`
</pre>
</details>

<details>
<summary><code>~/.config/opencode/command/nvim-control.md</code></summary>
<pre>
---
description: Run an explicit Neovim control command
---

!`nvim-control ex "$ARGUMENTS"`
</pre>
</details>

## Disclaimer
Since building software with AI can still be divisive, it might be worth
pointing out here that `nvim-control` itself has been built using OpenCode and
Claude Code, but with human guidance and continuous review of its work.

## License
See [LICENSE](https://github.com/majjoha/nvim-control/blob/main/LICENSE).
