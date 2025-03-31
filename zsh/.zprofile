echo "Loading ${USER} .zprofile..."

# GUI terminal session-specific setup
[[ -n "$DISPLAY" ]] && export EDITOR="nvim"

# Ensure Homebrew is first in PATH
export PATH="/opt/homebrew/bin:/opt/homebrew/opt/openjdk/bin:$PATH"
