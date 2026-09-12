#!/usr/bin/env bash
set -euo pipefail
source ~/.dotfiles/scripts/helpers.bash

log_step 'Updating global gitignore...'

if ! command -v gibo >/dev/null 2>&1; then
    log_warning "gibo is not installed. Please install gibo to update the global gitignore."
    exit 0
fi

gibo update
GITIGNORE_FILE="$HOME/.dotfiles/configs/gitignore"
GITIGNORE_CONTENTS="$(cat "$GITIGNORE_FILE")"
echo "$GITIGNORE_CONTENTS" | \
    sed -E -n 's|### https://raw.github.com/github/gitignore/[[:alnum:]]*/(Global/)?([[:alnum:]]*).gitignore|\2|gp' | \
    xargs gibo dump > "$GITIGNORE_FILE"
