#!/usr/bin/env bash
# WorktreeCreate hook. Replaces the default `git worktree add` for `--worktree`,
# EnterWorktree, and subagent `isolation: worktree`.
#
# Goal: uniform worktrees everywhere.
#   - branch follows conventionalbranch.org (default prefix `claude/`)
#   - worktree lives in `<repo>/.worktrees/<branch>` (matches the
#     using-git-worktrees skill, Mode A)
#   - gitignored files listed in `<repo>/.worktreeinclude` are copied in
#     (native .worktreeinclude is disabled once this hook is configured)
#
# Contract: read JSON on stdin, print the absolute worktree path on stdout,
# exit 0 on success. Any non-zero exit aborts worktree creation.
#
# stdin JSON: { worktree_name, base_ref, cwd, session_id, ... }

set -uo pipefail

err() { printf 'worktree-create: %s\n' "$1" >&2; }

INPUT=$(cat)
command -v jq >/dev/null 2>&1 || { err "jq not found"; exit 1; }

worktree_name=$(printf '%s' "$INPUT" | jq -r '.worktree_name // empty')
base_ref=$(printf '%s' "$INPUT" | jq -r '.base_ref // empty')
cwd=$(printf '%s' "$INPUT" | jq -r '.cwd // empty')

[ -n "$cwd" ] || { err "no cwd in hook input"; exit 1; }
repo_root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null) || {
  err "not a git repository: $cwd"
  exit 1
}

# conventionalbranch.org: lowercase a-z0-9, hyphens between words, dots only in
# release versions. Keep `/` so an existing `type/...` prefix survives.
sanitize() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's#[^a-z0-9._/-]+#-#g; s#-{2,}#-#g; s#\.{2,}#.#g; s#^[-._/]+##; s#[-._/]+$##'
}

known_type='feature|feat|bugfix|fix|hotfix|release|chore|ai|copilot|cursor|claude|codex'
clean=$(sanitize "$worktree_name")
[ -n "$clean" ] || clean="worktree"

if printf '%s' "$clean" | grep -qE "^(${known_type})/"; then
  branch="$clean"
else
  branch="claude/$clean"
fi

path="$repo_root/.worktrees/$branch"

# Keep `.worktrees/` out of git status without touching the tracked .gitignore.
git_common=$(git -C "$repo_root" rev-parse --git-common-dir 2>/dev/null)
case "$git_common" in
  /*) ;;
  *) git_common="$repo_root/$git_common" ;;
esac
if ! git -C "$repo_root" check-ignore -q .worktrees 2>/dev/null; then
  printf '.worktrees/\n' >>"$git_common/info/exclude" 2>/dev/null || true
fi

# Create the worktree. Send git's own output to stderr so stdout carries only
# the path. Reuse the branch if it already exists, otherwise create it.
mkdir -p "$(dirname "$path")"
if git -C "$repo_root" show-ref --verify --quiet "refs/heads/$branch"; then
  git -C "$repo_root" worktree add "$path" "$branch" >&2
  rc=$?
elif [ -n "$base_ref" ]; then
  git -C "$repo_root" worktree add "$path" -b "$branch" "$base_ref" >&2
  rc=$?
else
  git -C "$repo_root" worktree add "$path" -b "$branch" >&2
  rc=$?
fi
[ "$rc" -eq 0 ] || { err "git worktree add failed (rc=$rc)"; exit 1; }

# Copy gitignored files listed in .worktreeinclude (best-effort; never aborts a
# created worktree). Each line is a path; copied only if it exists and is
# gitignored, so tracked files are never duplicated.
include="$repo_root/.worktreeinclude"
if [ -f "$include" ]; then
  while IFS= read -r raw || [ -n "$raw" ]; do
    line="${raw#"${raw%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [ -z "$line" ] && continue
    case "$line" in \#*) continue ;; esac
    src="$repo_root/$line"
    [ -e "$src" ] || continue
    git -C "$repo_root" check-ignore -q "$line" 2>/dev/null || continue
    dest="$path/$line"
    mkdir -p "$(dirname "$dest")"
    cp -a "$src" "$dest" 2>/dev/null || err "could not copy $line"
  done <"$include"
fi

printf '%s\n' "$path"
exit 0
