#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

log_step 'Configuring Codex Sandbox shim...'

cat ~/.dotfiles/configs/bwrap/shim.bash | \
    sed \
    -e "s|REPLACE_WITH_BREW_PREFIX|$(brew --prefix bubblewrap)|g" \
    | sudo tee /usr/local/bin/bwrap > /dev/null

sudo chmod +x /usr/local/bin/bwrap
