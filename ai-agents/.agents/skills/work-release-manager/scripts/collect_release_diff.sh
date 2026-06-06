#!/usr/bin/env bash
# Collect factual release diff for dwsai-data-agent: commits, diffstat, tickets.
# Read-only. Emits JSON. Feeds changelog/ownership (release-diff-agent or main).
#
# Usage:
#   ./collect_release_diff.sh [PREV_TAG] [REF]
# Optional env overrides:
#   REPO PREV_TAG REF
#
# Exit: 0 ok, 2 usage/precondition error.
set -uo pipefail

REPO="${REPO:-.}"
PREV_TAG="${PREV_TAG:-${1:-}}"
REF="${REF:-${2:-HEAD}}"

command -v jq >/dev/null || { echo '{"error":"jq not found"}'; exit 2; }
git -C "$REPO" rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo '{"error":"not a git repo"}'; exit 2; }

if [ -z "$PREV_TAG" ]; then
  PREV_TAG="$(git -C "$REPO" tag -l 'release-*' --sort=-version:refname 2>/dev/null | grep -E '^release-[0-9]{6}\.[0-9]{4}$' | head -1)"
fi
[ -n "$PREV_TAG" ] || { echo '{"error":"previous release tag not resolved"}'; exit 2; }

range="$PREV_TAG..$REF"
head_commit="$(git -C "$REPO" rev-parse --short "$REF" 2>/dev/null || echo '')"

# diffstat via numstat
ins=$(git -C "$REPO" diff --numstat "$range" 2>/dev/null | awk '{a+=$1} END{print a+0}')
del=$(git -C "$REPO" diff --numstat "$range" 2>/dev/null | awk '{d+=$2} END{print d+0}')
files=$(git -C "$REPO" diff --name-only "$range" 2>/dev/null | grep -c . || echo 0)

commits_json="$(git -C "$REPO" log --format='%h%x1f%an%x1f%s' "$range" 2>/dev/null \
  | jq -R 'split("") | {hash:.[0], author:.[1], subject:.[2]}' | jq -s .)"

tickets_json="$(git -C "$REPO" log --format='%s%n%b' "$range" 2>/dev/null \
  | grep -oiE '(DWSAI|DGP|DC)-[0-9]+' | tr 'a-z' 'A-Z' | sort -u | jq -R . | jq -s 'map(select(length>0))')"

jq -n \
  --arg prev "$PREV_TAG" --arg ref "$REF" --arg head "$head_commit" \
  --argjson files "${files:-0}" --argjson ins "${ins:-0}" --argjson del "${del:-0}" \
  --argjson commits "${commits_json:-[]}" --argjson tickets "${tickets_json:-[]}" \
  '{previous_release_tag:$prev, ref:$ref, head_commit:$head,
    diffstat:{files:$files, insertions:$ins, deletions:$del},
    commits:$commits, tickets:$tickets}'
