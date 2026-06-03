# MacOS configuration

<!--toc:start-->
- [System Settings](#system-settings)
- [Command Line Tools](#command-line-tools)
- [Install brew](#install-brew)
- [Requirements](#requirements)
- [Installation](#installationhttpsgithubgithubassetscomimagesiconsemojiunicode1f6e0png-installation)
- [Macos misc](#macos-misc)
- [Content Creation](#content-creation)
- [Improving the Launcher](#improving-the-launcher)
- [Window Management](#window-management)
- [CLI utilities](#cli-utilities)
- [FZF](#fzf)
- [Terminal System Monitors](#terminal-system-monitors)
- [Web Tools](#web-tools)
- [Documentation](#documentation)
- [Programming Languages](#programming-languages)
  - [Python](#python)
  - [Node](#node)
  - [Rust](#rust)
  - [Lua](#lua)
  - [Go](#go)
- [Install Neovim](#install-neovim)
- [Rosetta](#rosetta)
- [Docker](#docker)
- [Install my dotfiles](#install-my-dotfiles)
- [Nerd fonts](#nerd-fonts)
- [Testing tools](#testing-tools)
- [Miscellaneous](#miscellaneous)
<!--toc:end-->

## System Settings
- set caps lock to escape
- bump key repeat up by one notch
- set turn display off after 20 mins while on battery 30 mins while charging
- turn on night shift

## Command Line Tools

```sh
xcode-select --install
```

## Install brew

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

echo '# Set PATH, MANPATH, etc., for Homebrew.' >> /Users/<your_user_name>/.zprofile
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/<your_user_name>/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

brew analytics off
```

Install packages from the tracked Brewfile:

```sh
brew bundle --file mac-setup/Brewfile
```

Language runtimes are managed outside Homebrew: Python via `uv`, Node via `mise`
(see [Programming Languages](#programming-languages)). Neovim language providers are
optional — AstroNvim v6 relies on Mason-managed LSPs — so install the `pynvim` / `neovim`
host packages only if a specific plugin needs the `:python3` / `:node` provider.

---

## Requirements

- [Nerd Fonts](https://www.nerdfonts.com/font-downloads) (Optional with manual intervention: See Documentation on customizing icons)
- [Neovim 0.11+ (stable, not nightly)](https://github.com/neovim/neovim/releases/tag/stable) — AstroNvim v6 baseline
- [Tree-sitter CLI](https://github.com/tree-sitter/tree-sitter/blob/master/cli/README.md) (Note: This is only necessary if you want to use auto_install feature with Treesitter)
- A clipboard tool is necessary for the integration with the system clipboard (see [:help clipboard-tool](https://neovim.io/doc/user/provider.html#clipboard-tool) for supported solutions)
- Terminal with true color support (for the default theme, otherwise it is dependent on the theme you are using)
- [ripgrep](https://github.com/BurntSushi/ripgrep) - live grep telescope search (<leader>fw)
- [lazygit](https://github.com/jesseduffield/lazygit) - git ui toggle terminal (<leader>tl or <leader>gg)
- [Python](https://www.python.org/) - python repl toggle terminal (<leader>tp)
- [Node](https://nodejs.org/en) - node repl toggle terminal (<leader>tn)
- [gdu](https://github.com/dundee/gdu) - disk usage toggle terminal (<leader>tu)
- [bottom](https://github.com/ClementTsang/bottom) - process viewer toggle terminal (<leader>tt)

## ![Installation](https://github.githubassets.com/images/icons/emoji/unicode/1f6e0.png) Installation

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

## CLI utilities

```sh
brew install tree    # see the outline of a directory
brew install zoxide  # jump anywhere within your filesystem with z <foldername>
brew install ripgrep # blazingly fast grep
brew install fd      # blazingly fast find
```

## FZF

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
brew install htop    # process monitor
brew install bottom  # process viewer (AstroNvim <leader>tt)
brew install gdu     # disk usage analyzer (AstroNvim <leader>tu)
brew install lazygit # git ui (AstroNvim <leader>tl)
```

## Web Tools

```sh
brew install insomnia
brew install wget
brew install httpie
brew install jq
brew install ngrok
npm install -g http-server
```

## Documentation

```sh
brew install tldr
```

## Programming Languages

### Python

Python is managed with [uv](https://docs.astral.sh/uv/) — interpreters, virtualenvs,
dependencies, and CLI tools (replaces pyenv, pipx, and poetry):

```sh
brew install uv

# Global interpreter; exposes python/python3 on PATH (~/.local/bin):
uv python install 3.13 --default
```

- Per-project: `uv init`, `uv add <pkg>`, `uv run ...` — the Python version is pinned via
  `uv.lock` / `.python-version`, reproducible across machines.
- Global CLI tools (pipx replacement): `uv tool install <tool>`.

### Node

Node is managed with [mise](https://mise.jdx.dev/) — it also handles other runtimes and
per-project version pins via `mise.toml`:

```sh
brew install mise

# .zshrc already runs: eval "$(mise activate zsh)"
mise use -g node@lts     # global Node (writes ~/.dotfiles/mise/config.toml)
```

- Per-project: `mise use node@<version>` writes a tracked `mise.toml` pin.

### Rust

This should be all you need to install rust.

```sh
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

### Lua

```sh
brew install lua
brew install stylua
```

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

## Install Neovim

Neovim is my text editor of choice

I install Neovim from source you can probably just:

```sh
brew install neovim
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

## Install my dotfiles

```sh
brew install stow
git clone https://github.com/therealalexmois/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Shell: symlink ~/.zshenv to the bootstrap entrypoint, then link zsh startup files.
stow --target "$HOME" bootstrap
zsh zsh/bootstrap.zsh

# AI CLI agents (Codex + Claude): stow ai-agents, render Codex config, link skills/profiles.
scripts/install-ai-cli-dotfiles.sh
```

## Nerd fonts

```sh
brew install fontconfig
```

Useful gist for install fonts: [font gist](https://gist.github.com/davidteren/898f2dcccd42d9f8680ec69a3a5d350e)

You can also download your own fonts and place them in ~/Library/Fonts

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
