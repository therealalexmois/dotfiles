#!/usr/bin/env bash
# WorktreeRemove hook. Fires when Claude Code removes a worktree at session
# exit, when a subagent finishes, or when a background session is deleted.
# It cannot block removal and its exit code is ignored (surfaced only with
# --debug), so every failure here is logged instead of raised.
#
# Why it removes anything at all: WorktreeCreate is delegated to
# ~/.agents/skills/git-worktree/scripts/create-worktree, which places worktrees
# in <repo>/.worktrees/. Claude Code cleans up only the worktrees it creates
# itself under .claude/worktrees/, so a delegated worktree survives the session
# together with its task branch even though ExitWorktree reports removal. This
# hook closes that gap and stays idempotent when the directory is already gone.
#
# The event does not fire when the user keeps the worktree (verified against the
# audit log on 2026-08-17), so reaching this script means removal was intended.
#
# stdin JSON: { worktree_path, cwd, session_id, transcript_path, ... }
#
# Note: cwd is the removed worktree directory and may already be gone, so do not
# rely on filesystem access to it. Removal is deliberately non-destructive: no
# --force, so a worktree with uncommitted work is kept, and the task branch is
# force-deleted only when its patches are already in the base branch (the squash
# and rebase merge case). Every deleted branch is logged with its SHA, so
# `git branch <name> <sha>` restores it.

set -uo pipefail

err() { printf 'worktree-remove: %s\n' "$1" >&2; }

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/claude"

INPUT=$(cat)
command -v jq >/dev/null 2>&1 || { err 'jq not found; skipping cleanup'; exit 0; }

mkdir -p "$state_dir" 2>/dev/null || true

# Audit the raw payload so the actual stdin schema can be confirmed.
printf '%s\t%s\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')" "$INPUT" \
  >>"$state_dir/worktree-remove-raw.log" 2>/dev/null || true

worktree_path=$(printf '%s' "$INPUT" | jq -r '.worktree_path // empty')
session_id=$(printf '%s' "$INPUT" | jq -r '.session_id // empty')

worktree_status='unknown'
branch_status='none'

# shellcheck disable=SC2329  # invoked indirectly by the EXIT trap below.
log_summary() {
  printf '%s\tsession=%s\tpath=%s\tworktree=%s\tbranch=%s\n' \
    "$(date '+%Y-%m-%dT%H:%M:%S%z')" "$session_id" "$worktree_path" \
    "$worktree_status" "$branch_status" \
    >>"$state_dir/worktree-remove.log" 2>/dev/null || true
}
trap log_summary EXIT

[[ -n "$worktree_path" ]] || { worktree_status='no-path'; exit 0; }

# Claude Code removed it itself, or a previous run already cleaned up.
[[ -d "$worktree_path" ]] || { worktree_status='already-gone'; exit 0; }

git_common_dir=$(git -C "$worktree_path" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || {
  err "not a git worktree: $worktree_path"
  worktree_status='not-a-worktree'
  exit 0
}
repo_root=$(dirname "$git_common_dir")

# The main checkout shares the common git dir with its worktrees; never remove it.
if [[ "$(cd "$worktree_path" && pwd -P)" == "$(cd "$repo_root" && pwd -P)" ]]; then
  err "refusing to remove the main checkout: $worktree_path"
  worktree_status='refused-main-checkout'
  exit 0
fi

# Read the branch before removal: afterwards the worktree is gone.
branch=$(git -C "$worktree_path" symbolic-ref --quiet --short HEAD 2>/dev/null || true)
branch_sha=$(git -C "$worktree_path" rev-parse HEAD 2>/dev/null || true)

# No --force: a worktree holding uncommitted work is kept, and git says why.
if ! remove_error=$(git -C "$repo_root" worktree remove "$worktree_path" 2>&1); then
  err "git worktree remove failed: $remove_error"
  worktree_status='remove-failed'
  exit 0
fi

worktree_status='removed'
git -C "$repo_root" worktree prune >/dev/null 2>&1 || true

[[ -n "$branch" ]] || { branch_status='detached-head'; exit 0; }

if git -C "$repo_root" branch -d "$branch" >/dev/null 2>&1; then
  branch_status="deleted:$branch@$branch_sha"
  exit 0
fi

# `git branch -d` refuses after a squash or rebase merge: the branch tip is not
# an ancestor of the base branch even though its content landed there. Compare
# patches instead, and keep the branch whenever that cannot be proven.
base=$(git -C "$repo_root" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)
if [[ -z "$base" ]]; then
  for candidate in origin/main origin/master main master; do
    if git -C "$repo_root" rev-parse --verify --quiet "$candidate" >/dev/null 2>&1; then
      base=$candidate
      break
    fi
  done
fi

if [[ -z "$base" ]]; then
  branch_status="kept:$branch@$branch_sha (no base branch found)"
  exit 0
fi

merged=false
if ! git -C "$repo_root" cherry "$base" "$branch" 2>/dev/null | grep -q '^+'; then
  merged=true
elif git -C "$repo_root" diff --quiet "$base" "$branch" 2>/dev/null; then
  merged=true
fi

if [[ "$merged" != true ]]; then
  branch_status="kept:$branch@$branch_sha (not merged into $base)"
  exit 0
fi

if git -C "$repo_root" branch -D "$branch" >/dev/null 2>&1; then
  branch_status="force-deleted:$branch@$branch_sha (patches already in $base)"
else
  branch_status="kept:$branch@$branch_sha (delete failed)"
fi

exit 0
