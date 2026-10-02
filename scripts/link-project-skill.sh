#!/usr/bin/env zsh
# Link one tracked skill into an external project repo's own skill directory
# (.claude/skills/ and/or .agents/skills/), instead of (or in addition to) the
# global ~/.claude/skills/ and ~/.agents/skills/ links installed by
# install-ai-cli-dotfiles.sh.
#
# This script intentionally takes the target repo path as an argument rather
# than reading it from a tracked file: dotfiles installs on multiple machines,
# and most target project repos (life-os, markova.studio, finsight, ...) only
# exist on some of them. Keeping the mapping out of the repo keeps the
# mechanism generic; run this once per machine, per repo, per skill you want
# scoped there.
#
# To also stop linking a skill into ~/.claude/skills/ globally, add it to
# scripts/claude-external-project-skills.txt and rerun
# scripts/install-ai-cli-dotfiles.sh --skills-only. Claude reads
# <repo>/.claude/skills/ and Codex reads <repo>/.agents/skills/; --agent picks
# which of the two gets the link (default: both).
#
# The link target is an absolute path into this machine's dotfiles checkout, so
# it must never be committed to the target repo. When the target repo is a Git
# work tree and the link path is not ignored yet, the script appends it to that
# repo's local .git/info/exclude (never to a tracked .gitignore).
#
# Usage:
#   scripts/link-project-skill.sh <skill-name> <path-to-repo> [--agent claude|codex|both]
#   scripts/link-project-skill.sh --remove <skill-name> <path-to-repo> [--agent claude|codex|both]
#
# Idempotent: re-running with the same arguments is a no-op. A pre-existing
# file or foreign symlink at the destination is left untouched and reported as
# an error, never overwritten or removed.
set -euo pipefail

repo_dir="${0:A:h:h}"
skills_dir="${repo_dir}/ai-agents/.agents/skills"

usage() {
  echo "usage: $0 [--remove] <skill-name> <path-to-repo> [--agent claude|codex|both]" >&2
  exit 2
}

mode="link"
agent="both"
positional=()
while (( $# )); do
  case "$1" in
    --agent)
      (( $# >= 2 )) || usage
      agent="$2"
      shift 2
      ;;
    --remove)
      mode="remove"
      shift
      ;;
    -*)
      usage
      ;;
    *)
      positional+=("$1")
      shift
      ;;
  esac
done
(( ${#positional[@]} == 2 )) || usage
[[ "$agent" == claude || "$agent" == codex || "$agent" == both ]] || usage

skill="${positional[1]}"
target_repo="${positional[2]}"

if [[ ! "$skill" =~ '^[a-z0-9]+(-[a-z0-9]+)*$' ]]; then
  echo "invalid skill name: ${skill}" >&2
  exit 1
fi
if [[ ! -f "${skills_dir}/${skill}/SKILL.md" ]]; then
  echo "unknown skill (no ${skills_dir}/${skill}/SKILL.md): ${skill}" >&2
  exit 1
fi

target_repo="${target_repo:A}"
if [[ ! -d "$target_repo" ]]; then
  echo "not a directory: $target_repo" >&2
  exit 1
fi

target="${skills_dir}/${skill}"

# Prints the repo-root-anchored exclude pattern for a link, or nothing when the
# target repo is not a Git work tree. No trailing slash: Git sees a symlink as a
# file, and a directory-only pattern would not match it.
exclude_pattern() {
  local dir_name="$1"
  git -C "$target_repo" rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0
  local prefix
  prefix="$(git -C "$target_repo" rev-parse --show-prefix)"
  print -r -- "/${prefix}${dir_name}/skills/${skill}"
}

exclude_file() {
  git -C "$target_repo" rev-parse --path-format=absolute --git-path info/exclude
}

ensure_excluded() {
  local dir_name="$1"
  local link_path="$2"
  local pattern
  pattern="$(exclude_pattern "$dir_name")"
  [[ -n "$pattern" ]] || return 0
  git -C "$target_repo" check-ignore -q -- "$link_path" && return 0

  local file
  file="$(exclude_file)"
  mkdir -p "${file:h}"
  print -r -- "$pattern" >> "$file"
  echo "added to ${file}: ${pattern}"
}

drop_exclude() {
  local dir_name="$1"
  local pattern
  pattern="$(exclude_pattern "$dir_name")"
  [[ -n "$pattern" ]] || return 0

  local file
  file="$(exclude_file)"
  [[ -f "$file" ]] || return 0
  grep -qxF -- "$pattern" "$file" || return 0

  local rest
  rest="$(grep -vxF -- "$pattern" "$file" || [[ $? -eq 1 ]])"
  if [[ -n "$rest" ]]; then
    print -r -- "$rest" > "$file"
  else
    : > "$file"
  fi
  echo "removed from ${file}: ${pattern}"
}

link_into() {
  local dir_name="$1"
  local link_dir="${target_repo}/${dir_name}/skills"
  local link_path="${link_dir}/${skill}"

  mkdir -p "$link_dir"
  if [[ -L "$link_path" ]]; then
    local current
    current="$(readlink "$link_path")"
    if [[ "$current" != "$target" ]]; then
      echo "unexpected skill symlink: $link_path -> $current" >&2
      exit 1
    fi
    echo "skill link ok: $link_path -> $current"
  elif [[ -e "$link_path" ]]; then
    echo "refusing to overwrite existing path: $link_path" >&2
    exit 1
  else
    ln -s "$target" "$link_path"
    echo "created skill link: $link_path -> $target"
  fi
  ensure_excluded "$dir_name" "$link_path"
}

unlink_from() {
  local dir_name="$1"
  local link_path="${target_repo}/${dir_name}/skills/${skill}"

  if [[ -L "$link_path" ]]; then
    local current
    current="$(readlink "$link_path")"
    if [[ "$current" != "$target" ]]; then
      echo "refusing to remove foreign symlink: $link_path -> $current" >&2
      exit 1
    fi
    rm "$link_path"
    echo "removed skill link: $link_path"
  elif [[ -e "$link_path" ]]; then
    echo "refusing to remove non-symlink path: $link_path" >&2
    exit 1
  else
    echo "skill link absent: $link_path"
  fi
  drop_exclude "$dir_name"
}

dir_names=()
[[ "$agent" == claude || "$agent" == both ]] && dir_names+=(".claude")
[[ "$agent" == codex || "$agent" == both ]] && dir_names+=(".agents")

for dir_name in "${dir_names[@]}"; do
  if [[ "$mode" == "link" ]]; then
    link_into "$dir_name"
  else
    unlink_from "$dir_name"
  fi
done
