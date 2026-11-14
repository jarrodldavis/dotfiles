log_step 'Collecting install scripts...'

discover_install_scripts() {
    local target script module output number target_order target_index

    target_index=0
    for target in "$@"; do
        # Keep the ordering supplied by resolve_install_targets.
        target_order=$(printf '%08d' "$target_index")
        ((target_index += 1))
        for script in ~/.dotfiles/modules/*/install/[0-9][0-9]-"$target".bash; do
            [[ -e "$script" ]] || continue

            module=${script%/install/*}
            module=${module##*/}
            number=${script##*/}
            number=${number%%-*}
            # Sort by phase number and module name, then target priority.
            printf '%s\t%s\t%s\n' \
                "${number}-${module}.bash" "$target_order" "$script"
        done
    done
}

collect_install_scripts() {
    local -a discovered=()
    local script output

    output=$(discover_install_scripts "$@")
    if [[ -z "$output" ]]; then
        log_fatal 'No install scripts found.'
    fi

    while IFS= read -r script; do
        discovered+=("$script")
    done <<< "$(printf '%s\n' "$output" | sort -t $'\t' -k1,1 -k2,2 -k3,3 | cut -f3-)"
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

    bash "$script"
    previous_phase=$phase
done

log_done "Finished installation phase: $previous_phase"
