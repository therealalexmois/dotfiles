#!/usr/bin/env bash
# Detect secrets/runtime config changes in deploy/service.yml across the release
# range. Read-only. Emits JSON. NEVER prints secret values - only variable names.
#
# Usage:
#   ./detect_secrets_runtime_config.sh [PREV_TAG] [REF]
# Optional env overrides:
#   REPO PREV_TAG REF SERVICE_FILE
#
# Output: {"secrets_runtime_config":"none|changed|unknown","changed_vars":[...]}
set -uo pipefail

REPO="${REPO:-.}"
PREV_TAG="${PREV_TAG:-${1:-}}"
REF="${REF:-${2:-HEAD}}"
SERVICE_FILE="${SERVICE_FILE:-deploy/service.yml}"

command -v jq >/dev/null || { echo '{"secrets_runtime_config":"unknown","changed_vars":[]}'; exit 0; }

if [ -z "$PREV_TAG" ]; then
  PREV_TAG="$(git -C "$REPO" tag -l 'release-*' --sort=-version:refname 2>/dev/null | grep -E '^release-[0-9]{6}\.[0-9]{4}$' | head -1)"
fi
if [ -z "$PREV_TAG" ] || ! git -C "$REPO" rev-parse "$PREV_TAG" >/dev/null 2>&1; then
  echo '{"secrets_runtime_config":"unknown","changed_vars":[],"note":"previous tag unavailable"}'; exit 0
fi

diff="$(git -C "$REPO" diff "$PREV_TAG..$REF" -- "$SERVICE_FILE" 2>/dev/null)"
if [ -z "$diff" ]; then
  echo '{"secrets_runtime_config":"none","changed_vars":[]}'; exit 0
fi

# Extract only variable NAMES from changed (+/-) lines. Never values.
# Matches "- name: FOO", bare "FOO:" keys and bare list items "- FOO" under envs.
names_json="$(printf '%s\n' "$diff" \
  | grep -E '^[+-]' | grep -vE '^[+-]{3}' \
  | sed -nE 's/^[+-][[:space:]]*-?[[:space:]]*name:[[:space:]]*"?([A-Za-z_][A-Za-z0-9_]*)"?.*/\1/p; s/^[+-][[:space:]]*([A-Z][A-Z0-9_]+):.*/\1/p; s/^[+-][[:space:]]*-[[:space:]]+([A-Z][A-Za-z0-9_]*)[[:space:]]*$/\1/p' \
  | sort -u | jq -R . | jq -s 'map(select(length>0))')"

jq -n --argjson v "${names_json:-[]}" '{secrets_runtime_config:"changed", changed_vars:$v}'
