echo "Loading ${USER} .zshrc..."

plugins=(
  git
  colored-man-pages colorize
  docker docker-compose
  macos
  brew
  zsh-autosuggestions
  fast-syntax-highlighting
  zsh-completions
  poetry
  kubectl minikube
  fnm
)

# Source Oh My Zsh
source "$ZSH/oh-my-zsh.sh"

# --- Load completions ---
fpath+=("${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-completions/src")

# --- Aliases ---
alias n='nvim .'

# Pyenv shell integration
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init - zsh)"
fi

# --- Starship prompt ---
if command -v starship >/dev/null; then
  eval "$(starship init zsh)"
fi

# --- fnm (Fast Node Manager) ---
if command -v fnm >/dev/null; then
  eval "$(fnm env --use-on-cd)"
fi

# --- fzf ---
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh

# --- McFly (fuzzy history search) ---
if command -v mcfly >/dev/null; then
  export MCFLY_KEY_SCHEME=vim
  export MCFLY_FUZZY=2
  export MCFLY_RESULTS_SORT=LAST_RUN
  eval "$(mcfly init zsh)"
fi

# --- History Options ---
export HISTSIZE=10000000
export SAVEHIST=10000000
export HIST_STAMPS="%T %d.%m.%y"
export HISTIGNORE="ls:cd:pwd:exit"

setopt EXTENDED_HISTORY
setopt HIST_IGNORE_SPACE

# --- Performance tweaks for Git repos ---
DISABLE_UNTRACKED_FILES_DIRTY=true

DISABLE_AUTO_TITLE="true"

# --- Prompt: clean multi-line rendering ---
setopt PROMPT_SUBST

# --- LLM configuration for https://github.com/Kurama622/llm.nvim ---
export LLM_KEY=NONE
