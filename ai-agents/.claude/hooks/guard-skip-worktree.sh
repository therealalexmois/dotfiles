#!/usr/bin/env bash
# PreToolUse hook (Edit|Write|MultiEdit). NON-BLOCKING reminder.
#
# The tracked skip-worktree defaults are held with `git update-index
# --skip-worktree` so Codex/Claude runtime rewrites do not churn them:
#   - ai-agents/.claude/settings.json
#   - ai-agents/.codex/*.config.toml   (the reasoning/mode profiles)
#
# Editing them is fine and expected. The catch is COMMITTING the change: it
# needs a `--no-skip-worktree` / re-apply dance (see AGENTS.md). This hook injects
# a one-line reminder via additionalContext and never blocks the edit.
#
# Contract: read JSON on stdin. Output JSON on stdout (additionalContext), exit 0.

set -uo pipefail

command -v jq >/dev/null 2>&1 || exit 0

INPUT=$(cat)
file=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')
[ -n "$file" ] || exit 0

# config.shared.toml and config.local.toml.example are NOT skip-worktree, so the
# *.config.toml glob below (which requires a `.config.toml` suffix) excludes them.
case "$file" in
  */.claude/settings.json | */.codex/*.config.toml)
    msg="Reminder: $file is a --skip-worktree tracked default. Edit freely, but to COMMIT this change you must first run \`git update-index --no-skip-worktree <file>\`, stage and commit, then re-apply \`git update-index --skip-worktree <file>\` (see AGENTS.md)."
    jq -n --arg c "$msg" \
      '{hookSpecificOutput: {hookEventName: "PreToolUse", additionalContext: $c}}'
    ;;
esac

exit 0
