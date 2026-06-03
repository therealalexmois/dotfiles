# Load Rust's environment
if [ -f "$HOME/.cargo/env" ]; then
  . "$HOME/.cargo/env"
fi

# XDG base dirs
export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.dotfiles}
export XDG_CACHE_HOME=${XDG_CACHE_HOME:-$HOME/.cache}
export XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
export XDG_STATE_HOME=${XDG_STATE_HOME:-$HOME/.local/state}

# ZSH root and history
export ZSH_ROOT="$XDG_CONFIG_HOME/zsh"
export ZSH="$ZSH_ROOT/.oh-my-zsh"
export ZSH_CUSTOM="$ZDOTDIR/custom"
export HISTFILE="$ZSH_ROOT/.zsh_history"

# Local user binaries (uv-managed Python shims and `uv tool` installs land here)
export PATH="$HOME/.local/bin:$PATH"

# Starship
export STARSHIP_CONFIG="${XDG_CONFIG_HOME}/starship.toml"

# Go
export GOPATH="$XDG_DATA_HOME/go"
export PATH="$GOPATH/bin:$PATH"

# Zellij
export ZELLIJ_CONFIG_DIR="$XDG_CONFIG_HOME/zellij"

# Wezterm
export WEZTERM_CONFIG_FILE="$XDG_CONFIG_HOME/wezterm/wezterm.lua"
