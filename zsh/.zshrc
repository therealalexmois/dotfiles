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

# --- Cached tool init ---
# Каждый `eval "$(<tool> init)"` это отдельный exec, а на рабочем Mac каждый exec
# облагается налогом EDR (~0.1-0.4с, см. memory slow-exec-edr-startup). Вывод init
# стабилен и меняется только при обновлении бинарника, поэтому кэшируем его в файл и
# регенерируем лишь когда бинарник новее кэша. На тёплом старте остаётся `source`, без exec.
_eval_cached() {
  local name=$1 bin=$2; shift 2
  local bin_path cache="${ZSH_CACHE_DIR:-$ZSH/cache}/init-$name.zsh"
  bin_path=$(command -v "$bin") || return 0
  if [[ ! -s "$cache" || "$bin_path" -nt "$cache" ]]; then
    "$@" >| "$cache"
  fi
  source "$cache"
}

# --- Starship prompt ---
_eval_cached starship starship starship init zsh

# --- mise (runtime version manager: Node, etc.) ---
_eval_cached mise mise mise activate zsh

# --- fzf ---
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh

# --- atuin (shell history, syncable across machines) ---
_eval_cached atuin atuin atuin init zsh

# --- zoxide (smarter cd: `z <dir>`) ---
_eval_cached zoxide zoxide zoxide init zsh

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

# Корпоративный root CA для внутренних доменов работодателя.
# Экспортируем только если файл есть (на личной машине его нет – иначе Node ругается).
if [[ -r "$HOME/.claude/certs/corporate-root-ca.pem" ]]; then
  export NODE_EXTRA_CA_CERTS="$HOME/.claude/certs/corporate-root-ca.pem"
fi

# Puppeteer: использовать системный Chrome вместо встроенного headless-shell
export PUPPETEER_EXECUTABLE_PATH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# Mermaid CLI: директория для сохранения диаграмм
export MERMAID_OUTPUT_DIR="$HOME/Visuals/figures"

# --- Машинно-локальный конфиг ---
# Настройки и секреты, которые нужны только на конкретной машине (например рабочие) и не
# должны попадать в репозиторий. Лежит в XDG_DATA_HOME, а не в XDG_CONFIG_HOME: последний
# указывает внутрь ~/.dotfiles, то есть в git. На личной машине файла просто нет.
[[ -r "$XDG_DATA_HOME/zsh/local.zsh" ]] && source "$XDG_DATA_HOME/zsh/local.zsh"

# --- tmux: не тащить в сервер маркеры сессии Claude Code ---
# Claude Code выставляет каждому дочернему процессу CLAUDE_CODE_CHILD_SESSION и компанию.
# Если tmux server стартует из такого процесса, он забирает их в свой global environment и
# раздает всем будущим панелям, пока живет, а живет он неделями. Любой claude, запущенный в
# такой панели, считает себя вложенной сессией и молча перестает сохранять транскрипт.
# Чистим окружение на входе: заражение случается только при старте сервера, а лечится
# уже лишь его перезапуском.
tmux() {
  env -u CLAUDECODE -u CLAUDE_CODE_CHILD_SESSION -u CLAUDE_CODE_SESSION_ID \
      -u CLAUDE_PID -u AI_AGENT -u CLAUDE_EFFORT -u CLAUDE_CODE_ENTRYPOINT \
      -u CLAUDE_CODE_EXECPATH -u CLAUDE_CODE_MESSAGING_SOCKET \
      -u CLAUDE_CODE_MESSAGING_TOKEN command tmux "$@"
}
