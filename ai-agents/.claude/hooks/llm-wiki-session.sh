#!/usr/bin/env bash
# wiki@llm-wiki hook: record redacted events in <HUB>/.sessions/.
# HUB comes from ~/.config/llm-wiki/config.json.
# SessionStart/UserPromptSubmit may inject rehydration context.
#
# Plugin 0.25.0 ships the helper only in its Codex build.
# Use the highest cached version; Claude wins a version tie.
# The target project's .claude/settings.local.json mirrors the plugin's Codex
# hooks.json. Do not wire this hook globally. Remove this wiring when Claude
# ships its own hooks, to avoid duplicate capture.
# Disable capture: `python3 <helper> disable` (honored via --if-enabled).
# Per-prompt rehydration: rehydrate.user_prompt in <HUB>/.sessions/config.json.
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
