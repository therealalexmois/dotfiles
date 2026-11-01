# Install the dotfiles on macOS

Use this procedure for a new checkout at `~/.dotfiles`.
Run shell commands in Terminal as your own user unless a tool asks otherwise.

The procedure downloads packages and plugins. It changes shell startup files,
configuration links, and AI CLI settings. Back up existing configuration first.
The AI installer backs up its own conflicts under `~/.dotfiles-backups/`.

## 1. Install Command Line Tools and Homebrew

```sh
xcode-select --install
```

Wait for installation to finish. Then install Homebrew:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Follow the installer's `brew shellenv` instructions for your Mac.
Homebrew normally uses `/opt/homebrew` on Apple Silicon and `/usr/local` on Intel.

```sh
brew --version
brew analytics off
```

`brew --version` must print a version before you continue.

## 2. Clone and install packages

The destination is required by hardcoded prompt and script paths.
If `~/.dotfiles` already exists, inspect it before cloning.

```sh
git clone https://github.com/therealalexmois/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
brew bundle --file mac-setup/Brewfile
```

The [Brewfile](../../mac-setup/Brewfile) is the package source of truth.
A package may become unavailable upstream; resolve a failed bundle before
continuing with steps that depend on it.

The tracked Alacritty cask has a Gatekeeper workaround. Only remove quarantine
from an application whose origin you have verified:

```sh
xattr -dr com.apple.quarantine /Applications/Alacritty.app
```

## 3. Configure Zsh

From `~/.dotfiles`:

```sh
stow --target "$HOME" bootstrap
zsh zsh/bootstrap.zsh
exec zsh
```

The bootstrap links startup files and installs Oh My Zsh/plugins when missing.
After the new shell starts, return to the checkout and verify the environment:

```sh
cd ~/.dotfiles
printf '%s\n' "$ZDOTDIR" "$XDG_CONFIG_HOME"
```

Expected paths, with your home directory in place of `~`:

```text
~/.dotfiles/zsh
~/.dotfiles
```

An existing `XDG_CONFIG_HOME` overrides the default. Check it if the second path
differs from the checkout.

## 4. Link Alacritty

```sh
bootstrap/install-alacritty.sh
```

The script links the Stow package to `~/.config/alacritty`.
Open Alacritty and check its configured font and theme.

## 5. Personalize local settings

Git identity is not tracked. Set it with your own values:

```sh
git config --global user.name 'Your Name'
git config --global user.email 'you@example.com'
```

Create `~/.codex/config.local.toml` from the tracked template if it does not
already exist:

```sh
mkdir -p ~/.codex
cp -n ai-agents/.codex/config.local.toml.example ~/.codex/config.local.toml
chmod 600 ~/.codex/config.local.toml
```

Edit the local file before using it. Keep project trust paths and account-specific
settings there. Local values override `config.shared.toml` during rendering.

For machine-only Claude MCP servers, use the ignored file
`ai-agents/.claude/mcp-servers.local.json`. Use the format of
`ai-agents/.claude/mcp-servers.json`.

Never add credentials or real machine-specific values to the tracked template.

## 6. Install AI CLI configuration

Install [Codex CLI](https://github.com/openai/codex) and
[Claude Code](https://code.claude.com/docs/en/overview) separately. Run each once.
The dotfiles installer requires `~/.codex/skills/.system` to exist.

```sh
scripts/install-ai-cli-dotfiles.sh
```

The installer:

1. Backs up existing AI configuration and links.
2. Creates a local Codex fragment from existing project trust entries when needed.
3. Stows `bootstrap` and `ai-agents`.
4. Renders Codex config from shared and local TOML.
5. Links skills and Codex profiles.
6. Syncs Claude user-scope MCP servers.
7. Prints a validation summary.

Unexpected symlink targets cause an error. Inspect the conflict before retrying.
Restart Codex and Claude after configuration or link changes.

To update skill links without rendering config or syncing MCP servers:

```sh
scripts/install-ai-cli-dotfiles.sh --skills-only
```

See [skill placement](../reference/tools.md#ai-cli-skills-and-config).

## 7. Start Neovim and tmux

Start Neovim from the configured shell:

```sh
nvim
```

The first launch bootstraps lazy.nvim and plugins.
See [Neovim setup and checks](../../nvim/README.md).

Start tmux:

```sh
tmux
```

The config bootstraps TPM when missing. To reload an existing server from a shell:

```sh
tmux source-file ~/.dotfiles/tmux/tmux.conf
```

Inside tmux, `Ctrl-a`, then `r`, reloads the config.

## 8. Verify the installation

From `~/.dotfiles`:

```sh
scripts/dry-run-install.sh
scripts/test-codex-skill-scope.sh
scripts/check-ai-cli.sh
```

The first two checks use temporary home directories.
The AI CLI check validates syntax, TOML rendering, skill links, and helper scripts.
It does not prove authentication or provider connectivity.

For full reproducibility, repeat this procedure on a clean macOS VM or spare Mac.
The dry run does not install Brewfile packages or exercise every application.

## Optional macOS preferences

- Map Caps Lock to Escape.
- Increase key repeat by one notch.
- Set display sleep to 20 minutes on battery and 30 minutes on power.
- Enable Night Shift.
- On Apple Silicon, install Rosetta only if an x86_64 application needs it:

  ```sh
  softwareupdate --install-rosetta
  ```
