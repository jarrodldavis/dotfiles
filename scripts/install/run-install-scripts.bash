#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

log_step 'Collecting install scripts...'
log_substep 'Resolved installation targets:'
resolve_install_targets echo

scripts=()
collect_install_scripts() {
    local target dir script

    while IFS= read -r script; do
        scripts+=("$script")
    done < <(
        for target in "$@"; do
            for dir in "$HOME/.dotfiles/scripts/install/"[0-9][0-9]-"$target"; do
                if ! [[ -d "$dir" ]]; then
                    log_warning "Directory $dir does not exist, skipping."
                    continue
                fi

                for script in "$dir"/[0-9][0-9]-*.bash; do
                    if ! [[ -e "$script" ]]; then
                        log_warning "Directory $dir has no install scripts."
                        continue
                    fi

                    if ! [[ -x "$script" ]]; then
                        log_warning "Script $script is not executable, skipping."
                        continue
                    fi

                    printf '%s\t%s\t%s\n' \
                        "$(basename "$script")" \
                        "$(basename "$dir")" \
                        "$script"
                done
            done
        done |
            sort -t $'\t' -k1,1 -k2,2 |
            cut -f3-
    )
}

resolve_install_targets collect_install_scripts

log_substep 'Discovered install scripts:'
printf '%s\n' "${scripts[@]}"

for script in "${scripts[@]}"; do
    "$script"
done
