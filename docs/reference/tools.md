# Tool and path reference

Use this page to locate configuration and choose an install method.
For the ordered setup procedure, see [Install the dotfiles](../how-to/install.md).
The [Brewfile](../../mac-setup/Brewfile) lists the packages installed by the bundle.

## Configuration paths

| Path | Contents | Loaded by |
| --- | --- | --- |
| `ai-agents/` | AI CLI config and skills | Stow and the AI installer |
| `alacritty/.config/alacritty/` | Terminal config and themes | Stow link |
| `atuin/config.toml` | Shell history config | XDG |
| `bootstrap/` | Home-level startup links | Stow |
| `git/ignore` | Global Git excludes | XDG |
| `lazydocker/config.yml` | Docker terminal UI config | XDG |
| `llm/prompts/` | Reusable editor prompts | Hardcoded `~/.dotfiles` path |
| `mac-setup/Brewfile` | Homebrew packages | `brew bundle` |
| `mise/config.toml` | Node and npm CLI selections | XDG |
| `nvim/` | AstroNvim configuration | XDG |
| `scripts/` | Install, render, audit, and check helpers | Direct invocation |
| `starship.toml` | Shell prompt | `$STARSHIP_CONFIG` |
| `tmux/tmux.conf` | tmux and plugin settings | XDG, tmux 3.1+ |
| `zsh/` | Shell startup and plugin bootstrap | `$ZDOTDIR` and home links |

## Install methods

| Component | Manager or procedure |
| --- | --- |
| CLI tools and applications in the Brewfile | `brew bundle --file mac-setup/Brewfile` |
| Python interpreters, environments, and CLI tools | uv |
| Node and selected global npm CLIs | mise |
| Rust toolchains | rustup |
| Oh My Zsh and Zsh plugins | `zsh/bootstrap.zsh` |
| tmux plugins | TPM, bootstrapped by the tmux config |
| Neovim plugins | lazy.nvim, bootstrapped at first launch |
| Codex and Claude Code | Separate installation; this repo supplies config |

Optional tools below are not all in the Brewfile. Install only those you need.

## Terminal and shell

| Component | Settings |
| --- | --- |
| Alacritty | GitHub Dark; JetBrainsMono Nerd Font, size 14; opacity 0.7; grid 160 x 48; padding 6px |
| Alacritty shell | `zsh --login`; `TERM=xterm-256color` |
| tmux | `Ctrl-a` prefix; mouse on; `hjkl` pane navigation; `\|` and `-` split panes |
| tmux copy mode | `v`, `y`, `V`, `r` |
| tmux reload | Prefix, then `r` |
| tmux session switcher | Prefix, then `o` |
| tmux key help | Prefix, then Space |
| Starship | `command_timeout = 1000`, `scan_timeout = 50`; `git_status` disabled |

Alacritty alternative themes sit beside `alacritty.toml`:
`material_theme`, `material_theme_mod`, and `github_dark_default`.
Fonts can also be installed under `~/Library/Fonts`.
See [Nerd Fonts downloads](https://www.nerdfonts.com/font-downloads).

The tmux config declares Catppuccin Macchiato, sensible defaults, online status,
Nerd Font window names, which-key, CPU, battery, uptime, sessionx, yank,
resurrect, and continuum. The status bar shows session, command, path, network,
battery, and time. Resurrect/continuum provide session save and restore.

Zsh enables Oh My Zsh plugins for Git, Docker, macOS, Homebrew, Kubernetes,
Minikube, and Poetry. It also loads autosuggestions, syntax highlighting,
and completions from `zsh/custom/plugins/`.

## AI CLI skills and config

| Target | Selection |
| --- | --- |
| `~/.claude/skills/` | All source skills except project-only and external-project names |
| `~/.agents/skills/` | `scripts/codex-global-skills.txt` |
| This repo's `.claude/skills/` | `scripts/claude-project-only-skills.txt` |
| Another project's skill directories | Per-machine `scripts/link-project-skill.sh` |
| `~/.codex/skills/.system` | Preserved by the installer |

Skill source: `ai-agents/.agents/skills/`.
The installer prunes legacy repository-managed Codex links and preserves
unrelated live links.

Codex config is rendered from shared and local TOML. Local values win.
Claude MCP sources are `ai-agents/.claude/mcp-servers.json` and the optional
ignored `mcp-servers.local.json`.

For local activation statistics and report limits, see
[the skill usage report](skill-usage-report.md).

## Language tools

### Python

uv manages interpreters, environments, dependencies, and CLI tools:

```sh
uv python install 3.13 --default
uv tool install <tool>
```

In a project, use `uv init`, `uv add <package>`, and `uv run <command>`.
`.python-version` selects the interpreter; `uv.lock` records dependency resolution.
The shell adds `~/.local/bin` to `PATH`.

### Node

The tracked mise config selects `node = "lts"` and selected npm CLIs.
The shell activates mise and exposes its shims to non-interactive shells.

```sh
mise use -g node@lts
```

This command changes the global mise config in the checkout.
For a project pin, use `mise use node@<version>` in that project.

### Rust, Lua, and Go

Install Rust with [rustup](https://rustup.rs/):

```sh
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

Lua and Go are optional Homebrew installs:

```sh
brew install lua go
```

StyLua formats the first-party Lua under `nvim/`.
The shell sets `GOPATH=$XDG_DATA_HOME/go` and adds `$GOPATH/bin` to `PATH`.
Existing files under `~/go` are not migrated or deleted automatically.

## CLI and optional applications

| Task | Tools |
| --- | --- |
| File search/navigation | `tree`, `zoxide`, `ripgrep`, `fd`, `fzf` |
| Process and disk inspection | `htop`, `bottom`, `gdu` |
| Git and Docker terminal UIs | `lazygit`, `lazydocker` |
| HTTP and JSON | `wget`, `httpie`, `jq` |
| Command examples | `tlrc` (`tldr`) |
| Network inspection | `nmap` |
| Optional web tools | Insomnia, ngrok, `http-server` |
| Optional load testing | `wrk` |
| Optional content creation | OBS, GIMP, Blender |
| Launcher/window management | Raycast; optional Rectangle |
| Optional macOS status tools | [Stats](https://github.com/exelban/stats), [Itsycal](https://www.mowglii.com/itsycal/) |

For fuzzy selection:

```sh
brew list | fzf
```

Atuin owns the configured `Ctrl-r` history binding.
The optional fzf installer can add shell bindings, which may conflict with it:

```sh
"$(brew --prefix)/opt/fzf/install"
```

For Docker Desktop, follow [the macOS install guide](https://docs.docker.com/desktop/install/mac-install/).
Complete its first-run setup. Disable automatic startup if you want to start it manually.
