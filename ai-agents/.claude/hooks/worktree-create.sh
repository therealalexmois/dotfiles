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
# stdin JSON: field names vary across Claude Code docs/versions. Observed/known
# candidates for the worktree name: .worktree_name, .name, .branch (the proposed
# default branch, e.g. "worktree-<name>"). For the base ref: .base_ref. The repo
# root may arrive as .base_path; otherwise derive it from .cwd. We read all
# candidates defensively so a schema change does not silently blank the name.

set -uo pipefail

err() { printf 'worktree-create: %s\n' "$1" >&2; }

INPUT=$(cat)
command -v jq >/dev/null 2>&1 || { err "jq not found"; exit 1; }

# Audit the raw payload so the actual stdin schema can be confirmed.
debug_log="${XDG_STATE_HOME:-$HOME/.local/state}/claude/worktree-create.log"
mkdir -p "$(dirname "$debug_log")" 2>/dev/null || true
printf '%s\t%s\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')" "$INPUT" >>"$debug_log" 2>/dev/null || true

# First non-empty of the known name fields. .branch may carry the default
# "worktree-<name>" convention, so a leading "worktree-" is stripped below.
worktree_name=$(printf '%s' "$INPUT" | jq -r '.worktree_name // .name // .branch // empty')
base_ref=$(printf '%s' "$INPUT" | jq -r '.base_ref // empty')
cwd=$(printf '%s' "$INPUT" | jq -r '.base_path // .cwd // empty')

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

# If the name came from the default-branch field it may be "worktree-<name>";
# strip that prefix so we don't get claude/worktree-<name>.
worktree_name="${worktree_name#worktree-}"
clean=$(sanitize "$worktree_name")

# No meaningful name was passed (e.g. `claude -w` with no argument, or a
# conversational "work in a worktree"). The native git path would generate a
# name here, but this hook replaces it, so synthesize a unique timestamped one.
case "$clean" in
  "" | worktree | wt) clean="wt-$(date '+%Y%m%d-%H%M%S')" ;;
esac

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
