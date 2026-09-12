---
name: terminal-registry
description: |
  Manage commands running in Neovim terminal buffers via the `terminal-registry`
  CLI (terminal-registry). Use this when the user asks to start, list,
  switch to, inspect output of, send input to, or kill a long-running command
  (dev server, REPL, test watcher, build, etc.) inside a Neovim terminal, or
  when the user says things like "run this in a terminal", "check the logs of
  the X terminal", "restart the Y process", or "send this command to the
  running terminal".
license: MIT
---

## Instructions

This repository provides `terminal-registry`, a command line wrapper
around the Lua module `terminal_registry` (see `lua/terminal_registry.lua`
and `doc/terminal_registry.txt`). It lets you manage terminal buffers running
inside a **currently open Neovim instance**, each identified by a string
`id`.

### Prerequisite: `$NVIM`

`terminal-registry` talks to a running Neovim instance via
`nvim --server "$NVIM" --remote-expr`. This only works when invoked from a
shell that has the `$NVIM` environment variable set — which Neovim sets
automatically for `:terminal` buffers opened inside it. If `$NVIM` is unset
or points to a stale server, the command will fail; ask the user to run it
from a Neovim terminal, or to provide the correct server address (e.g. via
`nvim --listen`).

### CLI usage

Run `terminal-registry help` to see the full usage text. Subcommands:

- `start <cmd> [<opts_json>]` — Start a new terminal running `<cmd>` and
  register it. `<opts_json>` is a JSON object with optional keys:
  - `id` (string): registry id to use (default: `<cmd>` itself).
  - `kill` (boolean): kill any existing terminal with the same id first
    (default: `true`).
  - `terminal_options` (object): options forwarded to Neovim's `termopen()`.
  Example: `terminal-registry start "npm run dev" '{"id":"dev-server"}'`
- `list` — List all registered terminal ids and their commands.
- `get_buf <id>` — Print the Neovim buffer number for the terminal `<id>`.
- `get_recent_output_lines <id> <n>` — Print the last `<n>` non-trailing-blank
  lines of output from terminal `<id>` (useful for checking logs/status
  without switching buffers).
- `send <id> <keys>` — Send raw `<keys>` to terminal `<id>` (no newline
  appended); use for partial input or control sequences.
- `sendl <id> <keys>` — Like `send`, but appends a trailing newline; use this
  to run a shell command inside the terminal, e.g.
  `terminal-registry sendl dev-server "npm test"`.
- `kill <id>` — Stop the job and delete the buffer for terminal `<id>`.

### Recommended workflow

1. Check `terminal-registry list` to see what's already registered
   before starting a duplicate terminal for the same purpose.
2. Use a stable, descriptive `id` (e.g. `dev-server`, `test-watch`,
   `python-repl`) so the same terminal can be reused across requests instead
   of spawning new ones.
3. To (re)start a process: `terminal-registry start <cmd> '{"id":"<id>"}'`.
   By default this kills any existing terminal with the same id first.
4. To check on a running process without switching to it in the editor: use
   `get_recent_output_lines <id> <n>`.
5. To feed input/commands to an interactive process (REPL, shell): use
   `sendl <id> <keys>`.
6. To stop a process you started: `kill <id>`.

### Example

```sh
# Start (or restart) a dev server terminal
terminal-registry start "npm run dev" '{"id":"dev-server"}'

# See what's registered
terminal-registry list

# Check its recent output
terminal-registry get_recent_output_lines dev-server 50

# Send a command to a REPL
terminal-registry start "python" '{"id":"py-repl","kill":false}'
terminal-registry sendl py-repl "print(1 + 1)"

# Stop it
terminal-registry kill py-repl
```

### Caveat

The `terminal-registry` command is available only when you have started via
the plugin's `require("terminal_registry").start()` function, which sets up
the `PATH` environment variable to include the plugin's `bin/` directory. If
you get "command not found", this session isn't running inside a
terminal-registry-managed terminal. Ask the user to start one via
`:lua require("terminal_registry").start("your_ai_agent", {id="AI"})` in
Neovim, or fall back to invoking the script directly by its full path (e.g.
under the plugin's  bin/  directory).
