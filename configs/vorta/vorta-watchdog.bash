#!/usr/bin/env bash
set -euo pipefail

app_id=com.borgbase.Vorta
log_file="$HOME/.var/app/$app_id/.local/state/Vorta/log/vorta.log"

max_age=2100          # 35 minutes
restart_cooldown=900  # 15 minutes for unresponsive Vorta
missing_cooldown=60   # 1 minute for missing Vorta

state_dir="${XDG_RUNTIME_DIR:?}/vorta-watchdog"
mkdir -p "$state_dir"

log() {
    systemd-cat -t vorta-watchdog -p info <<< "$*"
}

is_running() {
    flatpak ps --columns=application |
        grep -Fxq "$app_id"
}

borg_running() {
    pgrep -x borg >/dev/null ||
        pgrep -x borg2 >/dev/null
}

check_previous_launch() {
    local pending="$state_dir/pending-verification"

    [[ -f "$pending" ]] || return 0

    rm -f "$pending"

    if is_running; then
        log "Recovery verified: Vorta is running."
    else
        log "Recovery failed: Vorta is not running after the previous launch attempt."
    fi
}

restart_vorta() {
    local reason=$1
    local cooldown=$2
    local state_file=$3
    local now last_restart=0 remaining

    now=$(date +%s)

    if [[ -f "$state_file" ]]; then
        read -r last_restart < "$state_file"
    fi

    remaining=$((cooldown - (now - last_restart)))

    if (( remaining > 0 )); then
        log "$reason Restart suppressed: cooldown has ${remaining}s remaining."
        return 0
    fi

    if borg_running; then
        log "$reason Recovery postponed because Borg is running."
        return 0
    fi

    log "$reason Initiating Vorta restart."

    # Record the attempt before launching, so failures are rate-limited too.
    printf '%s\n' "$now" > "$state_file"

    if is_running; then
        log "Terminating existing Vorta instance."

        if ! flatpak kill "$app_id"; then
            log "Failed to terminate existing Vorta instance."
            return 1
        fi
    fi

    if systemd-run --user \
        --unit="vorta-watchdog-launch-$now" \
        --wait \
        --collect \
        --quiet \
        /usr/bin/flatpak run "$app_id" --daemonize; then

        touch "$state_dir/pending-verification"
        log "Flatpak launch command completed successfully; awaiting recovery verification."
    else
        log "Flatpak launch command failed."
        return 1
    fi
}

# Verify the previous launch attempt, if any.
check_previous_launch

# Recover when Vorta is completely absent.
if ! is_running; then
    restart_vorta \
        "Vorta is not running." \
        "$missing_cooldown" \
        "$state_dir/last-missing-restart"
    exit 0
fi

# Skip responsiveness checks when the application log is unavailable.
if [[ ! -f "$log_file" ]]; then
    log "Vorta log not found; skipping responsiveness check."
    exit 0
fi

# Find the most recent scheduler heartbeat.
last_refresh=$(
    awk '
        /vorta\.scheduler.*Refreshing all scheduler timers/ {
            timestamp = substr($0, 1, 19)
        }
        END { print timestamp }
    ' "$log_file"
)

if [[ -z "$last_refresh" ]]; then
    log "No scheduler heartbeat found; skipping responsiveness check."
    exit 0
fi

# Calculate how long the scheduler has been inactive.
last_epoch=$(date -d "$last_refresh" +%s)
now=$(date +%s)
age=$((now - last_epoch))

# Restart when the scheduler heartbeat is stale.
if (( age >= max_age )); then
    restart_vorta \
        "Scheduler heartbeat is ${age}s old." \
        "$restart_cooldown" \
        "$state_dir/last-unresponsive-restart"
fi
