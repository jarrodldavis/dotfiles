#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

log_step 'Collecting install scripts...'

scripts=()

collect_install_scripts() {
    local target dir script output errors

    output=$(
        errors=0

        for target in "$@"; do
            for dir in "$HOME/.dotfiles/scripts/install/"[0-9][0-9]-"$target"; do
                if [[ ! -d "$dir" ]]; then
                    log_error "Directory for target '$target' does not exist."
                    errors=1
                    continue
                fi

                for script in "$dir"/[0-9][0-9]-*.bash; do
                    if [[ ! -e "$script" ]]; then
                        log_error "Directory $dir has no install scripts."
                        errors=1
                        continue
                    fi

                    if [[ ! -x "$script" ]]; then
                        log_error "Script $script is not executable."
                        errors=1
                        continue
                    fi

                    printf '%s\t%s\t%s\n' \
                        "$(basename "$script")" \
                        "$(basename "$dir")" \
                        "$script"
                done
            done
        done

        if (( errors )); then
            exit 1
        fi
    )

    if [[ -z "$output" ]]; then
        log_error "No install scripts found."
        return 1
    fi

    while IFS= read -r script; do
        scripts+=("$script")
    done < <(
        printf '%s\n' "$output" |
            sort -t $'\t' -k1,1 -k2,2 |
            cut -f3-
    )
}

resolve_install_targets collect_install_scripts

log_info 'Resolved installation targets:'
resolve_install_targets echo

log_info 'Discovered install scripts:'
printf '%s\n' "${scripts[@]}"

previous_phase=

for script in "${scripts[@]}"; do
    filename=${script##*/}
    phase=${filename#*-}
    phase=${phase%.bash}

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
