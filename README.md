# macOS dotfiles

Configuration for Zsh, tmux, Neovim, Alacritty, Codex, and Claude Code.
The checkout must live at `~/.dotfiles`: several configurations use this path.

## Start here

| Task | Document |
| --- | --- |
| Set up a Mac | [Install the dotfiles](docs/how-to/install.md) |
| Find tools, paths, and package managers | [Tool reference](docs/reference/tools.md) |
| Understand config loading and symlinks | [Configuration layout](docs/explanation/configuration-layout.md) |
| Use Neovim | [Neovim](nvim/README.md) |
| Use AI in Neovim | [AI commands and profiles](nvim/AI.md) |
| Debug Python | [Python DAP](nvim/DAP.md) |
| Maintain reusable prompts | [Prompt library](llm/README.md) |
| Change this repository | [Repository instructions](AGENTS.md) |

The documentation separates procedures, reference, and explanation, following
[Diataxis](https://diataxis.fr/).

## Prerequisites

- macOS on Apple Silicon or Intel.
- A terminal with true color support.
- JetBrainsMono Nerd Font for terminal, prompt, and editor icons.
- A clipboard provider for Neovim. See `:help clipboard-tool`.
- Codex and Claude Code installed and run once before the AI CLI install step.
  The installer requires `~/.codex/skills/.system`.

This repository configures the AI CLIs. It does not install them.

## Install order

Follow [the installation procedure](docs/how-to/install.md) in order:

1. Install Command Line Tools and Homebrew.
2. Clone to `~/.dotfiles` and install the Brewfile.
3. Link Zsh startup files and start a new shell.
4. Link Alacritty config.
5. Configure local AI settings and run the AI CLI installer.
6. Start Neovim and tmux.
7. Verify the installation.

The installation downloads packages and plugins and changes home-directory links.
Review the procedure before running it.

## The role of GNU Stow

Stow links three packages into `$HOME`:

| Package | Destination |
| --- | --- |
| `bootstrap` | `~/.zshenv` |
| `alacritty` | `~/.config/alacritty` |
| `ai-agents` | Codex and Claude configuration |

Most other tools read this checkout through `$XDG_CONFIG_HOME`.
Do not run Stow for `nvim`, `tmux`, or `zsh`.
See [the loading diagram and exceptions](docs/explanation/configuration-layout.md).

## Personalizing your setup

Keep identity, credentials, and machine-specific settings outside tracked files.

- Set Git identity in `~/.gitconfig`.
- Copy [the Codex local template](ai-agents/.codex/config.local.toml.example)
  to `~/.codex/config.local.toml`.
- Put machine-only Claude MCP servers in the ignored
  `ai-agents/.claude/mcp-servers.local.json`.
- Keep project-specific prompts in that project's `.prompts/` directory.

See [the personalization steps](docs/how-to/install.md#5-personalize-local-settings).

## Verifying the install

From `~/.dotfiles`, check links without changing the real home directory:

```sh
scripts/dry-run-install.sh
scripts/test-codex-skill-scope.sh
```

These checks use a temporary home. They do not install Homebrew packages or prove
that a fresh Mac can run every step.

For full validation, follow [the installation procedure](docs/how-to/install.md)
inside a clean macOS VM or on a spare Mac.
[UTM](https://mac.getutm.app/) and [Tart](https://tart.run/) are possible VM hosts.

For changes to scripts and configuration, use the relevant checks in
[AGENTS.md](AGENTS.md#build--development-commands).
