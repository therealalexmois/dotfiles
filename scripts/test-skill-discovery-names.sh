#!/usr/bin/env bash
# Regression checks for skill names that Codex discovers recursively.
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
skills_dir="$repo_root/ai-agents/.agents/skills"
anthropic_skill="$skills_dir/anthropic-skill-creator/SKILL.md"
fixtures_dir="$skills_dir/skill-param-auditor/examples"

test ! -e "$skills_dir/skill-creator"
test -f "$anthropic_skill"
grep -q '^name: anthropic-skill-creator$' "$anthropic_skill"

if find "$fixtures_dir" -name SKILL.md -type f -print -quit | grep -q .; then
  printf 'fixtures must not be discoverable as SKILL.md\n' >&2
  exit 1
fi

for fixture_dir in "$fixtures_dir"/*/; do
  test -f "${fixture_dir}fixture.md"
done
