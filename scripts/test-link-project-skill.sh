#!/usr/bin/env zsh
set -euo pipefail

# Exercise link-project-skill.sh against throwaway target repos.
real_repo="${0:A:h:h}"
linker="$real_repo/scripts/link-project-skill.sh"
skill="writing"
source_dir="$real_repo/ai-agents/.agents/skills/$skill"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

fail() {
  print -u2 -- "FAIL: $1"
  exit 1
}

expect_status() {
  local expected="$1"
  shift
  local actual=0
  "$@" >/dev/null 2>&1 || actual=$?
  (( actual == expected )) || fail "expected exit $expected, got $actual: $*"
}

# --agent claude links only Claude and exits 0.
plain="$work/plain"
mkdir -p "$plain"
expect_status 0 "$linker" "$skill" "$plain" --agent claude
[[ "$(readlink "$plain/.claude/skills/$skill")" == "$source_dir" ]] || fail "claude link missing"
[[ ! -e "$plain/.agents/skills/$skill" ]] || fail "--agent claude linked Codex too"

# Argument and name validation.
expect_status 2 "$linker" "$skill" "$plain" --agent
expect_status 2 "$linker" "$skill" "$plain" --agent cursor
expect_status 2 "$linker" "$skill"
expect_status 1 "$linker" "../$skill" "$plain"
expect_status 1 "$linker" no-such-skill "$plain"

# A Git target gets both links, each excluded locally exactly once.
repo="$work/repo"
mkdir -p "$repo"
git -C "$repo" init -q
expect_status 0 "$linker" "$skill" "$repo"
expect_status 0 "$linker" "$skill" "$repo"
exclude="$repo/.git/info/exclude"
for dir_name in .claude .agents; do
  [[ "$(readlink "$repo/$dir_name/skills/$skill")" == "$source_dir" ]] || fail "$dir_name link missing"
  (( $(grep -cxF "/$dir_name/skills/$skill" "$exclude") == 1 )) || fail "$dir_name exclude not added exactly once"
done
[[ -z "$(git -C "$repo" status --porcelain)" ]] || fail "links show up in git status"

# Existing paths are never overwritten or removed.
other="$work/other"
mkdir -p "$other/.claude/skills/$skill"
expect_status 1 "$linker" "$skill" "$other" --agent claude
expect_status 1 "$linker" --remove "$skill" "$other" --agent claude
[[ -d "$other/.claude/skills/$skill" && ! -L "$other/.claude/skills/$skill" ]] || fail "existing directory touched"
mkdir -p "$other/.agents/skills"
ln -s /elsewhere "$other/.agents/skills/$skill"
expect_status 1 "$linker" --remove "$skill" "$other" --agent codex
[[ "$(readlink "$other/.agents/skills/$skill")" == /elsewhere ]] || fail "foreign symlink removed"

# --remove drops the links and their exclude entries; a second run is a no-op.
expect_status 0 "$linker" --remove "$skill" "$repo"
expect_status 0 "$linker" --remove "$skill" "$repo"
for dir_name in .claude .agents; do
  [[ ! -e "$repo/$dir_name/skills/$skill" && ! -L "$repo/$dir_name/skills/$skill" ]] || fail "$dir_name link not removed"
  ! grep -qxF "/$dir_name/skills/$skill" "$exclude" || fail "$dir_name exclude not removed"
done

print 'ok: link-project-skill links, excludes, validates and removes project skill links'
