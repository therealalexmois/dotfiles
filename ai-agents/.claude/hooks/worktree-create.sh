#!/usr/bin/env bash
# WorktreeCreate hook. Replaces the default `git worktree add` for `--worktree`,
# EnterWorktree, and subagent `isolation: worktree`.
#
# Goal: uniform worktrees everywhere.
#   - branch follows conventionalbranch.org, always with a type prefix
#     (explicit `type/...` kept, otherwise `feature/` is prepended)
#   - worktree lives in a flat `<repo>/.worktrees/<type>-<name>` dir (slashes in
#     the branch become hyphens, so no nested type folder)
#   - branched from origin/HEAD for a clean tree (falls back to local HEAD)
#   - gitignored files listed in `<repo>/.worktreeinclude` are copied in
#     (native .worktreeinclude is disabled once this hook is configured)
#   - provisioned best-effort: runs a setup script if present - personal
#     `<repo>/.worktree-setup.sh` (gitignored override) or the team-tracked
#     `<repo>/scripts/worktree-setup.sh` - else `uv venv && uv sync` for uv
#     projects; provisioning failure never aborts the worktree (the branch/tree
#     are already created)
#
# Contract: read JSON on stdin, print the absolute worktree path on stdout,
# exit 0 on success. Any non-zero exit aborts worktree creation.

set -uo pipefail

err() { printf 'worktree-create: %s\n' "$1" >&2; }

INPUT=$(cat)
command -v jq >/dev/null 2>&1 || { err "jq not found"; exit 1; }

# Audit the raw payload so the actual stdin schema can be confirmed.
debug_log="${XDG_STATE_HOME:-$HOME/.local/state}/claude/worktree-create.log"
mkdir -p "$(dirname "$debug_log")" 2>/dev/null || true
printf '%s\t%s\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')" "$INPUT" >>"$debug_log" 2>/dev/null || true

# Observed payload (Claude Code): { session_id, transcript_path, cwd,
# hook_event_name, name }. The worktree name arrives in .name; there is no
# base_ref field, so this hook chooses the base ref itself (see below).
worktree_name=$(printf '%s' "$INPUT" | jq -r '.name // empty')
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
default_type='feature'

clean=$(sanitize "$worktree_name")

# No meaningful name was passed (e.g. `claude -w` with no argument). The native
# git path would generate a name here, but this hook replaces it, so synthesize
# a unique timestamped one.
case "$clean" in
  "" | worktree | wt) clean="wt-$(date '+%Y%m%d-%H%M%S')" ;;
esac

# Branch always carries a conventionalbranch.org type prefix. An explicit type
# in the name is kept; otherwise the default type is prepended.
if printf '%s' "$clean" | grep -qE "^(${known_type})/"; then
  branch="$clean"
else
  branch="$default_type/$clean"
fi

# Flat worktree directory: no nested type folder. Slashes in the branch become
# hyphens for the path, so `feature/auth` lives in `.worktrees/feature-auth`.
dir_name=$(printf '%s' "$branch" | tr '/' '-')
path="$repo_root/.worktrees/$dir_name"

# Keep `.worktrees/` out of git status without touching the tracked .gitignore.
git_common=$(git -C "$repo_root" rev-parse --git-common-dir 2>/dev/null)
case "$git_common" in
  /*) ;;
  *) git_common="$repo_root/$git_common" ;;
esac
if ! git -C "$repo_root" check-ignore -q .worktrees 2>/dev/null; then
  printf '.worktrees/\n' >>"$git_common/info/exclude" 2>/dev/null || true
fi

# Base ref: there is no base_ref in the payload, so branch from origin/HEAD for
# a clean tree matching the remote (worktree.baseRef "fresh"). Fall back to the
# local HEAD when no remote default is resolvable.
base_ref=$(git -C "$repo_root" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)
[ -n "$base_ref" ] || base_ref=HEAD

# Create the worktree. Send git's own output to stderr so stdout carries only
# the path. Reuse the branch if it already exists, otherwise create it.
mkdir -p "$(dirname "$path")"
if git -C "$repo_root" show-ref --verify --quiet "refs/heads/$branch"; then
  git -C "$repo_root" worktree add "$path" "$branch" >&2
  rc=$?
else
  git -C "$repo_root" worktree add "$path" -b "$branch" "$base_ref" >&2
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
    # A venv hardcodes absolute paths and breaks when copied; it must be recreated
    # (uv venv / uv sync in the provisioning step below), never carried via .worktreeinclude.
    case "$line" in
      .venv | .venv/ | */.venv | */.venv/)
        err "skipping $line (recreate venv with uv, not copyable)"; continue ;;
    esac
    src="$repo_root/$line"
    [ -e "$src" ] || continue
    git -C "$repo_root" check-ignore -q "$line" 2>/dev/null || continue
    dest="$path/$line"
    mkdir -p "$(dirname "$dest")"
    cp -a "$src" "$dest" 2>/dev/null || err "could not copy $line"
  done <"$include"
fi

# Provision the new worktree (best-effort: never changes this hook's exit code, so a
# failed install leaves a valid worktree - the branch/tree are already created). Order:
# a repo setup script wins, otherwise a uv default for uv projects. Two setup-script
# candidates, first match wins: a personal `.worktree-setup.sh` at the repo root
# (gitignored override) or a team-tracked `scripts/worktree-setup.sh`. Read from
# repo_root (main checkout) so a gitignored, local-only override still applies - a
# fresh worktree carries only tracked files.
setup=""
for cand in "$repo_root/.worktree-setup.sh" "$repo_root/scripts/worktree-setup.sh"; do
  [ -x "$cand" ] && { setup="$cand"; break; }
done
if [ -n "$setup" ]; then
  ( cd "$path" && "$setup" ) >>"$debug_log" 2>&1 \
    || err "worktree setup script failed (see $debug_log); provision venv manually"
elif [ -f "$path/uv.lock" ] && command -v uv >/dev/null 2>&1; then
  ( cd "$path" && uv venv && uv sync ) >>"$debug_log" 2>&1 \
    || err "uv provisioning failed (see $debug_log); run 'uv venv && uv sync' manually"
fi

printf '%s\n' "$path"
exit 0
