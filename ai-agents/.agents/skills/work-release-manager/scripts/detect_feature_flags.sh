#!/usr/bin/env bash
# Detect new remote-config feature flags (release.*) added in the release range.
# Read-only. Emits JSON. Unregistered flags surface at runtime as Sage FLAG_NOT_FOUND.
#
# Usage:
#   ./detect_feature_flags.sh [PREV_TAG] [REF]
# Optional env overrides:
#   REPO PREV_TAG REF PARAMS_FILE
#
# Output: {"feature_flags":"none|changed|unknown","new_flags":[...]}
set -uo pipefail

REPO="${REPO:-.}"
PREV_TAG="${PREV_TAG:-${1:-}}"
REF="${REF:-${2:-HEAD}}"
PARAMS_FILE="${PARAMS_FILE:-src/app/infrastructure/remote_config/params.py}"

command -v jq >/dev/null || { echo '{"feature_flags":"unknown","new_flags":[]}'; exit 0; }

if [ -z "$PREV_TAG" ]; then
  PREV_TAG="$(git -C "$REPO" tag -l 'release-*' --sort=-version:refname 2>/dev/null | grep -E '^release-[0-9]{6}\.[0-9]{4}$' | head -1)"
fi
if [ -z "$PREV_TAG" ] || ! git -C "$REPO" rev-parse "$PREV_TAG" >/dev/null 2>&1; then
  echo '{"feature_flags":"unknown","new_flags":[],"note":"previous tag unavailable"}'; exit 0
fi

flags_json="$(git -C "$REPO" diff "$PREV_TAG..$REF" -- "$PARAMS_FILE" 2>/dev/null \
  | grep -E "^\+[[:space:]]*key='release\." \
  | sed -E "s/.*key='([^']+)'.*/\1/" \
  | sort -u | jq -R . | jq -s 'map(select(length>0))')"
n="$(printf '%s' "$flags_json" | jq 'length')"
[ "${n:-0}" -gt 0 ] && state="changed" || state="none"

jq -n --arg s "$state" --argjson f "${flags_json:-[]}" '{feature_flags:$s, new_flags:$f}'
