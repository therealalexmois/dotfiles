#!/usr/bin/env zsh

echo "🔧 Bootstrapping Zsh environment..."

# Paths
DOTFILES_ZSH="$HOME/.dotfiles/zsh"
ZSH_FILES=(.zshrc .zprofile .zlogin)

for file in $ZSH_FILES; do
  TARGET="$HOME/$file"
  SOURCE="$DOTFILES_ZSH/$file"

  if [[ -e "$TARGET" || -L "$TARGET" ]]; then
    echo "🗑  Removing existing $TARGET"
    rm -f "$TARGET"
  fi

  echo "🔗 Linking $SOURCE → $TARGET"
  ln -s "$SOURCE" "$TARGET"
done

echo "✅ Symlinks set. Zsh will now load from .dotfiles/zsh"

# Optional: Oh My Zsh initial install (if not already installed)
if [[ ! -d "$DOTFILES_ZSH/.oh-my-zsh" ]]; then
  echo "📦 Installing Oh My Zsh into $DOTFILES_ZSH/.oh-my-zsh..."
  git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$DOTFILES_ZSH/.oh-my-zsh"
fi

echo "✅ Done! Restart your terminal or run: exec zsh"
