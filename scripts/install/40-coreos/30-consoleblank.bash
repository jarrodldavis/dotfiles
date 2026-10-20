#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

TIMEOUT_MINUTES=1

log_step 'Enabling console blanking...'
check_sudo

timeout_seconds=$((TIMEOUT_MINUTES * 60))

# enable console blanking immediately
sudo sh -c "setterm --blank $TIMEOUT_MINUTES --term linux < /dev/tty1 > /dev/tty1"

# persist console blanking across reboots via kernel argument
want="consoleblank=$timeout_seconds"
read -ra current <<< "$(rpm-ostree kargs)"

args=()
have_wanted=false
for k in "${current[@]}"; do
    case "$k" in
        "$want")        have_wanted=true ;;
        consoleblank=*) args+=("--delete-if-present=$k") ;;   # wrong value
        consoleblank)   args+=("--delete-if-present=$k") ;;   # bare key, no value
    esac
done
$have_wanted || args+=("--append-if-missing=$want")

if ((${#args[@]})); then
    sudo rpm-ostree kargs "${args[@]}"
fi

log_success "Console blanking enabled!"

log_info "Current session:"
bat /sys/module/kernel/parameters/consoleblank

log_info "Kernel arguments:"
rpm-ostree kargs
