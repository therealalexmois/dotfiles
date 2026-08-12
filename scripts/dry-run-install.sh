#!/usr/bin/env zsh
set -euo pipefail

# Validates the symlink-producing parts of the install flow (README.md's
# "Install order") against a throwaway fake $HOME, without touching the real
# $HOME or installing anything via Homebrew/npm/git-clone. Safe to re-run.
#
# Scope: the three GNU Stow packages (bootstrap, alacritty, ai-agents) plus the
# hand-symlinked zsh startup files (.zshrc, .zprofile). It intentionally does NOT execute
# zsh/bootstrap.zsh or scripts/install-ai-cli-dotfiles.sh verbatim, because both
# hardcode `$HOME/.dotfiles` internally and would need real network access
# (Oh My Zsh / plugin clones) or a real Codex/Claude install to run for real.
# See README.md "Verifying the install" for the full-fidelity VM check this
# script does not replace.

REPO_DIR="${0:A:h:h}"
KEEP=0
[[ "${1:-}" == "--keep" ]] && KEEP=1

FAKE_HOME="$(mktemp -d)"
cleanup() {
  if (( KEEP )); then
    echo "kept fake \$HOME for inspection: $FAKE_HOME"
  else
    rm -rf "$FAKE_HOME"
  fi
}
trap cleanup EXIT

echo "repo:      $REPO_DIR"
echo "fake HOME: $FAKE_HOME"
echo

cd "$REPO_DIR"

fail=0

# Compares resolved targets rather than the literal relative-symlink text, since
# that text depends on how deep $FAKE_HOME happens to be relative to $REPO_DIR.
expect_link() {
  local link_path="$1" expected_source="$2"
  if [[ ! -L "$link_path" ]]; then
    echo "FAIL: missing symlink $link_path" >&2
    fail=1
    return
  fi
  local resolved
  resolved="$(realpath "$link_path")"
  if [[ "$resolved" != "$(realpath "$expected_source")" ]]; then
    echo "FAIL: $link_path resolves to $resolved (expected $expected_source)" >&2
    fail=1
    return
  fi
  echo "ok: $link_path -> $resolved"
}

echo "=== stow: bootstrap ==="
stow -n -v --target "$FAKE_HOME" bootstrap
stow --target "$FAKE_HOME" bootstrap
expect_link "$FAKE_HOME/.zshenv" "$REPO_DIR/bootstrap/.zshenv"
echo

echo "=== stow: alacritty ==="
# mkdir -p .config first, same as bootstrap/install-alacritty.sh: without it, stow
# folds the whole ~/.config into one symlink instead of a leaf ~/.config/alacritty.
mkdir -p "$FAKE_HOME/.config"
stow -n -v --target "$FAKE_HOME" alacritty
stow --target "$FAKE_HOME" alacritty
expect_link "$FAKE_HOME/.config/alacritty" "$REPO_DIR/alacritty/.config/alacritty"
echo

echo "=== stow: ai-agents ==="
# Prepare the target directory used by the installer's runtime command link.
mkdir -p "$FAKE_HOME/.local/bin"
stow -n -v --target "$FAKE_HOME" ai-agents
stow --target "$FAKE_HOME" ai-agents
for f in .codex/AGENTS.md .claude/CLAUDE.md .claude/settings.json .claude/agents; do
  [[ -L "$FAKE_HOME/$f" || -e "$FAKE_HOME/$f" ]] || { echo "FAIL: missing $FAKE_HOME/$f" >&2; fail=1; }
done
ln -s "../../.agents/skills/git-worktree/scripts/agent-worktree-create" "$FAKE_HOME/.local/bin/agent-worktree-create"
expect_link "$FAKE_HOME/.local/bin/agent-worktree-create" "$REPO_DIR/ai-agents/.agents/skills/git-worktree/scripts/agent-worktree-create"
find "$FAKE_HOME/.claude" "$FAKE_HOME/.codex" -maxdepth 1 2>/dev/null | sort
echo

echo "=== zsh startup files (bootstrap.zsh's non-Stow symlinks) ==="
for f in .zshrc .zprofile; do
  ln -sf "$REPO_DIR/zsh/$f" "$FAKE_HOME/$f"
  [[ -e "$FAKE_HOME/$f" ]] || { echo "FAIL: $FAKE_HOME/$f is a dangling symlink" >&2; fail=1; }
  echo "ok: $FAKE_HOME/$f -> $(readlink "$FAKE_HOME/$f")"
done
echo

echo "=== skills known to ai-agents/.agents/skills ==="
skill_count=0
for skill_dir in "$REPO_DIR"/ai-agents/.agents/skills/*/; do
  skill_name="${skill_dir:t}"
  [[ "$skill_name" == *-workspace ]] && continue
  [[ -f "${skill_dir}SKILL.md" ]] || { echo "FAIL: $skill_name has no SKILL.md" >&2; fail=1; continue; }
  skill_count=$((skill_count + 1))
done
echo "ok: $skill_count skills have a SKILL.md (scripts/install-ai-cli-dotfiles.sh would link all of them)"
echo

if (( fail )); then
  echo "dry run FAILED – see FAIL lines above" >&2
  exit 1
fi
echo "dry run OK – stow packages and zsh startup symlinks resolve as README.md documents."
echo "This does not cover zsh/bootstrap.zsh's Oh My Zsh clone or scripts/install-ai-cli-dotfiles.sh's"
echo "Codex render/skill-linking logic – validate those with a full run on a clean VM."
