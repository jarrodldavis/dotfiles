#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

log_step 'Configuring GitHub CLI...'

if command -v gh >/dev/null 2>&1; then
    gh auth status || true
    gh extension install jarrodldavis/gh-cd
    gh extension upgrade jarrodldavis/gh-cd
else
    log_warning 'GitHub CLI is not installed.'
fi
