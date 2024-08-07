. "$HOME/.cargo/env"

export XDG_CONFIG_HOME=$HOME/.dotfiles

export ZSH="$XDG_CONFIG_HOME/zsh/.oh-my-zsh"

# export NVM_DIR="$XDG_CONFIG_HOME/.nvm"

export PYENV_ROOT="$XDG_CONFIG_HOME/.pyenv"

export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship.toml"

# Go
export GOPATH=$HOME/.local/share/go
export PATH=$HOME/.local/share/go/bin:$PATH

# Poetry
# Zellij
export ZELLIJ_CONFIG_DIR="$XDG_CONFIG_HOME/zellij"

# Wezterm
export WEZTERM_CONFIG_FILE="$XDG_CONFIG_HOME/wezterm/wezterm.lua"
