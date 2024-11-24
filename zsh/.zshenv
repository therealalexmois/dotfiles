echo "Loading .zshenv..."
. "$HOME/.cargo/env"

# XDG
export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.dotfiles}
# export XDG_CACHE_HOME=${XDG_CACHE_HOME:-$HOME/.cache}
# export XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
# export XDG_STATE_HOME=${XDG_STATE_HOME:-$HOME/.local/state}
# export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-$HOME/.xdg}
# export XDG_PROJECTS_DIR=${XDG_PROJECTS_DIR:-$HOME/Projects}

# ZSH
export ZSH_ROOT="$XDG_CONFIG_HOME/zsh"
export ZSH=${ZSH:-$XDG_CONFIG_HOME/zsh/.oh-my-zsh}
export HISTFILE="$ZSH_ROOT/.zsh_history"

# export NVM_DIR="$XDG_CONFIG_HOME/.nvm"

# Pyenv
export PYENV_ROOT=${PYENV_ROOT:-$XDG_CONFIG_HOME/.pyenv}
export PATH="$PATH:$PYENV_ROOT/bin"

# Starship
export STARSHIP_CONFIG=${STARSHIP_CONFIG:-$XDG_CONFIG_HOME/starship.toml}

# Go
export GOPATH=$HOME/.local/share/go
export PATH=$HOME/.local/share/go/bin:$PATH

# Zellij
export ZELLIJ_CONFIG_DIR="$XDG_CONFIG_HOME/zellij"

# Wezterm
export WEZTERM_CONFIG_FILE="$XDG_CONFIG_HOME/wezterm/wezterm.lua"
