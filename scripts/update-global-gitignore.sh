#!/usr/bin/env zsh
set -euo pipefail

if ! command -v gibo >/dev/null 2>&1; then
    echo "gibo is not installed. Please install gibo to update the global gitignore."
    exit 0
fi

gibo update
GITIGNORE_FILE="$HOME/.dotfiles/configs/gitignore"
GITIGNORE_CONTENTS="$(cat "$GITIGNORE_FILE")"
echo "$GITIGNORE_CONTENTS" | "$HOME/.dotfiles/scripts/gibo-redump.sh" > "$GITIGNORE_FILE"
