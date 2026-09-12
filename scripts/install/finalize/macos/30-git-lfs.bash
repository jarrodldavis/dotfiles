#!/usr/bin/env bash
set -euo pipefail
source ~/.dotfiles/scripts/helpers.bash

log_step 'Configuring Git LFS...'
git lfs install --system --skip-repo
