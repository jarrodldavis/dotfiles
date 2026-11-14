#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash
# shellcheck source=scripts/install/discover.bash
source ~/.dotfiles/scripts/install/discover.bash

log_step 'Collecting install scripts...'

collect_install_scripts() {
    local -a discovered=()
    local script output

    output=$(discover_install_scripts "$HOME/.dotfiles" "$@") || return 1
    while IFS= read -r script; do
        discovered+=("$script")
    done <<< "$output"
    scripts=("${discovered[@]}")
}

scripts=()
resolve_install_targets collect_install_scripts

log_info 'Resolved installation targets:'
resolve_install_targets echo

log_info 'Discovered install scripts:'
printf '%s\n' "${scripts[@]}"

previous_phase=

for script in "${scripts[@]}"; do
    module=${script%/install/*}
    module_name=${module##*/}
    filename=${script##*/}
    phase_number=${filename%%-*}
    phase="${phase_number}-${module_name}"

    if [[ -z "$previous_phase" ]]; then
        log_step "Starting installation phase: $phase"
    fi

    if [[ -n "$previous_phase" && "$phase" != "$previous_phase" ]]; then
        log_done "Finished installation phase: $previous_phase"
        log_step "Starting installation phase: $phase"
    fi

    "$script"
    previous_phase=$phase
done

log_done "Finished installation phase: $previous_phase"
