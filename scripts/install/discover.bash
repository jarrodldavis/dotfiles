#!/usr/bin/env bash
# Print install scripts in execution order. Arguments: repository root, targets.
# Discovers modules/name/install/NN-target.bash.

discover_install_scripts() {
    local root="$1" target script module output number target_order target_index
    shift

    output=$(
        target_index=0
        for target in "$@"; do
            # Keep the ordering supplied by resolve_install_targets.
            target_order=$(printf '%08d' "$target_index")
            ((target_index += 1))
            for script in "$root"/modules/*/install/[0-9][0-9]-"$target".bash; do
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
    ) || return 1

    if [[ -z "$output" ]]; then
        printf 'No install scripts found.\n' >&2
        return 1
    fi

    printf '%s\n' "$output" | sort -t $'\t' -k1,1 -k2,2 -k3,3 | cut -f3-
}
