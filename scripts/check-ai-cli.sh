#!/usr/bin/env bash
# Lint and smoke-check the AI CLI dotfiles tooling (Codex + Claude).
# Safe to run repeatedly; performs no writes to ~/.codex or ~/.claude.
set -euo pipefail

repo_dir="${HOME}/.dotfiles"
status=0

note() { printf '\n== %s ==\n' "$1"; }
fail() { printf 'FAIL: %s\n' "$1" >&2; status=1; }

note "zsh syntax: install-ai-cli-dotfiles.sh"
if zsh -n "${repo_dir}/scripts/install-ai-cli-dotfiles.sh"; then
  echo "ok"
else
  fail "install-ai-cli-dotfiles.sh has zsh syntax errors"
fi

note "bash lint: AI CLI shell scripts"
if command -v shellcheck >/dev/null 2>&1; then
  if shellcheck \
    "${repo_dir}/ai-agents/.agents/skills/git-worktree/scripts/create-worktree" \
    "${repo_dir}/ai-agents/.claude/hooks/worktree-create.sh" \
    "${repo_dir}/ai-agents/.claude/hooks/worktree-remove.sh" \
    "${repo_dir}/ai-agents/.claude/statusline.sh" \
    "${repo_dir}/scripts/check-ai-cli.sh" \
    "${repo_dir}/scripts/test-create-worktree.sh" \
    "${repo_dir}/scripts/test-skill-discovery-names.sh"; then
    echo "ok"
  else
    fail "shellcheck reported issues"
  fi
else
  echo "skip: shellcheck not installed (brew install shellcheck)"
fi

note "python compile: render-codex-config.py"
if python3 -m py_compile "${repo_dir}/scripts/render-codex-config.py"; then
  echo "ok"
else
  fail "render-codex-config.py failed to compile"
fi

note "codex config render check (no write)"
if "${repo_dir}/scripts/render-codex-config.py" --check; then
  :
else
  fail "render --check failed"
fi

note "TOML parse: shared + profile configs"
if python3 - "$repo_dir" <<'PY'; then
import sys
import tomllib
from pathlib import Path

repo = Path(sys.argv[1])
codex_dir = repo / "ai-agents" / ".codex"
targets = [codex_dir / "config.shared.toml", *sorted(codex_dir.glob("*.config.toml"))]
for path in targets:
    with path.open("rb") as fh:
        tomllib.load(fh)
    print(f"ok: {path.name}")
PY
  :
else
  fail "a tracked Codex TOML failed to parse"
fi

note "create-worktree integration"
if "${repo_dir}/scripts/test-create-worktree.sh"; then
  echo "ok"
else
  fail "create-worktree integration failed"
fi

note "skill discovery names"
if bash "${repo_dir}/scripts/test-skill-discovery-names.sh"; then
  echo "ok"
else
  fail "skill discovery names are inconsistent"
fi

note "result"
if [[ "$status" -eq 0 ]]; then
  echo "all AI CLI dotfiles checks passed"
else
  echo "one or more checks failed" >&2
fi
exit "$status"
