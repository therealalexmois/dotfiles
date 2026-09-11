#!/usr/bin/env bash
# Validates the agent-skill layer against the invariants documented in AGENTS.md
# ("Agent Skills: Naming and Layout").
#
# Repository invariants (always checked):
#   - every skill directory carries a SKILL.md;
#   - the directory name equals the `name:` field in that SKILL.md;
#   - no nested SKILL.md that Codex's recursive discovery would pick up as an
#     extra skill (test fixtures must not look like skills).
#
# Installed invariants (checked when the agent CLIs are installed on this host):
#   - no dangling skill symlinks under ~/.agents, ~/.claude, ~/.codex;
#   - no skill name collides with a Codex system skill;
#   - the three link layers cover exactly the tracked skills (warning only,
#     since a freshly added skill is linked by the next install run).
#
# Usage:
#   scripts/check-skills.sh              # repository + installed checks
#   scripts/check-skills.sh --repo-only  # repository checks only
#
# Exit codes: 0 = all invariants hold, 1 = at least one failed.
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
skills_dir="$repo_root/ai-agents/.agents/skills"

mode="${1:-all}"
case "$mode" in
  all | --repo-only) ;;
  *)
    printf 'usage: %s [--repo-only]\n' "$0" >&2
    exit 2
    ;;
esac

status=0
fail() {
  printf 'FAIL: %s\n' "$1" >&2
  status=1
}
warn() { printf 'WARN: %s\n' "$1" >&2; }

# Nested SKILL.md files that are fixtures on purpose: skill-tester validates a
# skill directory, so its fixture has to be a real skill with a real SKILL.md.
# Paths are relative to $skills_dir.
nested_skill_md_allowlist=(
  "skill-tester/assets/sample-skill/SKILL.md"
)

# Reads the `name:` value from a SKILL.md YAML frontmatter block; prints nothing
# when the file has no frontmatter or no name key.
frontmatter_name() {
  awk '
    NR == 1 && $0 !~ /^---[[:space:]]*$/ { exit }
    NR > 1 && /^---[[:space:]]*$/ { exit }
    NR > 1 && /^name:[[:space:]]*/ {
      sub(/^name:[[:space:]]*/, "")
      gsub(/^["'"'"']|["'"'"']$/, "")
      sub(/[[:space:]]+$/, "")
      print
      exit
    }
  ' "$1"
}

tracked_skills=()
for skill_path in "$skills_dir"/*/; do
  skill="$(basename "$skill_path")"
  case "$skill" in
    *-workspace) continue ;;
  esac
  tracked_skills+=("$skill")
done

printf '== skill sources: SKILL.md and name ==\n'
for skill in "${tracked_skills[@]}"; do
  skill_md="$skills_dir/$skill/SKILL.md"
  if [[ ! -f "$skill_md" ]]; then
    fail "$skill: no SKILL.md (add one, or delete the directory: the install script skips it and every consumer treats it as junk)"
    continue
  fi
  name="$(frontmatter_name "$skill_md")"
  if [[ -z "$name" ]]; then
    fail "$skill/SKILL.md: no 'name:' in frontmatter"
  elif [[ "$name" != "$skill" ]]; then
    fail "$skill/SKILL.md: frontmatter name is '$name' (must equal the directory name '$skill')"
  fi
done
printf 'checked %d skill directories\n' "${#tracked_skills[@]}"

printf '\n== skill sources: no stray nested SKILL.md ==\n'
nested_found=0
while IFS= read -r nested; do
  rel="${nested#"$skills_dir"/}"
  allowed=0
  for entry in "${nested_skill_md_allowlist[@]}"; do
    [[ "$rel" == "$entry" ]] && allowed=1 && break
  done
  if (( allowed )); then
    printf 'allowed fixture: %s\n' "$rel"
    continue
  fi
  fail "$rel: nested SKILL.md is discovered as a separate skill by Codex (rename the fixture, e.g. to fixture.md)"
  nested_found=1
done < <(find "$skills_dir" -mindepth 3 -name SKILL.md -type f | sort)
(( nested_found )) || printf 'ok\n'

printf '\n== skill-param-auditor fixtures ==\n'
fixtures_dir="$skills_dir/skill-param-auditor/examples"
if [[ -d "$fixtures_dir" ]]; then
  for fixture_dir in "$fixtures_dir"/*/; do
    [[ -f "${fixture_dir}fixture.md" ]] || fail "${fixture_dir}fixture.md is missing"
  done
  printf 'ok\n'
else
  printf 'skip: %s does not exist\n' "$fixtures_dir"
fi

if [[ "$mode" == "--repo-only" ]]; then
  printf '\n== result ==\n'
  if [[ "$status" -eq 0 ]]; then
    echo "skill repository invariants hold"
  else
    echo "one or more skill invariants failed" >&2
  fi
  exit "$status"
fi

printf '\n== installed link layers ==\n'
installed_dirs=("$HOME/.agents/skills" "$HOME/.claude/skills" "$HOME/.codex/skills")
for dir in "${installed_dirs[@]}"; do
  if [[ ! -d "$dir" ]]; then
    printf 'skip: %s does not exist\n' "$dir"
    continue
  fi
  linked=()
  for entry in "$dir"/*; do
    [[ -e "$entry" || -L "$entry" ]] || continue
    name="$(basename "$entry")"
    [[ "$name" == ".system" ]] && continue
    if [[ -L "$entry" && ! -e "$entry" ]]; then
      fail "$entry is a dangling symlink -> $(readlink "$entry")"
      continue
    fi
    if [[ ! -f "$entry/SKILL.md" ]]; then
      fail "$entry resolves to a directory without SKILL.md"
      continue
    fi
    linked+=("$name")
  done
  missing=()
  for skill in "${tracked_skills[@]}"; do
    [[ -f "$skills_dir/$skill/SKILL.md" ]] || continue
    printf '%s\n' "${linked[@]:-}" | grep -qx "$skill" || missing+=("$skill")
  done
  if (( ${#missing[@]} )); then
    warn "$dir is missing links for: ${missing[*]} (run scripts/install-ai-cli-dotfiles.sh)"
  fi
  unmanaged=()
  for name in "${linked[@]:-}"; do
    [[ -n "$name" ]] || continue
    [[ -d "$skills_dir/$name" ]] || unmanaged+=("$name")
  done
  if (( ${#unmanaged[@]} )); then
    warn "$dir holds entries this repo does not track: ${unmanaged[*]}"
  fi
  printf 'checked %s (%d links)\n' "$dir" "${#linked[@]}"
done

printf '\n== Codex system skill collisions ==\n'
system_dir="$HOME/.codex/skills/.system"
if [[ -d "$system_dir" ]]; then
  for system_path in "$system_dir"/*/; do
    system_skill="$(basename "$system_path")"
    if [[ -d "$skills_dir/$system_skill" ]]; then
      fail "$system_skill collides with the Codex system skill of the same name (rename the tracked skill)"
    fi
  done
  printf 'ok\n'
else
  printf 'skip: %s does not exist\n' "$system_dir"
fi

printf '\n== result ==\n'
if [[ "$status" -eq 0 ]]; then
  echo "skill invariants hold"
else
  echo "one or more skill invariants failed" >&2
fi
exit "$status"
