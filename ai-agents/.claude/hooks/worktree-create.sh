#!/usr/bin/env bash
# Claude WorktreeCreate adapter. Claude supplies JSON on stdin; the shared
# agent-worktree-create command owns Git, naming, copying, and provisioning.

set -uo pipefail

err() { printf 'worktree-create: %s\n' "$1" >&2; }

input=$(cat)
command -v jq >/dev/null 2>&1 || { err "jq not found"; exit 1; }
printf '%s' "$input" | jq -e . >/dev/null 2>&1 || { err "invalid JSON hook input"; exit 1; }

# Keep the Claude-specific payload audit at the adapter boundary.
debug_log="${XDG_STATE_HOME:-$HOME/.local/state}/claude/worktree-create.log"
mkdir -p "$(dirname "$debug_log")" 2>/dev/null || true
printf '%s\t%s\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')" "$input" >>"$debug_log" 2>/dev/null || true

worktree_name=$(printf '%s' "$input" | jq -r '.name // empty')
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
[[ -n "$cwd" ]] || { err "no cwd in hook input"; exit 1; }

wrapper="$HOME/.agents/skills/git-worktree/scripts/agent-worktree-create"
[[ -x "$wrapper" ]] || { err "shared command is not executable: $wrapper"; exit 1; }

exec "$wrapper" --name "$worktree_name" --cwd "$cwd"
