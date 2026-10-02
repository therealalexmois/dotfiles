#!/usr/bin/env bash
# Session-capture hook for the wiki@llm-wiki plugin. Records redacted Claude Code
# session events into <HUB>/.sessions/ (HUB comes from ~/.config/llm-wiki/config.json)
# and lets the helper inject rehydration context on SessionStart/UserPromptSubmit.
#
# Plugin 0.25.0 ships the session helper only in its Codex build, so this runs the
# highest installed version from either plugin cache (the Claude cache wins a tie).
# The events wired in settings.json mirror the plugin's own Codex hooks.json; drop
# this wiring once the Claude build ships hooks itself, or every event is captured
# twice. Capture can be switched off without touching settings.json:
# `python3 <helper> disable` (honored via --if-enabled); per-prompt rehydration is
# the `rehydrate.user_prompt` key in <HUB>/.sessions/config.json.
#
# Contract: hook JSON on stdin, optional additionalContext JSON on stdout. No helper
# installed means no capture (exit 0); helper errors exit 1, which never blocks work.

set -uo pipefail

helper=""
helper_version=""
for candidate in \
  "$HOME"/.claude/plugins/cache/llm-wiki/wiki/*/hooks/llm_wiki_session.py \
  "$HOME"/.codex/plugins/cache/llm-wiki/wiki/*/hooks/llm_wiki_session.py; do
  [ -f "$candidate" ] || continue
  version="${candidate%/hooks/llm_wiki_session.py}"
  version="${version##*/}"
  if [ -z "$helper" ] || [ "$(printf '%s\n%s\n' "$helper_version" "$version" | sort -V | tail -n 1)" != "$helper_version" ]; then
    helper=$candidate
    helper_version=$version
  fi
done

[ -n "$helper" ] || exit 0

exec python3 "$helper" hook --harness claude --if-enabled
