#!/usr/bin/env bash
# Integration test for the shared agent worktree creator and Claude adapter.
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
wrapper="${repo_dir}/ai-agents/.agents/skills/git-worktree/scripts/agent-worktree-create"
claude_hook="${repo_dir}/ai-agents/.claude/hooks/worktree-create.sh"
expected_delegate="\$HOME/.local/bin/agent-worktree-create"
test_root="$(mktemp -d)"

cleanup() {
  rm -rf "$test_root"
}
trap cleanup EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_equal() {
  local expected="$1"
  local actual="$2"
  local label="$3"

  [[ "$actual" == "$expected" ]] || fail "$label: expected '$expected', got '$actual'"
}

assert_file() {
  local path="$1"
  [[ -f "$path" ]] || fail "missing file: $path"
}

origin="${test_root}/origin.git"
seed="${test_root}/seed"
checkout="${test_root}/checkout"

git init --quiet --bare "$origin"
git init --quiet --initial-branch=main "$seed"
git -C "$seed" config user.name "Worktree Test"
git -C "$seed" config user.email "worktree-test@example.invalid"

mkdir -p "${seed}/scripts"
printf '.env\n' >"${seed}/.gitignore"
printf 'initial\n' >"${seed}/tracked.txt"
printf '%s\n' '#!/usr/bin/env bash' 'printf setup-ran >.setup-ran' >"${seed}/scripts/worktree-setup.sh"
chmod +x "${seed}/scripts/worktree-setup.sh"
git -C "$seed" add .gitignore tracked.txt scripts/worktree-setup.sh
git -C "$seed" commit --quiet -m "initial"
git -C "$seed" remote add origin "$origin"
git -C "$seed" push --quiet --set-upstream origin main
git --git-dir="$origin" symbolic-ref HEAD refs/heads/main

git clone --quiet "$origin" "$checkout"
checkout="$(git -C "$checkout" rev-parse --show-toplevel)"
printf 'local-secret\n' >"${checkout}/.env"
printf '.env\n' >"${checkout}/.worktreeinclude"

printf 'fetched-base\n' >"${seed}/remote-only.txt"
git -C "$seed" add remote-only.txt
git -C "$seed" commit --quiet -m "remote update"
git -C "$seed" push --quiet
remote_head="$(git -C "$seed" rev-parse HEAD)"

[[ -x "$wrapper" ]] || fail "shared wrapper is not executable: $wrapper"

created_path="$(XDG_STATE_HOME="${test_root}/state" "$wrapper" --name 'DWSAI 1498 General Agent Run' --cwd "$checkout")"
expected_path="${checkout}/.worktrees/feat-dwsai-1498-general-agent-run"
assert_equal "$expected_path" "$created_path" "worktree path"
assert_equal "feat/dwsai-1498-general-agent-run" "$(git -C "$created_path" branch --show-current)" "branch"
assert_equal "$remote_head" "$(git -C "$created_path" rev-parse HEAD)" "fresh base"
assert_file "${created_path}/remote-only.txt"
assert_file "${created_path}/.env"
assert_file "${created_path}/.setup-ran"
grep -qx 'local-secret' "${created_path}/.env" || fail ".worktreeinclude content was not copied"
git -C "$checkout" check-ignore -q .worktrees || fail ".worktrees is not excluded from git status"

grep -Fq "$expected_delegate" "$claude_hook" \
  || fail "Claude hook does not delegate to the shared wrapper"
if grep -Eq 'git[^[:cntrl:]]+worktree add' "$claude_hook"; then
  fail "Claude hook still creates worktrees directly"
fi

printf 'agent worktree create integration test passed\n'
