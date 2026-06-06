#!/usr/bin/env bash
# Detect DB migrations introduced in the release range. Read-only. Emits JSON.
#
# Usage:
#   ./detect_db_migrations.sh [PREV_TAG] [REF]
# Optional env overrides:
#   REPO PREV_TAG REF MIGRATIONS_DIR
#
# Output: {"db_migrations":"none|present|unknown","files":[...]}
set -uo pipefail

REPO="${REPO:-.}"
PREV_TAG="${PREV_TAG:-${1:-}}"
REF="${REF:-${2:-HEAD}}"
MIGRATIONS_DIR="${MIGRATIONS_DIR:-migrations/}"

command -v jq >/dev/null || { echo '{"db_migrations":"unknown","files":[]}'; exit 0; }

if [ -z "$PREV_TAG" ]; then
  PREV_TAG="$(git -C "$REPO" tag -l 'release-*' --sort=-version:refname 2>/dev/null | grep -E '^release-[0-9]{6}\.[0-9]{4}$' | head -1)"
fi
if [ -z "$PREV_TAG" ] || ! git -C "$REPO" rev-parse "$PREV_TAG" >/dev/null 2>&1; then
  echo '{"db_migrations":"unknown","files":[],"note":"previous tag unavailable"}'; exit 0
fi

files_json="$(git -C "$REPO" diff --name-only "$PREV_TAG..$REF" -- "$MIGRATIONS_DIR" 2>/dev/null \
  | grep -E '\.(py|sql)$' | jq -R . | jq -s 'map(select(length>0))')"
n="$(printf '%s' "$files_json" | jq 'length')"
[ "${n:-0}" -gt 0 ] && state="present" || state="none"

jq -n --arg s "$state" --argjson f "${files_json:-[]}" '{db_migrations:$s, files:$f}'
