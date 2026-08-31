#!/usr/bin/env bash
# Integration test for the shared worktree creator and Claude adapter.
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
wrapper="${repo_dir}/ai-agents/.agents/skills/git-worktree/scripts/create-worktree"
claude_hook="${repo_dir}/ai-agents/.claude/hooks/worktree-create.sh"
skill_file="${repo_dir}/ai-agents/.agents/skills/git-worktree/SKILL.md"
installer="${repo_dir}/scripts/install-ai-cli-dotfiles.sh"
expected_delegate="\$HOME/.agents/skills/git-worktree/scripts/create-worktree"
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

assert_absent() {
  local path="$1"
  [[ ! -e "$path" ]] || fail "unexpected path: $path"
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
checkout_remote_before="$(git -C "$checkout" rev-parse refs/remotes/origin/main)"
printf 'local-secret\n' >"${checkout}/.env"
printf '.env\n' >"${checkout}/.worktreeinclude"

printf 'fetched-base\n' >"${seed}/remote-only.txt"
git -C "$seed" add remote-only.txt
git -C "$seed" commit --quiet -m "remote update"
git -C "$seed" push --quiet
remote_head="$(git -C "$seed" rev-parse HEAD)"

[[ -x "$wrapper" ]] || fail "shared wrapper is not executable: $wrapper"

if XDG_STATE_HOME="${test_root}/state" \
  "$wrapper" --name 'DWSAI 1498 General Agent Run' --cwd "$checkout" \
  >"${test_root}/preflight.stdout" 2>"${test_root}/preflight.stderr"; then
  fail "unconfirmed default location was accepted"
fi
assert_absent "${checkout}/.worktrees"
assert_equal \
  "$checkout_remote_before" \
  "$(git -C "$checkout" rev-parse refs/remotes/origin/main)" \
  "remote ref before preflight confirmation"
if git -C "$checkout" show-ref --verify --quiet refs/heads/feat/dwsai-1498-general-agent-run; then
  fail "preflight created the task branch"
fi
grep -Fq '.worktrees is not ignored' "${test_root}/preflight.stderr" \
  || fail "preflight blocker was not reported"

created_path="$(
  XDG_STATE_HOME="${test_root}/state" \
    "$wrapper" \
    --name 'DWSAI 1498 General Agent Run' \
    --cwd "$checkout" \
    --ignore-mode info-exclude
)"
expected_path="${checkout}/.worktrees/feat-dwsai-1498-general-agent-run"
assert_equal "$expected_path" "$created_path" "worktree path"
assert_equal "feat/dwsai-1498-general-agent-run" "$(git -C "$created_path" branch --show-current)" "branch"
assert_equal "$remote_head" "$(git -C "$created_path" rev-parse HEAD)" "fresh base"
assert_file "${created_path}/remote-only.txt"
assert_file "${created_path}/.env"
assert_file "${created_path}/.setup-ran"
grep -qx 'local-secret' "${created_path}/.env" || fail ".worktreeinclude content was not copied"
git_common="$(git -C "$checkout" rev-parse --git-common-dir)"
case "$git_common" in
  /*) ;;
  *) git_common="$checkout/$git_common" ;;
esac
git -C "$checkout" check-ignore -q --no-index .worktrees/.git-worktree-preflight \
  || fail ".worktrees is not excluded from git status"
assert_equal \
  "1" \
  "$(grep -Fxc '/.worktrees/' "$git_common/info/exclude")" \
  "info/exclude rule count"

second_path="$(
  XDG_STATE_HOME="${test_root}/state" \
    "$wrapper" --name 'Second Task' --cwd "$checkout"
)"
assert_equal "${checkout}/.worktrees/feat-second-task" "$second_path" "existing ignore path"
assert_equal \
  "1" \
  "$(grep -Fxc '/.worktrees/' "$git_common/info/exclude")" \
  "deduplicated info/exclude rule count"

gitignore_checkout="${test_root}/gitignore-checkout"
git clone --quiet "$origin" "$gitignore_checkout"
gitignore_checkout="$(git -C "$gitignore_checkout" rev-parse --show-toplevel)"
gitignore_path="$(
  XDG_STATE_HOME="${test_root}/state" \
    "$wrapper" --name 'Tracked Ignore' --cwd "$gitignore_checkout" --ignore-mode gitignore
)"
assert_equal \
  "${gitignore_checkout}/.worktrees/feat-tracked-ignore" \
  "$gitignore_path" \
  "gitignore worktree path"
assert_equal \
  "1" \
  "$(grep -Fxc '/.worktrees/' "${gitignore_checkout}/.gitignore")" \
  "gitignore rule count"
gitignore_common="$(git -C "$gitignore_checkout" rev-parse --git-common-dir)"
case "$gitignore_common" in
  /*) ;;
  *) gitignore_common="$gitignore_checkout/$gitignore_common" ;;
esac
if grep -Fqx '/.worktrees/' "$gitignore_common/info/exclude"; then
  fail "gitignore choice also changed info/exclude"
fi

explicit_checkout="${test_root}/explicit-checkout"
explicit_root="${test_root}/explicit-root"
explicit_path="${explicit_root}/custom-worktree"
git clone --quiet "$origin" "$explicit_checkout"
explicit_checkout="$(git -C "$explicit_checkout" rev-parse --show-toplevel)"
mkdir -p "$explicit_root"
actual_explicit_path="$(
  XDG_STATE_HOME="${test_root}/state" \
    "$wrapper" --name 'Explicit Path' --cwd "$explicit_checkout" --path "$explicit_path"
)"
assert_equal "$explicit_path" "$actual_explicit_path" "explicit worktree path"
assert_equal "feat/explicit-path" "$(git -C "$explicit_path" branch --show-current)" "explicit path branch"
assert_absent "${explicit_checkout}/.worktrees"
explicit_common="$(git -C "$explicit_checkout" rev-parse --git-common-dir)"
case "$explicit_common" in
  /*) ;;
  *) explicit_common="$explicit_checkout/$explicit_common" ;;
esac
if grep -Fqx '/.worktrees/' "$explicit_common/info/exclude"; then
  fail "explicit path changed info/exclude"
fi
if grep -Fqx '/.worktrees/' "${explicit_checkout}/.gitignore"; then
  fail "explicit path changed .gitignore"
fi

grep -Fq "$expected_delegate" "$claude_hook" \
  || fail "Claude hook does not delegate to the shared wrapper"
grep -Fq '[scripts/create-worktree](scripts/create-worktree)' "$skill_file" \
  || fail "SKILL.md does not link the bundled worktree script"
grep -Fq -- '--ignore-mode info-exclude' "$skill_file" \
  || fail "SKILL.md does not document the default ignore confirmation"
grep -Fq -- '--path' "$skill_file" \
  || fail "SKILL.md does not document explicit paths"
if grep -Fq 'create-worktree' "$installer"; then
  fail "installer still manages a separate worktree command link"
fi
if grep -Eq 'git[^[:cntrl:]]+worktree add' "$claude_hook"; then
  fail "Claude hook still creates worktrees directly"
fi

printf 'create-worktree integration test passed\n'
