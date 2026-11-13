#!/usr/bin/env bash
# Print install scripts in execution order. Arguments: repository root, targets.
# Supports both scripts/install/NN-target/NN-name.bash and
# modules/name/install/NN-target.bash during migration.

discover_install_scripts() {
    local root="$1" target dir script module output found number target_order target_index
    shift

    output=$(
        target_index=0
        for target in "$@"; do
            found=0
            # Keep the ordering supplied by resolve_install_targets.
            target_order=$(printf '%08d' "$target_index")
            ((target_index += 1))
            for dir in "$root/scripts/install/"[0-9][0-9]-"$target"; do
                [[ -d "$dir" ]] || continue

                for script in "$dir"/[0-9][0-9]-*.bash; do
                    [[ -e "$script" ]] || continue
                    if [[ ! -x "$script" ]]; then
                        printf 'Installation script is not executable: %s\n' "$script" >&2
                        exit 1
                    fi

                    found=1
                    printf '%s\t%s\t%s\n' \
                        "$(basename "$script")" "$target_order" "$script"
                done
            done

            for script in "$root"/modules/*/install/[0-9][0-9]-"$target".bash; do
                [[ -e "$script" ]] || continue
                if [[ ! -x "$script" ]]; then
                    printf 'Installation script is not executable: %s\n' "$script" >&2
                    exit 1
                fi

                found=1
                module=${script%/install/*}
                module=${module##*/}
                number=${script##*/}
                number=${number%%-*}
                # Sort as if the module's script had its legacy feature name.
                printf '%s\t%s\t%s\n' \
                    "${number}-${module}.bash" "$target_order" "$script"
            done

            if (( ! found )); then
                printf 'No installation scripts for target: %s\n' "$target" >&2
                exit 1
            fi
        done
    ) || return 1

    if [[ -z "$output" ]]; then
        printf 'No install scripts found.\n' >&2
        return 1
    fi

    printf '%s\n' "$output" | sort -t $'\t' -k1,1 -k2,2 -k3,3 | cut -f3-
}
