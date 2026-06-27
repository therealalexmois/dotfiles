#!/usr/bin/env bash
# WorktreeRemove hook. Post-event only: fires after a worktree is removed at
# session exit or when a subagent finishes. It cannot block removal; exit codes
# are ignored (surfaced only with --debug). Used here for an audit log.
#
# stdin JSON: { worktree_path, cwd, session_id, ... }
#
# Note: cwd is the removed worktree directory and may already be gone, so do not
# rely on filesystem access to it.

set -uo pipefail

INPUT=$(cat)
command -v jq >/dev/null 2>&1 || exit 0

# Audit the raw payload so the actual stdin schema can be confirmed.
debug_log="${XDG_STATE_HOME:-$HOME/.local/state}/claude/worktree-remove-raw.log"
mkdir -p "$(dirname "$debug_log")" 2>/dev/null || true
printf '%s\t%s\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')" "$INPUT" >>"$debug_log" 2>/dev/null || true

worktree_path=$(printf '%s' "$INPUT" | jq -r '.worktree_path // empty')
session_id=$(printf '%s' "$INPUT" | jq -r '.session_id // empty')

log_file="${XDG_STATE_HOME:-$HOME/.local/state}/claude/worktree-remove.log"
mkdir -p "$(dirname "$log_file")" 2>/dev/null || true
printf '%s\tsession=%s\tpath=%s\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')" "$session_id" "$worktree_path" \
  >>"$log_file" 2>/dev/null || true

exit 0
