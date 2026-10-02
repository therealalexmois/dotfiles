#!/usr/bin/env bash
# Integration test for the WorktreeRemove hook after a squash merge.
#
# The task branch has two commits, the squash commit lands on main and main moves
# on. `git cherry` and a tree comparison cannot prove such a merge, so the branch
# may be deleted only when the merged PR reports the same head SHA. `gh` is
# replaced by a stub that answers with FAKE_PR_HEAD.
#
# Usage: scripts/test-worktree-remove.sh [path-to-hook]
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
wrapper="${repo_dir}/ai-agents/.agents/skills/git-worktree/scripts/create-worktree"
hook="${1:-${repo_dir}/ai-agents/.claude/hooks/worktree-remove.sh}"
test_root="$(mktemp -d)"

cleanup() {
  rm -rf "$test_root"
}
trap cleanup EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

# Builds a repository whose task branch is squash-merged into a main that moved on.
# Prints the worktree path; the branch name is fixed.
prepare_squash_merged_worktree() {
  local case_dir="$1"
  local origin="${case_dir}/origin.git"
  local checkout="${case_dir}/checkout"

  git init --quiet --bare "$origin"
  git init --quiet --initial-branch=main "$checkout"
  git -C "$checkout" config user.name "Worktree Test"
  git -C "$checkout" config user.email "worktree-test@example.invalid"
  printf '.worktrees/\n' >"${checkout}/.gitignore"
  printf 'initial\n' >"${checkout}/tracked.txt"
  git -C "$checkout" add .gitignore tracked.txt
  git -C "$checkout" commit --quiet -m "initial"
  git -C "$checkout" remote add origin "$origin"
  git -C "$checkout" push --quiet --set-upstream origin main
  git --git-dir="$origin" symbolic-ref HEAD refs/heads/main

  local worktree
  worktree=$("$wrapper" --name fix/squashed --cwd "$checkout" --format json | jq -r '.worktree')
  git -C "$worktree" config user.name "Worktree Test"
  git -C "$worktree" config user.email "worktree-test@example.invalid"
  printf 'first\n' >"${worktree}/first.txt"
  git -C "$worktree" add first.txt
  git -C "$worktree" commit --quiet -m "first"
  printf 'second\n' >"${worktree}/second.txt"
  git -C "$worktree" add second.txt
  git -C "$worktree" commit --quiet -m "second"

  # Squash merge on the host, then an unrelated commit moves main on.
  git -C "$checkout" merge --quiet --squash fix/squashed >/dev/null
  git -C "$checkout" commit --quiet -m "fix: squashed (#1)"
  printf 'later\n' >"${checkout}/later.txt"
  git -C "$checkout" add later.txt
  git -C "$checkout" commit --quiet -m "later"
  git -C "$checkout" push --quiet origin main
  git -C "$checkout" fetch --quiet --prune origin

  printf '%s\n' "$worktree"
}

# Runs the hook with a `gh` stub that reports the given merged PR head.
run_hook() {
  local case_dir="$1"
  local worktree="$2"
  local pr_head="$3"
  local stubs="${case_dir}/bin"

  mkdir -p "$stubs"
  # shellcheck disable=SC2016  # the stub expands FAKE_PR_HEAD at run time, not here.
  printf '%s\n' '#!/usr/bin/env bash' 'printf "%s\n" "${FAKE_PR_HEAD:-}"' >"${stubs}/gh"
  chmod +x "${stubs}/gh"

  jq -n --arg path "$worktree" '{worktree_path: $path, cwd: $path, session_id: "test"}' |
    PATH="${stubs}:${PATH}" FAKE_PR_HEAD="$pr_head" XDG_STATE_HOME="${case_dir}/state" bash "$hook" >/dev/null 2>&1
}

branch_exists() {
  git -C "$1" rev-parse --verify --quiet refs/heads/fix/squashed >/dev/null
}

# Case 1: the merged PR head equals the branch tip, so the branch goes.
case_dir="${test_root}/matching-pr"
mkdir -p "$case_dir"
worktree=$(prepare_squash_merged_worktree "$case_dir")
tip=$(git -C "$worktree" rev-parse HEAD)
run_hook "$case_dir" "$worktree" "$tip"
[[ ! -d "$worktree" ]] || fail "matching PR: worktree was not removed"
if branch_exists "${case_dir}/checkout"; then
  fail "matching PR: squash-merged branch was kept although the merged PR head equals its tip"
fi
grep -q "force-deleted:fix/squashed@${tip}" "${case_dir}/state/claude/worktree-remove.log" ||
  fail "matching PR: the log does not record the deleted SHA"

# Case 2: the merged PR head differs, so a local-only commit may exist and the branch stays.
case_dir="${test_root}/other-pr-head"
mkdir -p "$case_dir"
worktree=$(prepare_squash_merged_worktree "$case_dir")
run_hook "$case_dir" "$worktree" "0000000000000000000000000000000000000000"
branch_exists "${case_dir}/checkout" || fail "other PR head: branch was deleted without proof"

# Case 3: no merged PR at all, so the branch stays.
case_dir="${test_root}/no-pr"
mkdir -p "$case_dir"
worktree=$(prepare_squash_merged_worktree "$case_dir")
run_hook "$case_dir" "$worktree" ""
branch_exists "${case_dir}/checkout" || fail "no PR: branch was deleted without proof"

printf 'OK: worktree-remove squash merge cases passed\n'
