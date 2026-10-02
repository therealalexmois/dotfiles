#!/usr/bin/env bash
# Regression checks for installed skill links with a throwaway HOME.
set -euo pipefail

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT

test_home="$test_dir/home"
mkdir -p "$test_home/.agents/skills" "$test_home/.claude/skills/synced" "$test_home/.codex/skills"
ln -s "$repo_dir" "$test_home/.dotfiles"

skills=()
for skill_path in "$repo_dir"/ai-agents/.agents/skills/*/; do
  skill="$(basename "$skill_path")"
  [[ "$skill" == *-workspace ]] && continue
  skills+=("$skill")
  ln -s "../../.dotfiles/ai-agents/.agents/skills/$skill" "$test_home/.agents/skills/$skill"
  ln -s "../../.agents/skills/$skill" "$test_home/.claude/skills/$skill"
  ln -s "../../.agents/skills/$skill" "$test_home/.codex/skills/$skill"
done

output="$test_dir/check-output"
baseline_status=0
HOME="$test_home" bash "$repo_dir/scripts/check-skills.sh" --repo-only >"$test_dir/repo-output" 2>&1 || baseline_status=$?
installed_status=0
HOME="$test_home" bash "$repo_dir/scripts/check-skills.sh" >"$output" 2>&1 || installed_status=$?
installed_section="$(sed -n '/^== installed link layers ==/,/^== Codex system skill collisions ==/p' "$output")"
if [[ "$installed_status" -ne "$baseline_status" ]] ||
  printf '%s\n' "$installed_section" | grep -Fq 'FAIL:' ||
  printf '%s\n' "$installed_section" | grep -Fq 'WARN:' ||
  ! printf '%s\n' "$installed_section" | grep -Fq "checked $test_home/.claude/skills (${#skills[@]} links)" ||
  ! grep -Fqx '== Claude synced skill name collisions (SKILL.md only; diagnostic) ==' "$output" ||
  ! grep -Fqx 'found 0 same-name skill pair(s); only SKILL.md compared' "$output"; then
  printf 'FAIL: Claude synced container caused an installed-link check failure\n' >&2
  tail -n 12 "$output" >&2
  exit 1
fi

skill="${skills[0]}"
other_skill="${skills[1]}"
rmdir "$test_home/.claude/skills/synced"
absent_status=0
HOME="$test_home" bash "$repo_dir/scripts/check-skills.sh" >"$output" 2>&1 || absent_status=$?
if [[ "$absent_status" -ne "$baseline_status" ]] ||
  ! grep -Fqx 'found 0 same-name skill pair(s); only SKILL.md compared' "$output"; then
  printf 'FAIL: absent Claude synced container changed the check result\n' >&2
  tail -n 12 "$output" >&2
  exit 1
fi

synced_skill_dir="$test_home/.claude/skills/synced/account/$skill"
mkdir -p "$synced_skill_dir"
cp "$repo_dir/ai-agents/.agents/skills/$skill/SKILL.md" "$synced_skill_dir/SKILL.md"
identical_status=0
HOME="$test_home" bash "$repo_dir/scripts/check-skills.sh" >"$output" 2>&1 || identical_status=$?
if [[ "$identical_status" -ne "$baseline_status" ]] ||
  ! grep -Fqx "  $skill: SKILL.md identical" "$output" ||
  ! grep -Fqx 'found 1 same-name skill pair(s); only SKILL.md compared' "$output"; then
  printf 'FAIL: identical Claude synced skill was not reported\n' >&2
  tail -n 12 "$output" >&2
  exit 1
fi

cp "$repo_dir/ai-agents/.agents/skills/$other_skill/SKILL.md" "$synced_skill_dir/SKILL.md"
different_status=0
HOME="$test_home" bash "$repo_dir/scripts/check-skills.sh" >"$output" 2>&1 || different_status=$?
if [[ "$different_status" -ne "$baseline_status" ]] ||
  ! grep -Fqx "  $skill: SKILL.md different" "$output" ||
  ! grep -Fqx 'found 1 same-name skill pair(s); only SKILL.md compared' "$output"; then
  printf 'FAIL: different Claude synced skill was not reported\n' >&2
  tail -n 12 "$output" >&2
  exit 1
fi

# A valid but incorrectly targeted symlink must not count as the tracked skill.
rm "$test_home/.claude/skills/$skill"
ln -s "../../.agents/skills/$other_skill" "$test_home/.claude/skills/$skill"
if HOME="$test_home" bash "$repo_dir/scripts/check-skills.sh" >"$output" 2>&1; then
  printf 'FAIL: wrong managed target was accepted\n' >&2
  exit 1
fi
if ! grep -Fq "$test_home/.claude/skills/$skill points to ../../.agents/skills/$other_skill" "$output"; then
  printf 'FAIL: wrong managed target was not diagnosed\n' >&2
  tail -n 12 "$output" >&2
  exit 1
fi
if ! grep -Fqx 'found 0 same-name skill pair(s); only SKILL.md compared' "$output"; then
  printf 'FAIL: wrong managed target was reported as a repository-managed collision\n' >&2
  tail -n 12 "$output" >&2
  exit 1
fi

printf 'ok: Claude synced collisions are diagnostic and wrong managed skill links fail\n'
