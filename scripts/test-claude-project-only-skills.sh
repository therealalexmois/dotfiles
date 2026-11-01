#!/usr/bin/env zsh
set -euo pipefail

# Exercise the Claude project-only skill scoping without changing the real HOME.
real_repo="${0:A:h:h}"
test_home="$(mktemp -d)"
trap 'rm -rf "$test_home"' EXIT

mkdir -p "$test_home/.dotfiles/ai-agents/.agents/skills/global"
mkdir -p "$test_home/.dotfiles/ai-agents/.agents/skills/projectonly"
mkdir -p "$test_home/.dotfiles/ai-agents/.agents/skills/external"
mkdir -p "$test_home/.dotfiles/scripts"
mkdir -p "$test_home/.agents/skills" "$test_home/.claude/skills" "$test_home/.codex/skills"
mkdir -p "$test_home/.codex/skills/.system"
touch "$test_home/.dotfiles/ai-agents/.agents/skills/global/SKILL.md"
touch "$test_home/.dotfiles/ai-agents/.agents/skills/projectonly/SKILL.md"
touch "$test_home/.dotfiles/ai-agents/.agents/skills/external/SKILL.md"
print global > "$test_home/.dotfiles/scripts/codex-global-skills.txt"
print projectonly > "$test_home/.dotfiles/scripts/claude-project-only-skills.txt"
print external > "$test_home/.dotfiles/scripts/claude-external-project-skills.txt"

# Migration: skills that used to be global keep stale ~/.claude/skills links.
ln -s ../../.dotfiles/ai-agents/.agents/skills/projectonly "$test_home/.claude/skills/projectonly"
ln -s ../../.dotfiles/ai-agents/.agents/skills/external "$test_home/.claude/skills/external"

export HOME="$test_home"
source "$real_repo/scripts/install-ai-cli-dotfiles.sh"
main --skills-only >/dev/null

[[ -L "$HOME/.claude/skills/global" ]]
[[ "$(readlink "$HOME/.claude/skills/global")" == ../../.dotfiles/ai-agents/.agents/skills/global ]]
[[ ! -e "$HOME/.claude/skills/projectonly" && ! -L "$HOME/.claude/skills/projectonly" ]]
[[ -L "$HOME/.dotfiles/.claude/skills/projectonly" ]]
[[ "$(readlink "$HOME/.dotfiles/.claude/skills/projectonly")" == ../../ai-agents/.agents/skills/projectonly ]]
[[ -f "$HOME/.dotfiles/.claude/skills/projectonly/SKILL.md" ]]
[[ ! -e "$HOME/.dotfiles/.claude/skills/global" && ! -L "$HOME/.dotfiles/.claude/skills/global" ]]

# External-project skills are linked by neither layer; link-project-skill.sh owns them.
[[ ! -e "$HOME/.claude/skills/external" && ! -L "$HOME/.claude/skills/external" ]]
[[ ! -e "$HOME/.dotfiles/.claude/skills/external" && ! -L "$HOME/.dotfiles/.claude/skills/external" ]]

# Idempotent: a second run creates, updates and removes nothing.
second_run="$(main --skills-only)"
if print -r -- "$second_run" | grep -Eq '^(created|updated|removed) '; then
  print -u2 -- "second run changed links:"
  print -u2 -- "$second_run"
  exit 1
fi

# Invalid or missing names fail validation before any link is touched.
for bad_skill in Bad_Name absent; do
  if validation_error="$( (claude_project_only_skills=("$bad_skill"); validate_sources) 2>&1 )"; then
    print -u2 -- "validate_sources accepted project-only skill: $bad_skill"
    exit 1
  fi
  if [[ "$validation_error" != *"Claude project-only skill"*"$bad_skill"* ]]; then
    print -u2 -- "unexpected validation error for $bad_skill: $validation_error"
    exit 1
  fi
done
for bad_skill in Bad_Name absent projectonly; do
  if validation_error="$( (claude_external_skills=("$bad_skill"); validate_sources) 2>&1 )"; then
    print -u2 -- "validate_sources accepted external-project skill: $bad_skill"
    exit 1
  fi
  if [[ "$validation_error" != *"Claude external-project skill"*"$bad_skill"* ]]; then
    print -u2 -- "unexpected validation error for $bad_skill: $validation_error"
    exit 1
  fi
done

print 'ok: project-only Claude skills move from ~/.claude/skills into the dotfiles-local .claude/skills; external-project skills leave both'
