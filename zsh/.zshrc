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
)

# OMZ reads HIST_STAMPS at source time, so set it before sourcing.
export HIST_STAMPS="%T %d.%m.%y"

# Source Oh My Zsh
source "$ZSH/oh-my-zsh.sh"

# --- Load completions ---
fpath+=("${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-completions/src")

# --- Aliases ---
alias n='nvim .'
alias anki='open -a Anki'
diag-lang() {
  echo "=== Input Source ==="
  defaults read ~/Library/Preferences/com.apple.HIToolbox.plist AppleSelectedInputSources 2>/dev/null | grep -E "Name|Bundle"
  echo "=== Tmux Panes ==="
  tmux list-panes -a -F "#{pane_id} active=#{pane_active} cmd=#{pane_current_command} pid=#{pane_pid}" 2>/dev/null
  echo "=== TextInputMenuAgent ==="
  ps -p "$(pgrep TextInputMenuAgent)" -o pid,etime,stat 2>/dev/null
  echo "=== Recent HID events ==="
  log show --predicate 'subsystem == "com.apple.HIToolbox"' --last 15s --style compact 2>/dev/null | grep -i "input\|source\|switch" | tail -15
}

# --- Starship prompt ---
if command -v starship >/dev/null; then
  eval "$(starship init zsh)"
fi

# --- mise (runtime version manager: Node, etc.) ---
if command -v mise >/dev/null; then
  eval "$(mise activate zsh)"
fi

# --- fzf ---
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh

# --- atuin (shell history, syncable across machines) ---
if command -v atuin >/dev/null; then
  eval "$(atuin init zsh)"
fi

# --- zoxide (smarter cd: `z <dir>`) ---
if command -v zoxide >/dev/null; then
  eval "$(zoxide init zsh)"
fi

# --- History Options ---
export HISTSIZE=200000
export SAVEHIST=200000
export HISTIGNORE="ls:cd:pwd:exit"

setopt EXTENDED_HISTORY
setopt HIST_IGNORE_SPACE

# --- Performance tweaks for Git repos ---
DISABLE_UNTRACKED_FILES_DIRTY=true

DISABLE_AUTO_TITLE="true"

# --- Prompt: clean multi-line rendering ---
setopt PROMPT_SUBST
