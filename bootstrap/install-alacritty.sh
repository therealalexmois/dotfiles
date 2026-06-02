#!/usr/bin/env zsh
set -euo pipefail

DOTFILES_DIR="${HOME}/.dotfiles"
BACKUP_DIR="${HOME}/.dotfiles-backups/alacritty/config-backup-$(date +%Y%m%d-%H%M%S)"
TARGET="${HOME}/.config/alacritty"

echo "🔧 Bootstrapping Alacritty config..."

if [[ -e "$TARGET" && ! -L "$TARGET" ]]; then
  echo "📦 Backing up existing $TARGET → $BACKUP_DIR"
  mkdir -p "$BACKUP_DIR"
  cp -pR "$TARGET" "$BACKUP_DIR"
  rm -rf "$TARGET"
fi

stow --dir "$DOTFILES_DIR" --target "$HOME" alacritty

echo "✅ Symlink: $TARGET → $(readlink "$TARGET")"
echo "✅ Done! Restart Alacritty to apply."
