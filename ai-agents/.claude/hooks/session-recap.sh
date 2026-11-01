#!/usr/bin/env bash
# SessionStart hook: request a short recap on resume or compact.
# startup and clear receive no instruction.
# Claude uses its loaded context; the hook does not read transcripts.
#
# Contract: read JSON on stdin. Output JSON (additionalContext) on stdout, exit 0.

set -uo pipefail

command -v jq >/dev/null 2>&1 || exit 0

INPUT=$(cat)
src=$(printf '%s' "$INPUT" | jq -r '.source // empty')

case "$src" in
  resume | compact) ;;
  *) exit 0 ;;
esac

msg="This session was continued (source: $src). Before anything else, give the user a short recap (2-4 lines) from the loaded context: what we were working on, what is already done, and the next concrete step. Then wait for direction. Keep it factual, no filler."

jq -n --arg c "$msg" \
  '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $c}}'

exit 0
