#!/usr/bin/env bash
# PostToolUse hook (Edit|Write|MultiEdit). WARN-ONLY lint; never edits files.
#
# Scoped to the dotfiles repo only (resolved through symlinks, so stowed paths
# like ~/.claude/... count). Files in other repositories are ignored.
#
#   - nvim/**/*.lua  -> stylua --check  (style drift against nvim/.stylua.toml)
#   - **/*.sh        -> shellcheck      (shell script issues)
#
# Out-of-scope files, a missing linter, or a clean result all exit 0 silently.
# On a lint failure the linter output goes to stderr and the hook exits 2, which
# Claude Code feeds back to Claude as a signal to fix (the tool already ran).
#
# Override the repo root with DOTFILES_DIR (defaults to ~/.dotfiles).
#
# Contract: read JSON on stdin. exit 0 = quiet pass; exit 2 = warn to Claude.

set -uo pipefail

command -v jq >/dev/null 2>&1 || exit 0

INPUT=$(cat)
file=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')
[ -n "$file" ] || exit 0
[ -f "$file" ] || exit 0

# Resolve a path to its physical location (follows symlinked dirs via pwd -P).
phys_path() {
  printf '%s/%s\n' "$(cd "$(dirname "$1")" 2>/dev/null && pwd -P)" "$(basename "$1")"
}

# Scope guard: only lint files inside the dotfiles repo. Compare physical paths
# so a stowed symlink (e.g. ~/.claude/hooks/x.sh) still resolves into the repo.
dotfiles=$(cd "${DOTFILES_DIR:-$HOME/.dotfiles}" 2>/dev/null && pwd -P) || exit 0
real=$(phys_path "$file")
case "$real" in "$dotfiles"/*) ;; *) exit 0 ;; esac

# Walk up from the file to find the nearest stylua config, so --check resolves
# the right ruleset regardless of CWD.
find_stylua_config() {
  local d
  d=$(dirname "$1")
  while [ "$d" != "/" ] && [ -n "$d" ]; do
    [ -f "$d/.stylua.toml" ] && { printf '%s\n' "$d/.stylua.toml"; return 0; }
    [ -f "$d/stylua.toml" ] && { printf '%s\n' "$d/stylua.toml"; return 0; }
    d=$(dirname "$d")
  done
  return 1
}

case "$file" in
  *.lua)
    # Only Neovim config Lua carries a stylua ruleset; skip stray .lua elsewhere.
    case "$file" in */nvim/*) ;; *) exit 0 ;; esac
    command -v stylua >/dev/null 2>&1 || exit 0
    cfg=$(find_stylua_config "$file" || true)
    if [ -n "$cfg" ]; then
      out=$(stylua --config-path "$cfg" --check "$file" 2>&1) && exit 0
    else
      out=$(stylua --check "$file" 2>&1) && exit 0
    fi
    printf 'lint-on-edit: stylua reports formatting issues in %s:\n' "$file" >&2
    printf '%s\n' "$out" >&2
    printf 'Run: stylua %s\n' "$file" >&2
    exit 2
    ;;
  *.sh)
    command -v shellcheck >/dev/null 2>&1 || exit 0
    out=$(shellcheck -f gcc "$file" 2>&1) && exit 0
    printf 'lint-on-edit: shellcheck reports issues in %s:\n' "$file" >&2
    printf '%s\n' "$out" >&2
    exit 2
    ;;
esac

exit 0
