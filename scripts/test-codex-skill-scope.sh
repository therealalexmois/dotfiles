#!/usr/bin/env zsh
set -euo pipefail

# Exercise the Codex-only link reduction without changing the real HOME.
real_repo="${0:A:h:h}"
test_home="$(mktemp -d)"
trap 'rm -rf "$test_home"' EXIT

mkdir -p "$test_home/.dotfiles/ai-agents/.agents/skills/kept"
mkdir -p "$test_home/.dotfiles/ai-agents/.agents/skills/dropped"
mkdir -p "$test_home/.dotfiles/scripts"
mkdir -p "$test_home/.agents/skills" "$test_home/.claude/skills" "$test_home/.codex/skills"
mkdir -p "$test_home/.codex/skills/.system"
touch "$test_home/.dotfiles/ai-agents/.agents/skills/kept/SKILL.md"
touch "$test_home/.dotfiles/ai-agents/.agents/skills/dropped/SKILL.md"
print kept > "$test_home/.dotfiles/scripts/codex-global-skills.txt"

ln -s ../../.dotfiles/ai-agents/.agents/skills/kept "$test_home/.agents/skills/kept"
ln -s ../../.dotfiles/ai-agents/.agents/skills/dropped "$test_home/.agents/skills/dropped"
ln -s ../../.agents/skills/dropped "$test_home/.claude/skills/dropped"
ln -s ../../.agents/skills/dropped "$test_home/.codex/skills/dropped"

export HOME="$test_home"
source "$real_repo/scripts/install-ai-cli-dotfiles.sh"

if (codex_global_skills=(); main --skills-only >/dev/null 2>&1); then
  print -u2 'FAIL: empty Codex selection must abort before pruning links'
  exit 1
fi
[[ -L "$HOME/.agents/skills/dropped" ]]
[[ -L "$HOME/.codex/skills/dropped" ]]

main --skills-only >/dev/null

[[ -f "$HOME/.claude/skills/dropped/SKILL.md" ]]
[[ "$(readlink "$HOME/.claude/skills/dropped")" == ../../.dotfiles/ai-agents/.agents/skills/dropped ]]
[[ -L "$HOME/.agents/skills/kept" ]]
[[ ! -L "$HOME/.agents/skills/dropped" ]]
[[ ! -L "$HOME/.codex/skills/dropped" ]]
[[ -L "$backup_dir/claude-skills/dropped" ]]

print 'ok: Codex keeps only selected links while Claude retains other skills'
