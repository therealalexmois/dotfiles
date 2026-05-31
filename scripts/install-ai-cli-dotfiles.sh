#!/usr/bin/env zsh
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

repo_dir="${HOME}/.dotfiles"
backup_dir="${HOME}/.dotfiles-backups/ai-cli-dotfiles/$(date +%Y%m%d-%H%M%S)"

skills=(
  cli-creator
  codebase-onboarding
  define-goal
  defuddle
  engineering-review
  find-skills
  obsidian-bases
  obsidian-cli
  obsidian-markdown
  prd
  python-docstring-editor
  russian-technical-editor
  skill-creator
  to-jira-issues
  to-prd
)

backup_item() {
  local item_path="$1"
  local label="$2"
  if [[ ! -e "$item_path" && ! -L "$item_path" ]]; then
    return 0
  fi
  local dest="${backup_dir}/${label}"
  mkdir -p "$(dirname "$dest")"
  cp -pR "$item_path" "$dest"
}

move_conflict() {
  local item_path="$1"
  local label="$2"
  if [[ ! -e "$item_path" && ! -L "$item_path" ]]; then
    return 0
  fi
  if [[ -L "$item_path" ]]; then
    echo "unexpected symlink conflict: $item_path -> $(readlink "$item_path")" >&2
    exit 1
  fi
  local dest="${backup_dir}/${label}"
  mkdir -p "$(dirname "$dest")"
  if [[ -e "$dest" || -L "$dest" ]]; then
    echo "backup destination already exists: $dest" >&2
    exit 1
  fi
  mv "$item_path" "$dest"
  echo "moved conflict: $item_path -> $dest"
}

prepare_stow_path() {
  local item_path="$1"
  local expected_target="$2"
  local label="$3"
  if [[ ! -e "$item_path" && ! -L "$item_path" ]]; then
    return 0
  fi
  if [[ -L "$item_path" ]]; then
    local current
    current="$(readlink "$item_path")"
    if [[ "$current" == "$expected_target" ]]; then
      echo "stow link ok: $item_path -> $current"
      return 0
    fi
    echo "wrong symlink conflict: $item_path -> $current; expected $expected_target" >&2
    exit 1
  fi
  move_conflict "$item_path" "$label"
}

ensure_correct_skill_link() {
  local agent_dir="$1"
  local skill="$2"
  local target="../../.agents/skills/${skill}"
  local link_path="${agent_dir}/skills/${skill}"

  mkdir -p "${agent_dir}/skills"
  if [[ -L "$link_path" ]]; then
    local current
    current="$(readlink "$link_path")"
    if [[ "$current" == "$target" ]]; then
      echo "skill link ok: $link_path -> $current"
      return 0
    fi
    echo "unexpected skill symlink: $link_path -> $current" >&2
    exit 1
  fi
  if [[ -e "$link_path" ]]; then
    move_conflict "$link_path" "${agent_dir:t}-skills/${skill}"
  fi
  ln -s "$target" "$link_path"
  echo "created skill link: $link_path -> $target"
}

validate_sources() {
  for skill in "${skills[@]}"; do
    if [[ ! -d "${repo_dir}/ai-agents/.agents/skills/${skill}" ]]; then
      echo "missing tracked skill source: ${skill}" >&2
      exit 1
    fi
  done
  if [[ ! -d "${HOME}/.codex/skills/.system" ]]; then
    echo "missing Codex system skills directory" >&2
    exit 1
  fi
}

main() {
  cd "$repo_dir"
  mkdir -p "$backup_dir"
  echo "backup directory: $backup_dir"

  validate_sources

  backup_item "${HOME}/.codex/config.toml" "codex/config.toml"
  backup_item "${HOME}/.codex/AGENTS.md" "codex/AGENTS.md"
  backup_item "${HOME}/.claude/settings.json" "claude/settings.json"
  backup_item "${HOME}/.claude/CLAUDE.md" "claude/CLAUDE.md"
  backup_item "${HOME}/.claude/statusline-command.sh" "claude/statusline-command.sh"

  for skill in "${skills[@]}"; do
    backup_item "${HOME}/.agents/skills/${skill}" "agents/skills/${skill}"
    backup_item "${HOME}/.codex/skills/${skill}" "codex-skills/${skill}"
    backup_item "${HOME}/.claude/skills/${skill}" "claude-skills/${skill}"
  done

  "${repo_dir}/scripts/render-codex-config.py" --init-local-only

  prepare_stow_path "${HOME}/.codex/AGENTS.md" "../.dotfiles/ai-agents/.codex/AGENTS.md" "stow-conflicts/codex/AGENTS.md"
  prepare_stow_path "${HOME}/.claude/CLAUDE.md" "../.dotfiles/ai-agents/.claude/CLAUDE.md" "stow-conflicts/claude/CLAUDE.md"
  prepare_stow_path "${HOME}/.claude/settings.json" "../.dotfiles/ai-agents/.claude/settings.json" "stow-conflicts/claude/settings.json"
  prepare_stow_path "${HOME}/.claude/statusline-command.sh" "../.dotfiles/ai-agents/.claude/statusline-command.sh" "stow-conflicts/claude/statusline-command.sh"
  for skill in "${skills[@]}"; do
    prepare_stow_path "${HOME}/.agents/skills/${skill}" "../../.dotfiles/ai-agents/.agents/skills/${skill}" "stow-conflicts/agents/skills/${skill}"
  done

  stow -n -v --target "$HOME" bootstrap ai-agents
  stow --target "$HOME" bootstrap ai-agents

  "${repo_dir}/scripts/render-codex-config.py"

  for skill in "${skills[@]}"; do
    ensure_correct_skill_link "${HOME}/.codex" "$skill"
    ensure_correct_skill_link "${HOME}/.claude" "$skill"
  done

  if [[ -d "${HOME}/.agents/skills/skill-creator" && -d "${HOME}/.codex/skills/.system/skill-creator" ]]; then
    echo "warning: global skill-creator duplicates Codex .system/skill-creator; neither was modified"
  fi

  echo "validation summary:"
  python3 -c 'import tomllib, pathlib; tomllib.load(open(pathlib.Path.home()/".codex/config.toml","rb")); print("codex toml ok")'
  test -L "${HOME}/.codex/AGENTS.md" && readlink "${HOME}/.codex/AGENTS.md"
  test -L "${HOME}/.claude/CLAUDE.md" && readlink "${HOME}/.claude/CLAUDE.md"
  test -L "${HOME}/.claude/settings.json" && readlink "${HOME}/.claude/settings.json"
  test -L "${HOME}/.claude/statusline-command.sh" && readlink "${HOME}/.claude/statusline-command.sh"
  test -d "${HOME}/.codex/skills/.system"
  find "${HOME}/.agents/skills" -maxdepth 1 -mindepth 1 -type l -print | sort
  find "${HOME}/.codex/skills" -maxdepth 1 -type l -print | sort
  find "${HOME}/.claude/skills" -maxdepth 1 -type l -print | sort
}

main "$@"
