#!/usr/bin/env bash
# SessionStart hook. On a CONTINUED session (source: resume or compact) it injects
# a one-time instruction to open with a short recap of where we left off. Fresh
# sessions (source: startup or clear) get nothing, so this never fires on a cold
# start. The recap is produced by Claude from the already-loaded context; this
# hook only nudges, it does not read the transcript itself.
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
