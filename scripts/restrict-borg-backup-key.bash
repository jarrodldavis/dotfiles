#!/usr/bin/env bash
set -euo pipefail

authorized_keys="$HOME/.ssh/authorized_keys"
command_path="$HOME/.local/bin/borg-backup-server"
prefix="restrict,command=\"$command_path\""
temporary_file="$(mktemp "${authorized_keys}.XXXXXX")"
trap 'rm -f "$temporary_file"' EXIT

awk -v prefix="$prefix" '
    /[[:space:]]coreos-borg-backup$/ {
        matches++

        if (index($0, prefix " ") != 1) {
            if ($0 ~ /(^|,)command=/ || $0 ~ /^restrict,/) {
                print "Borg key already has unexpected authorized_keys options" > "/dev/stderr"
                failed = 1
                exit
            }

            $0 = prefix " " $0
        }
    }

    { print }

    END {
        if (failed) {
            exit 2
        }

        if (matches != 1) {
            print "Expected exactly one coreos-borg-backup key; found " matches > "/dev/stderr"
            exit 1
        }
    }
' "$authorized_keys" > "$temporary_file"

chmod --reference="$authorized_keys" "$temporary_file"
mv "$temporary_file" "$authorized_keys"
trap - EXIT
