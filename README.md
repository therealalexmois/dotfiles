# macOS dotfiles

Personal macOS dotfiles for terminal, shell, editor, and developer-tooling configuration.
This README is meant to be sufficient on its own: following it top to bottom on a clean
macOS install reproduces the same environment. For the architecture and conventions behind
the config (not needed just to install it), see [AGENTS.md](AGENTS.md).

<!--toc:start-->
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Install order](#install-order)
- [Homebrew vs other install methods](#homebrew-vs-other-install-methods)
- [The role of GNU Stow](#the-role-of-gnu-stow)
- [Personalizing your setup](#personalizing-your-setup)
- [System Settings](#system-settings)
- [Terminal, tmux and Prompt](#terminal-tmux-and-prompt)
  - [Alacritty](#alacritty)
  - [tmux](#tmux)
  - [Starship prompt](#starship-prompt)
- [Shell (Zsh)](#shell-zsh)
- [Editor (Neovim)](#editor-neovim)
- [AI CLI agents (Codex + Claude)](#ai-cli-agents-codex-claude)
- [git](#git)
- [Programming Languages](#programming-languages)
  - [Python](#python)
  - [Node](#node)
  - [Rust](#rust)
  - [Lua](#lua)
  - [Go](#go)
- [CLI utilities](#cli-utilities)
- [FZF](#fzf)
- [Terminal System Monitors](#terminal-system-monitors)
- [Web Tools](#web-tools)
- [Documentation](#documentation)
- [Testing tools](#testing-tools)
- [Miscellaneous](#miscellaneous)
- [Macos misc](#macos-misc)
- [Content Creation](#content-creation)
- [Improving the Launcher](#improving-the-launcher)
- [Window Management](#window-management)
- [Rosetta](#rosetta)
- [Docker](#docker)
- [Nerd fonts](#nerd-fonts)
- [Verifying the install](#verifying-the-install)
<!--toc:end-->

## Overview

Top-level directories and what actually manages them:

| Directory | Holds | How it's picked up |
|---|---|---|
| `ai-agents/` | Codex + Claude Code config, shared agent skills | GNU Stow (`ai-agents/.claude/agents/…`, per-skill symlinks) |
| `alacritty/` | Alacritty terminal config, themes | GNU Stow (own package; Alacritty is a GUI app and won't see `$XDG_CONFIG_HOME`) |
| `atuin/` | Shell-history sync config | `$XDG_CONFIG_HOME/atuin/config.toml` (no symlink needed) |
| `bootstrap/` | `~/.zshenv` redirect, `install-alacritty.sh` | GNU Stow |
| `git/` | Global git excludes file | `$XDG_CONFIG_HOME/git/ignore` (no symlink needed) |
| `lazydocker/` | lazydocker config | `$XDG_CONFIG_HOME/lazydocker/config.yml` |
| `llm/` | Reusable CodeCompanion prompt library | read from `~/.dotfiles/llm/prompts/` by a hardcoded path in the nvim config – **the repo must live at exactly `~/.dotfiles`** |
| `mac-setup/` | `Brewfile` | `brew bundle --file mac-setup/Brewfile` |
| `mise/` | Node (and other runtime) version pin | `$XDG_CONFIG_HOME/mise/config.toml` |
| `nvim/` | AstroNvim user config | `$XDG_CONFIG_HOME/nvim` (no symlink; see the [Editor](#editor-neovim) section for the caveat this implies) |
| `scripts/` | Install/lint/render/audit scripts | invoked directly by path |
| `tmux/` | tmux config, TPM-managed plugins | `$XDG_CONFIG_HOME/tmux/tmux.conf` (tmux 3.1+ XDG support; no symlink) |
| `zsh/` | `.zshrc` / `.zprofile` / `.zshenv` / Oh My Zsh bootstrap | `zsh/bootstrap.zsh` creates individual `~/.zshrc` etc. symlinks (not Stow) |
| `starship.toml` (repo root) | Prompt config | `$STARSHIP_CONFIG`, exported by `zsh/.zshenv` |

A handful of other top-level directories (`docs/`, `glab-cli/`, `goose/`, `homebrew/`,
`htop/`, `k9s/`, `lazygit/`, `openspec/`) exist locally but are **not** part of a
reproducible install: they're either pure runtime/telemetry state, or config that's
deliberately kept out of git for tools not covered by this guide. Don't expect a fresh
clone to reproduce them.

The common thread for everything that isn't Stow-managed: `zsh/.zshenv` sets
`XDG_CONFIG_HOME=$HOME/.dotfiles`, so any tool that already respects the XDG base
directory spec reads its config straight out of the repo, with zero symlinks. Only tools
that don't respect XDG (Alacritty, a GUI app) or that need files in very specific
locations before other tools can see them (`~/.zshenv` itself, the Claude/Codex config
tree) need GNU Stow.

## Prerequisites

- macOS on Apple Silicon or Intel.
- [Nerd Fonts](https://www.nerdfonts.com/font-downloads) – used by the terminal, prompt,
  and Neovim icons.
- Terminal with true color support.
- A clipboard tool for Neovim's system clipboard integration (see
  [`:help clipboard-tool`](https://neovim.io/doc/user/provider.html#clipboard-tool)).
- [Codex CLI](https://github.com/openai/codex) and
  [Claude Code CLI](https://docs.claude.com/en/docs/claude-code/overview) – install and
  run each at least once (so `~/.codex` and `~/.claude`, including
  `~/.codex/skills/.system`, exist) before running the AI-agents install step below. This
  repo configures both CLIs; it doesn't install them.

## Install order

Run in this order. Each step depends on the ones before it (details in
[Overview](#overview) and the per-tool sections below).

```sh
# 1. Command Line Tools (git, etc.)
xcode-select --install

# 2. Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
brew analytics off

# 3. Clone the repo to exactly ~/.dotfiles – several scripts and configs hardcode this path
git clone https://github.com/therealalexmois/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# 4. Everything Homebrew installs or manages: formulae, casks, Nerd Fonts (see next section)
brew bundle --file mac-setup/Brewfile
# Alacritty's cask is adhoc-signed and quarantined by Gatekeeper on every install/upgrade:
xattr -dr com.apple.quarantine /Applications/Alacritty.app

# 5. Shell: symlink ~/.zshenv (sets ZDOTDIR + XDG_CONFIG_HOME), then the rest of zsh
stow --target "$HOME" bootstrap
zsh zsh/bootstrap.zsh
exec zsh   # reload so XDG_CONFIG_HOME / ZDOTDIR are active for every step below

# 6. Alacritty: GUI apps don't inherit shell env vars, so it needs its own symlink
bootstrap/install-alacritty.sh

# 7. AI CLI agents (Codex + Claude): stow config, render Codex TOML, link shared skills
#    Requires Codex and Claude Code CLI already installed – see Prerequisites.
scripts/install-ai-cli-dotfiles.sh

# 8. Neovim: bootstraps lazy.nvim on first launch (reads config via XDG_CONFIG_HOME,
#    so launch it from a terminal that has sourced the zsh env from step 5)
nvim

# 9. tmux: config and TPM plugin bootstrap are picked up automatically via XDG once
#    step 5 is done; source-file forces it on the very first run
tmux source-file ~/.dotfiles/tmux/tmux.conf
```

After this, do the one-time personal setup in
[Personalizing your setup](#personalizing-your-setup) before you start relying on the
Codex/Claude config.

## Homebrew vs other install methods

Most CLI tools and apps in this setup come from the tracked
[`mac-setup/Brewfile`](mac-setup/Brewfile) via `brew bundle`. A few things are
intentionally installed a different way:

| What | How | Why not Homebrew |
|---|---|---|
| Homebrew itself | official install script (`curl \| bash`, see [brew.sh](https://brew.sh)) | it's the bootstrap |
| Python interpreters, venvs, project tools | [`uv`](https://docs.astral.sh/uv/) (`brew install uv`, then `uv python install`) | `uv` replaces pyenv/pipx/poetry; only `uv` itself is a formula |
| Node (and other runtimes) | [`mise`](https://mise.jdx.dev/) (`brew install mise`, then `mise use -g node@lts`) | per-project version pinning via `mise.toml` |
| Rust | [`rustup`](https://rustup.rs/) install script | rustup manages toolchains itself |
| Oh My Zsh + its zsh plugins (`zsh-autosuggestions`, `fast-syntax-highlighting`, `zsh-completions`) | `git clone` by `zsh/bootstrap.zsh` | not packaged for Homebrew as a coherent unit |
| tmux plugins (Catppuccin, sessionx, resurrect, …) | [TPM](https://github.com/tmux-plugins/tpm), `git clone` on first `tmux` run | TPM is the standard tmux plugin workflow |
| Neovim plugins | [lazy.nvim](https://github.com/folke/lazy.nvim), bootstrapped on first `nvim` launch | plugin manager, not a system package |
| Codex CLI / Claude Code CLI | installed separately (npm-based; see each project's own docs) | not this repo's concern – it only configures them, see [Prerequisites](#prerequisites) |
| Docker Desktop | `cask "docker-desktop"` in the Brewfile, but see [Docker](#docker) | still a manual first-run step (license/start-up) |

Everything else – formulae and casks alike – is a plain entry in
[`mac-setup/Brewfile`](mac-setup/Brewfile); `brew bundle --file mac-setup/Brewfile`
installs all of it in one pass.

## The role of GNU Stow

[GNU Stow](https://www.gnu.org/software/stow/) symlinks a package directory's tree into a
target directory (here, always `$HOME`). It's used for exactly three packages, and only
because those three can't rely on `$XDG_CONFIG_HOME`:

| Package | `stow` target | Why Stow (not XDG) |
|---|---|---|
| `bootstrap` | `~/.zshenv` | has to exist at the fixed shell-startup location before `XDG_CONFIG_HOME` is even set |
| `alacritty` | `~/.config/alacritty` | Alacritty is a GUI app launched by macOS, so it never inherits the shell's `XDG_CONFIG_HOME` and always looks in the default `~/.config/alacritty` |
| `ai-agents` | `~/.claude/…`, `~/.codex/…`, `~/.agents/skills/…` | Claude Code and Codex expect real files/dirs at fixed paths, and `ai-agents/.claude/agents` uses a Stow "fold" (the parent `~/.claude` stays a real directory since Claude/Codex also write runtime state into it) |

Everything else in this repo (zsh's own rc files, tmux, Neovim, Starship, git, atuin,
mise, lazydocker) is picked up because `zsh/.zshenv` exports
`XDG_CONFIG_HOME=$HOME/.dotfiles` – the tool just reads its config straight from the repo,
with no symlink at all. `zsh/bootstrap.zsh` is the one exception that predates this
pattern: it symlinks `~/.zshrc`, `~/.zprofile`, and `~/.zlogin` by hand instead of using
Stow, because `ZDOTDIR` (also set by `bootstrap/.zshenv`) already makes zsh load its
startup files straight from `zsh/` – the symlinks mainly exist so tools that expect a
literal `~/.zshrc` to exist (like Oh My Zsh) find one.

Because of this, running `stow` for packages that aren't in the table above (`nvim`,
`tmux`, `zsh`) is a no-op at best and a broken/duplicate symlink at worst – don't do it.

## Personalizing your setup

This repo is public, so it deliberately keeps two kinds of things out of git:

- **git identity.** `~/.gitconfig` (name, email, `[user]` section) is not tracked here at
  all – set your own with `git config --global user.name` / `user.email` after cloning.
- **Machine- and account-specific values.** Copy
  [`ai-agents/.codex/config.local.toml.example`](ai-agents/.codex/config.local.toml.example)
  to `~/.codex/config.local.toml` and fill in your own project paths and any
  MCP/plugin settings – `config.shared.toml` (tracked) never gets machine-specific
  values, and `config.local.toml` itself is gitignored.

If you fork this repo, grep for your own username/paths before committing anything new
under `ai-agents/` – `config.local.toml.example` is a template, not a config file, and
should only ever contain placeholders like `<your-username>`.

## System Settings

- set caps lock to escape
- bump key repeat up by one notch
- set turn display off after 20 mins while on battery 30 mins while charging
- turn on night shift

## Terminal, tmux and Prompt

### Alacritty

[Alacritty](https://alacritty.org) is the terminal emulator. Config lives in
`alacritty/.config/alacritty/` (Stow package, see [The role of GNU Stow](#the-role-of-gnu-stow)).

```sh
brew install --cask alacritty
# Adhoc-signed cask fails Gatekeeper after every install/upgrade:
xattr -dr com.apple.quarantine /Applications/Alacritty.app
bootstrap/install-alacritty.sh
```

- Theme: GitHub Dark (`themes/github_dark.toml`), imported from `alacritty.toml`.
  `material_theme`, `material_theme_mod`, and `github_dark_default` sit in the same
  directory as ready alternates.
- Font: JetBrainsMono Nerd Font, size 14, pulled in by the
  `font-jetbrains-mono-nerd-font` cask (see [Nerd fonts](#nerd-fonts)).
- Window: 70% opacity, 160×48 default grid, 6px padding, no dynamic padding.
- Shell launches as `zsh --login`; `TERM=xterm-256color` with true color and undercurl
  enabled for tmux and Neovim.

### tmux

[tmux](https://github.com/tmux/tmux) is the terminal multiplexer. Once `XDG_CONFIG_HOME`
is set (Install order, step 5), it reads `tmux/tmux.conf` automatically; no symlink
needed.

```sh
brew install tmux
tmux source-file ~/.dotfiles/tmux/tmux.conf   # bootstraps TPM on first run
```

- Theme: [Catppuccin](https://github.com/catppuccin/tmux), Macchiato flavor, with a
  custom status bar (session, current command, path, network status, battery, time).
- Plugin manager: [TPM](https://github.com/tmux-plugins/tpm). Plugins declared in
  `tmux/tmux.conf`:
  [tmux-sensible](https://github.com/tmux-plugins/tmux-sensible),
  [tmux-online-status](https://github.com/tmux-plugins/tmux-online-status),
  [tmux-nerd-font-window-name](https://github.com/joshmedeski/tmux-nerd-font-window-name),
  [tmux-which-key](https://github.com/alexwforsythe/tmux-which-key) (`prefix + space`),
  [tmux-cpu](https://github.com/tmux-plugins/tmux-cpu),
  [tmux-battery](https://github.com/tmux-plugins/tmux-battery),
  [tmux-uptime](https://github.com/robhurring/tmux-uptime),
  [tmux-sessionx](https://github.com/omerxx/tmux-sessionx) (`prefix + o` – session
  switcher), [tmux-yank](https://github.com/tmux-plugins/tmux-yank), and
  [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect) +
  [tmux-continuum](https://github.com/tmux-plugins/tmux-continuum) for session
  autosave/restore.
- Prefix remapped to `C-a`; vim-style pane navigation (`hjkl`) and copy mode
  (`v`/`y`/`V`/`r`); mouse support on; panes split with `|` / `-`.
- Reload config with `prefix + r`.

### Starship prompt

[Starship](https://starship.rs) is the shell prompt.

```sh
brew install starship
# .zshrc already runs: eval "$(starship init zsh)" on top of Oh My Zsh
```

- Config: `starship.toml`, loaded via `$STARSHIP_CONFIG` (exported by `zsh/.zshenv`).
- Tuned for fast rendering: `command_timeout = 1000`, `scan_timeout = 50`.
- `git_status` module disabled; segment formats wrapped in `\[...\]` for clean
  rendering across terminals and inside tmux.

## Shell (Zsh)

[Zsh](https://www.zsh.org) ships with macOS; the setup layers
[Oh My Zsh](https://ohmyz.sh) on top.

```sh
stow --target "$HOME" bootstrap   # ~/.zshenv -> sets ZDOTDIR, XDG_CONFIG_HOME
zsh zsh/bootstrap.zsh             # symlinks .zshrc/.zprofile/.zlogin, clones Oh My Zsh
```

- `bootstrap/.zshenv` sets `ZDOTDIR=$HOME/.dotfiles/zsh`, so zsh loads its startup files
  straight from the repo.
- `zsh/.zshenv` exports the XDG base dirs, `STARSHIP_CONFIG`, `GOPATH`, and `$EDITOR`.
- `zsh/.zshrc` enables the `git`, `docker`, `macos`, `brew`, `kubectl`/`minikube`, and
  `poetry` Oh My Zsh plugins, plus `zsh-autosuggestions`, `fast-syntax-highlighting`, and
  `zsh-completions` (cloned by `zsh/bootstrap.zsh` into `zsh/custom/plugins/`).
- Tool init (`starship`, `mise`, `atuin`, `zoxide`) is cached to a file and only
  regenerated when the binary is newer than the cache, to avoid one `exec` per shell
  startup.

## Editor (Neovim)

[Neovim](https://neovim.io) with [AstroNvim](https://astronvim.com) as the base
distribution.

```sh
brew install neovim
nvim   # bootstraps lazy.nvim on first launch
```

- Requires [Neovim 0.11+ stable](https://github.com/neovim/neovim/releases/tag/stable)
  (AstroNvim v6 baseline) and, optionally,
  [Tree-sitter CLI](https://github.com/tree-sitter/tree-sitter/blob/master/cli/README.md)
  for `auto_install`.
- Neovim language providers (`:python3`/`:node`) are optional – AstroNvim v6 relies on
  Mason-managed LSPs – so only install the `pynvim`/`neovim` host packages if a specific
  plugin needs them.
- **Caveat**: config is found via `$XDG_CONFIG_HOME/nvim`, not a symlink at
  `~/.config/nvim`. Launching `nvim` from a terminal that sourced the zsh env (Install
  order, step 5) works correctly; a GUI launcher that doesn't inherit shell env vars
  (e.g. a Dock icon, Spotlight, or a non-terminal wrapper) will silently fall back to an
  empty `~/.config/nvim` instead.
- Plugin-adjacent tools also referenced from AstroNvim keybindings:
  [ripgrep](https://github.com/BurntSushi/ripgrep) (`<leader>fw` live grep),
  [lazygit](https://github.com/jesseduffield/lazygit) (`<leader>tl`/`<leader>gg`),
  [gdu](https://github.com/dundee/gdu) (`<leader>tu`),
  [bottom](https://github.com/ClementTsang/bottom) (`<leader>tt`), plus Python/Node
  REPL toggles (`<leader>tp`/`<leader>tn`).
- A clipboard tool is required for system-clipboard integration – see
  [`:help clipboard-tool`](https://neovim.io/doc/user/provider.html#clipboard-tool).

## AI CLI agents (Codex + Claude)

```sh
scripts/install-ai-cli-dotfiles.sh
```

Requires the [Codex CLI](https://github.com/openai/codex) and
[Claude Code CLI](https://docs.claude.com/en/docs/claude-code/overview) already installed
and run at least once (see [Prerequisites](#prerequisites)) – the script validates that
`~/.codex/skills/.system` exists before touching anything.

The script (idempotent, backs up any real-file conflicts to a timestamped directory
under `~/.dotfiles-backups/`):

1. Renders `~/.codex/config.toml` from `ai-agents/.codex/config.shared.toml` +
   `~/.codex/config.local.toml` via `scripts/render-codex-config.py`.
2. Stows `ai-agents` (`~/.codex/AGENTS.md`, `~/.claude/CLAUDE.md`,
   `~/.claude/settings.json`, `~/.claude/agents/`).
3. Symlinks every skill under `ai-agents/.agents/skills/` into `~/.agents/skills/`, with
   child links from `~/.claude/skills/` and `~/.codex/skills/`, and prunes stale links for
   renamed/removed skills.
4. Symlinks the bundled `git-worktree/scripts/agent-worktree-create` command into
   `~/.local/bin/` for both Codex and the Claude WorktreeCreate hook.
5. Symlinks Codex reasoning/mode profile TOML files into `~/.codex/`.

See [Personalizing your setup](#personalizing-your-setup) for the local-only
`config.local.toml` you need to create before this is useful.

## git

Global excludes live at `git/ignore`, read from `$XDG_CONFIG_HOME/git/ignore` once
`zsh/.zshenv` has exported `XDG_CONFIG_HOME` (Install order, step 5) – no symlink needed.
This only works for git invocations that inherit the shell's environment; a GUI git
client that doesn't source your shell config won't see it.

Git identity (`user.name`, `user.email`) is intentionally **not** part of this repo – set
it yourself, see [Personalizing your setup](#personalizing-your-setup).

## Programming Languages

### Python

Python is managed with [uv](https://docs.astral.sh/uv/) – interpreters, virtualenvs,
dependencies, and CLI tools (replaces pyenv, pipx, and poetry):

```sh
brew install uv

# Global interpreter; exposes python/python3 on PATH (~/.local/bin):
uv python install 3.13 --default
```

- Per-project: `uv init`, `uv add <pkg>`, `uv run ...` – the Python version is pinned via
  `uv.lock` / `.python-version`, reproducible across machines.
- Global CLI tools (pipx replacement): `uv tool install <tool>`.

### Node

Node is managed with [mise](https://mise.jdx.dev/) – it also handles other runtimes and
per-project version pins via `mise.toml`:

```sh
brew install mise

# .zshrc already runs: eval "$(mise activate zsh)"
mise use -g node@lts     # global Node (writes ~/.dotfiles/mise/config.toml)
```

- Per-project: `mise use node@<version>` writes a tracked `mise.toml` pin.

### Rust

This should be all you need to install rust, via [rustup](https://rustup.rs/):

```sh
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

### Lua

```sh
brew install lua
brew install stylua
```

[stylua](https://github.com/JohnnyMorganz/StyLua) formats the first-party Lua in
`nvim/`.

### Go

```sh
brew install go
```

I hate that they put a go directory right in my home directory. I personally change the GOPATH like this:

```sh
export GOPATH=$HOME/.local/share/go
export PATH=$HOME/.local/share/go/bin:$PATH
```

then remove the other one:

```sh
sudo rm -rf ~/go
```

## CLI utilities

```sh
brew install tree    # https://github.com/Old-Man-Programmer/tree - see the outline of a directory
brew install zoxide  # https://github.com/ajeetdsouza/zoxide - jump anywhere within your filesystem with z <foldername>
brew install ripgrep # https://github.com/BurntSushi/ripgrep - blazingly fast grep
brew install fd      # https://github.com/sharkdp/fd - blazingly fast find
```

## FZF

[fzf](https://github.com/junegunn/fzf):

```sh
brew install fzf
$(brew --prefix)/opt/fzf/install
```

After installation you will be able to press control-r to interactively search history

Also you can pipe any output in to fzf and fuzzy search over it for example:

```sh
brew list | fzf
```

## Terminal System Monitors

```sh
brew install htop    # https://htop.dev - process monitor
brew install bottom  # https://github.com/ClementTsang/bottom - process viewer (AstroNvim <leader>tt)
brew install gdu     # https://github.com/dundee/gdu - disk usage analyzer (AstroNvim <leader>tu)
brew install lazygit # https://github.com/jesseduffield/lazygit - git ui (AstroNvim <leader>tl)
```

## Web Tools

```sh
brew install insomnia
brew install wget    # https://www.gnu.org/software/wget/
brew install httpie
brew install jq      # https://jqlang.github.io/jq/
brew install ngrok
npm install -g http-server
```

## Documentation

```sh
brew install tldr    # https://tldr.sh
```

## Testing tools

[wrk](https://github.com/wg/wrk) - a HTTP benchmarking tool

```sh
brew install wrk
```

## Miscellaneous

[nmap](https://nmap.org/) – is an open source tool for network exploration and security auditing.

```sh
brew install nmap
```

## Macos misc

- [macOS system monitor](https://github.com/exelban/stats)
- [clock](https://www.mowglii.com/itsycal/)

## Content Creation

```sh
brew install obs     # to record my screen
brew install gimp    # image editing
brew install blender # video editing
```

## Improving the Launcher

```sh
brew install raycast
```

## Window Management

```sh
brew install rectangle
```

## Rosetta

Rosetta will allow you to run software compiled for x86_64 architecture on Apple silicon.

```sh
softwareupdate --install-rosetta
```

## Docker

Follow the instructions at the following link to install docker desktop for Apple silicon.

[docker desktop](https://docs.docker.com/desktop/install/mac-install/)

```sh
brew install lazydocker
```

Make sure to stop docker desktop after installing and set it to not auto-start since it is pretty resource hungry.

## Nerd fonts

```sh
brew install fontconfig
```

Useful gist for install fonts: [font gist](https://gist.github.com/davidteren/898f2dcccd42d9f8680ec69a3a5d350e)

You can also download your own fonts and place them in ~/Library/Fonts, or get the
[Nerd Fonts](https://www.nerdfonts.com) this setup uses directly from
[the download page](https://www.nerdfonts.com/font-downloads) (JetBrainsMono is pinned in
`alacritty.toml`).

## Verifying the install

Two levels of check, for two different things:

- **Symlink/script correctness** – run `scripts/dry-run-install.sh`. It stows and links
  everything into a throwaway fake `$HOME` (a symlink to this repo, plus stow/script
  runs against it) without touching your real home directory or installing any Homebrew
  package, and reports any symlink that doesn't point where the [Overview](#overview)
  table says it should. Safe to run repeatedly; cheap enough to run after every change to
  `bootstrap/`, `zsh/bootstrap.zsh`, or `scripts/install-ai-cli-dotfiles.sh`.
- **Full reproducibility** – the dry run never installs a Homebrew package or exercises
  `brew bundle`, so it can't catch a missing Brewfile entry or a step that only works
  because something was already installed on this machine. Periodically validate the
  whole README end to end on a genuinely clean macOS environment (a fresh VM, e.g.
  [UTM](https://mac.getutm.app/) or [Tart](https://tart.run/), or a spare machine) by
  following [Install order](#install-order) from a blank state.

Existing lint/check commands from [AGENTS.md](AGENTS.md#build--development-commands) are
part of the same discipline: `stylua --check nvim`, `(cd nvim && selene .)`,
`zsh -n bootstrap/.zshenv zsh/.zshenv zsh/.zprofile zsh/.zshrc zsh/bootstrap.zsh`, and
`scripts/check-ai-cli.sh` – run them before trusting a change to any of the files they
cover.
