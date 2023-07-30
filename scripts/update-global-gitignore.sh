#!/bin/zsh
set -euo pipefail

GITIGNORE_FILE="$HOME/.dotfiles/configs/gitignore"
GITIGNORE_CONTENTS="$(cat $GITIGNORE_FILE)"
echo "$GITIGNORE_CONTENTS" | $HOME/.dotfiles/scripts/gibo-redump.sh > "$GITIGNORE_FILE"
