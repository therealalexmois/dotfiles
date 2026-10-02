# Python debugging with DAP

This is the keyboard-first runbook for Python debugging in this Neovim
configuration. It uses `nvim-dap`, `nvim-dap-python`, `nvim-dap-ui`, and the
Mason-installed `debugpy-adapter`.

## Before the first session

The Python AstroCommunity pack and the local DAP spec arrange for `debugpy` to
be installed through Mason. Run `:MasonToolsInstall` if it is missing. The
configuration intentionally fails closed when the Mason executable
`debugpy-adapter` is not on `$PATH`; it does not fall back to a system
`python`. A failed setup reports:

```text
Python DAP is unavailable: Mason executable debugpy-adapter was not found. Run :MasonToolsInstall.
```

Open a Python buffer from the project root. `nvim-dap` reads a project
`.vscode/launch.json` automatically when a new session is started. The example
below belongs in the project being debugged, not in this dotfiles repository.
It is standard JSON, so do not add trailing commas. Keep `.env` local-only and
never copy secrets into dotfiles.

## The normal keyboard loop

1. Put the cursor on the line to inspect and press `F9` (or `<Leader>db`) to
   toggle a breakpoint.
2. Press `F5` (or `<Leader>dc`) and choose a configuration. The chooser combines
   the built-in Python entries with entries from `.vscode/launch.json`.
3. When execution stops, inspect the DAP UI, hover, or REPL, then step with
   `F10`, `F11`, and `Shift-F11`.
4. Continue with `F5`. Press `Shift-F5` only when the launched target should
   be terminated.

The built-in Python entries are `file`, `file:args`, `attach`, and
`file:doctest`. `file:args` prompts for an argument string and splits it into
arguments. A project launch file can provide stable file, module, argument-list,
and localhost socket-attach entries for repeatable sessions.

## Keymap reference

The following mappings are available in a Python buffer or an active DAP
session. `<Leader>` is the configured global leader.

| Key | Action |
| --- | --- |
| `F5`, `<Leader>dc` | Start or continue, then choose a configuration when needed |
| `F9`, `<Leader>db` | Toggle a line breakpoint |
| `Shift-F9`, `<Leader>dC` | Prompt for a conditional breakpoint expression |
| `F10`, `<Leader>do` | Step over |
| `F11`, `<Leader>di` | Step into |
| `Shift-F11`, `<Leader>dO` | Step out |
| `F6`, `<Leader>dp` | Pause |
| `<Leader>ds` | Run to cursor |
| `Shift-F5`, `<Leader>dQ` | Terminate the session and its launched target |
| `Ctrl-F5`, `<Leader>dr` | Restart the current frame, not the whole process |
| `<Leader>dq` | Close the DAP session without an explicit terminate request |
| `<Leader>dd` | Detach and close the DAP session with `terminateDebuggee=false` |
| `<Leader>dl` | Add a logpoint; prompt for its message |
| `<Leader>dL` | Add a hit-condition breakpoint; prompt for its hit condition |
| `<Leader>dx` | Pick adapter-provided exception filters |
| `<Leader>dv` | List breakpoints and logpoints in the quickfix window |
| `<Leader>du` | Toggle the DAP UI |
| `<Leader>dh` | Hover the expression under the cursor |
| `<Leader>dE` | Prompt for an expression and evaluate it; in Visual mode evaluate the selection |
| `<Leader>dR` | Toggle the DAP REPL |
| `<Leader>dt` | Debug the nearest Python test method |
| `<Leader>dT` | Debug the nearest Python test class |

`<Leader>dt` and `<Leader>dT` use `nvim-dap-python`'s test runner. It detects
`pytest` from the project markers/configuration when possible, otherwise it
uses the plugin's fallback runner. If detection is wrong, set
`require("dap-python").test_runner = "pytest"` in the project configuration.
The Python tree-sitter parser is required to locate the nearest method/class.

### Breakpoint details

- A conditional breakpoint stops only when its expression is truthy.
- A logpoint logs its message and continues instead of stopping. `debugpy`
  supports `{name}`-style variable interpolation in the message.
- A hit condition is adapter-defined. For `debugpy`, enter the count as a
  string such as `3` to stop on the requested visit. Verify the behavior for
  non-numeric expressions in the target project before relying on them.
- The exception picker asks the adapter for available filters. With `debugpy`,
  the common filters are `raised` and `uncaught`; the active adapter remains
  the source of truth.

## File, module, and test launches

Create this project-level `.vscode/launch.json` when the defaults are not
enough. The `cwd` and `envFile` entries are useful for applications whose
imports or settings depend on the project root; `.env` remains local-only.

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Python: current file",
      "type": "python",
      "request": "launch",
      "program": "${file}",
      "cwd": "${workspaceFolder}",
      "envFile": "${workspaceFolder}/.env",
      "justMyCode": true
    },
    {
      "name": "Python: module",
      "type": "python",
      "request": "launch",
      "module": "uvicorn",
      "args": ["app.main:app", "--reload"],
      "cwd": "${workspaceFolder}",
      "envFile": "${workspaceFolder}/.env",
      "justMyCode": true
    },
    {
      "name": "Python: attach localhost:5678",
      "type": "python",
      "request": "attach",
      "connect": { "host": "127.0.0.1", "port": 5678 },
      "justMyCode": true
    },
    {
      "name": "Python: attach container",
      "type": "python",
      "request": "attach",
      "connect": { "host": "127.0.0.1", "port": 5678 },
      "pathMappings": [
        { "localRoot": "${workspaceFolder}", "remoteRoot": "/app" }
      ],
      "justMyCode": true
    }
  ]
}
```

The `Python: current file` configuration runs `${file}`. The module entry
shows a repeatable `uvicorn` example; replace `module` and `args` with the
module and arguments used by the project. For a one-off argument string,
choose the built-in `file:args` entry instead of editing this file.

For a repeatable test workflow, put the cursor inside a pytest method or class
and use `<Leader>dt` or `<Leader>dT`. The generated launch uses the current
file and pytest node path, including `-s` so test output remains visible.

## Socket attach with debugpy

Start the application-side listener before pressing `F5`. For a local module,
the CLI form is:

```sh
python3 -m debugpy --listen 127.0.0.1:5678 -m uvicorn app.main:app
python3 -m debugpy --listen 127.0.0.1:5678 --wait-for-client -m uvicorn app.main:app
```

The second command makes startup wait until Neovim attaches. An application
can also start the listener itself:

```python
import debugpy

debugpy.listen(("127.0.0.1", 5678))
debugpy.wait_for_client()
```

Then choose `Python: attach localhost:5678` from the project launch file. For a
different local port or host, choose the built-in `attach` entry; it prompts for
host (default `127.0.0.1`) and port (default `5678`).

For a container or remote process, make the debugpy listener and port
forwarding reachable from the Neovim host. A listener on `0.0.0.0` should be
protected by the container/network boundary and never exposed to an untrusted
network. Edit the attach configuration to match the forwarded port and add
path mappings when paths differ:

```json
{
  "name": "Python: attach container",
  "type": "python",
  "request": "attach",
  "connect": { "host": "127.0.0.1", "port": 5678 },
  "pathMappings": [
    { "localRoot": "${workspaceFolder}", "remoteRoot": "/app" }
  ]
}
```

`<Leader>dd` is the supported way to leave a socket-attached application
running. It sends `terminateDebuggee=false`, then closes the Neovim DAP
session. Do not use `Shift-F5`/`<Leader>dQ` for this case: terminate is for a
target Neovim launched and owned by the debug session. The exact target-side
behavior still depends on the debug adapter and transport; this runbook does
not promise a restart or shutdown of the application after detach.

### macOS PID limitation

Arbitrary PID injection/attach is not a supported path in this configuration
on macOS. Use an application-side `debugpy.listen(...)` socket and attach to
that socket instead. This keeps the attach contract explicit and works for
local, forwarded, and container targets. PyCharm may offer additional process
and interpreter integration, but it does not change this Neovim limitation.
`debugpy --pid <PID>` may also be blocked by macOS task-port permissions; that
is not a fallback for socket attach or a readiness criterion for this setup.

## Inspecting state and recovering

- **No adapter:** run `:MasonToolsInstall`, verify the Mason
  `debugpy-adapter` executable is available, and restart Neovim if the plugin
  was installed during this session. No system-`python` fallback is attempted.
- **No configuration appears:** check that Neovim's working directory is the
  project root, that the file is Python, and that `.vscode/launch.json` is valid
  standard JSON with `version` and `configurations`.
- **The test method/class is not found:** install/enable the Python tree-sitter
  parser, place the cursor inside the test, and confirm the project runner is
  detected as pytest.
- **Socket attach refuses the connection:** start the target listener first;
  verify host, port, container port publishing/SSH forwarding, and firewall
  rules. For remote paths, add `pathMappings` and use absolute remote roots.
- **The UI is missing:** toggle `<Leader>du`; use `<Leader>dh`, `<Leader>dE`,
  or `<Leader>dR` for focused inspection. `dapui` opens automatically when a
  session initializes when its plugin is available.
- **A stale or broken session remains:** use `<Leader>dq` to close the client,
  or `<Leader>dQ` to terminate a launched target, then start again with `F5`.
  Use `<Leader>dd` for a socket target that must stay alive.

## PyCharm parity and intentional gaps

This is an 80/20 workflow comparison, not a claim of feature equivalence.

| Capability | Neovim in this setup | PyCharm comparison |
| --- | --- | --- |
| File/module launch and arguments | Built-in chooser plus versioned `.vscode/launch.json` | Run/debug configurations with a richer GUI editor |
| Breakpoints | Line, conditional, logpoint, hit condition, list/quickfix | Comparable core breakpoint types with more inline controls |
| Exceptions | Adapter-provided filter picker | GUI exception breakpoint editor and broader IDE presentation |
| Tests | Nearest method/class via `nvim-dap-python` and pytest node paths | Richer test tree, gutter actions, parametrization and test navigation |
| Variables and evaluation | DAP UI, hover, REPL, expression evaluation | More integrated inspectors, watches and data presentation |
| Socket/container attach | Explicit debugpy listener, host/port, and manual path mappings | More integrated interpreter, remote target and mapping workflows |
| Arbitrary macOS PID injection | Not supported; use socket attach | PyCharm has process/interpreter integrations outside this contract |
| Data/scientific debugging | Not included | PyCharm has richer DataFrame/scientific views |
| Smart Step Into and test-runner UX | Not included; use ordinary stepping and DAP test commands | Available as IDE-oriented features |

Neovim's advantages here are keyboard-first control, project configurations
that can be reviewed and versioned, and composition with the shell and other
editor tools. The deliberate gaps are GUI-rich test navigation, scientific/data
viewers, Smart Step Into, and arbitrary PID injection on macOS. They are known
scope boundaries, not hidden fallbacks.

## Verification status

The current environment has a working Mason `debugpy-adapter` and imports
Mason `debugpy 1.8.21`. A live local smoke used the current setup, attached to
a loopback `debugpy` listener, stopped at a breakpoint, detached with
`terminateDebuggee=false`, and confirmed that the target continued and exited.
A separate deterministic headless smoke invoked `dap.continue()` from a
temporary project cwd, intercepted the configuration chooser, and confirmed
that a project `.vscode/launch.json` entry was discovered and selected without
starting an adapter or using the network.

These checks establish adapter availability, socket attach/detach, and the
automatic launch-file discovery path. They do not claim interactive DAP UI,
logpoint, pytest, evaluate, or arbitrary macOS PID-injection behavior.
