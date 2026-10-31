#!/usr/bin/env bash
set -euo pipefail

app_id=com.borgbase.Vorta
autostart_entry="$HOME/.config/autostart/vorta.desktop"
log_file="$HOME/.var/app/$app_id/.local/state/Vorta/log/vorta.log"

max_age=2100 # 35 minutes
cooldown=900 # 15 minutes

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

restart_vorta() {
    local reason=$1
    local now last_restart=0

    now=$(date +%s)

    if [[ -f "$state_dir/last-restart" ]]; then
        read -r last_restart < "$state_dir/last-restart"
    fi

    if (( now - last_restart < cooldown )); then
        return
    fi

    if borg_running; then
        log "$reason Recovery postponed because Borg is running."
        return
    fi

    log "$reason Restarting Vorta."

    if is_running; then
        flatpak kill "$app_id"
    fi

    if systemd-run --user \
        --unit="vorta-watchdog-launch-$now" \
        --collect \
        /usr/bin/gio launch "$autostart_entry"; then
        printf '%s\n' "$now" > "$state_dir/last-restart"
    else
        log "Failed to launch Vorta."
        return 1
    fi
}

# Recover if Vorta isn't running.
if ! is_running; then
    restart_vorta "Vorta is not running."
    exit 0
fi

# Check that the application log exists.
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

# Restart if the heartbeat is too old.
if (( age >= max_age )); then
    restart_vorta "Scheduler heartbeat is ${age}s old."
fi
