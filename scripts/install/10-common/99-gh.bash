#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

if ! command -v gh >/dev/null 2>&1; then
    log_warning 'GitHub CLI is not installed.'
    exit 0
fi

log_info 'GitHub CLI Authentication status:'
gh auth status || true

log_substep 'Installing GitHub CLI extensions...'
gh extension install jarrodldavis/gh-cd
gh extension install github/gh-stack
gh extension upgrade --all

log_substep 'Installing GitHub CLI skills...'
gh skill install --all --scope user --force --agent "codex" github/gh-stack
gh skill install --all --scope user --force --agent "github-copilot" github/gh-stack
gh skill update --force --all
