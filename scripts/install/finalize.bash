#!/usr/bin/env bash
set -euo pipefail
source ~/.dotfiles/scripts/helpers.bash

run_scripts() {
    local targets=("$@")
    for target in "${targets[@]}"; do
        for script in "$HOME/.dotfiles/scripts/install/finalize/$target"/[0-9][0-9]-*; do
            [ -x "$script" ] || continue
            "$script"
        done
    done
}

dispatch_os_targets run_scripts
