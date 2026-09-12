#!/usr/bin/env bash
set -euo pipefail
source ~/.dotfiles/scripts/helpers.bash

log_step 'Configuring NUT...'
check_sudo

USER=$(id -un)
GROUP=$(id -gn)

HA_PASSWORD=$(openssl rand -hex 24)
UPSMON_PASSWORD="$(openssl rand -hex 24)"

BREW_PREFIX="$(brew --prefix)"
CONFIG_DIR="$BREW_PREFIX/etc/nut"
LOG_DIR="$BREW_PREFIX/var/log"
RUN_DIR="$BREW_PREFIX/var/run"
STATE_DIR="$BREW_PREFIX/var/state/ups"

install_config() {
    case "$1" in
        /*) from="$1" ;;
        *) from="$HOME/.dotfiles/configs/nut/$1" ;;
    esac
    to="$2"

    cat "$from" | \
        sed \
        -e "s/REPLACE_WITH_HA_PASSWORD/$HA_PASSWORD/g" \
        -e "s/REPLACE_WITH_UPSMON_USER/$USER/g" \
        -e "s/REPLACE_WITH_UPSMON_GROUP/$GROUP/g" \
        -e "s/REPLACE_WITH_UPSMON_PASSWORD/$UPSMON_PASSWORD/g" \
        -e "s|REPLACE_WITH_BREW_PREFIX|$BREW_PREFIX|g" \
        | sudo tee "$to" > /dev/null

    echo "$from -> $to"
}

log_substep 'Installing configuration files...'

mkdir -pv "$CONFIG_DIR"

if ! [ -f "$BREW_PREFIX/etc/nut/upsd.users" ]; then
    install_config upsd.users "$CONFIG_DIR/upsd.users"
else
    install_config "$CONFIG_DIR/upsd.users" "$CONFIG_DIR/upsd.users"
fi

UPSMON_PASSWORD=$(
    awk '
      /^\[upsmon\]/ { flag=1; next }
      /^\[/         { flag=0 }
      flag && /^[[:space:]]*password[[:space:]]*=/ { print $3 }
    ' "$CONFIG_DIR/upsd.users"
)

install_config upsmon.conf "$CONFIG_DIR/upsmon.conf"
install_config nut.conf "$CONFIG_DIR/nut.conf"
install_config ups.conf "$CONFIG_DIR/ups.conf"
install_config upsd.conf "$CONFIG_DIR/upsd.conf"

sudo chown -v "root:$GROUP" "$CONFIG_DIR"/*.{conf,users}
sudo chmod -v 640 "$CONFIG_DIR"/*.{conf,users}

log_substep 'Installing NUT driver daemon...'
install_config local.nut-driver.plist /Library/LaunchDaemons/local.nut-driver.plist
sudo chown -v root:wheel /Library/LaunchDaemons/local.nut-driver.plist
sudo chmod -v 644 /Library/LaunchDaemons/local.nut-driver.plist
plutil -lint /Library/LaunchDaemons/local.nut-driver.plist

log_substep 'Installing NUT server daemon...'
install_config local.nut-server.plist /Library/LaunchDaemons/local.nut-server.plist
sudo chown -v root:wheel /Library/LaunchDaemons/local.nut-server.plist
sudo chmod -v 644 /Library/LaunchDaemons/local.nut-server.plist
plutil -lint /Library/LaunchDaemons/local.nut-server.plist

log_substep 'Installing NUT monitor daemon...'
install_config local.nut-monitor.plist /Library/LaunchDaemons/local.nut-monitor.plist
sudo chown -v root:wheel /Library/LaunchDaemons/local.nut-monitor.plist
sudo chmod -v 644 /Library/LaunchDaemons/local.nut-monitor.plist
plutil -lint /Library/LaunchDaemons/local.nut-monitor.plist

log_substep 'Initializing runtime directories...'
mkdir -pv "$LOG_DIR"
touch "$LOG_DIR"/nut-{driver,server,monitor}.log
mkdir -pv "$RUN_DIR"
sudo chown -v "root:$GROUP" "$RUN_DIR"
sudo chmod -v 775 "$RUN_DIR"
mkdir -pv "$STATE_DIR"
chmod -v 700 "$STATE_DIR"

log_substep 'Initializing NUT daemons...'
if launchctl print system/local.nut-monitor >/dev/null 2>&1 ; then
    sudo launchctl bootout system /Library/LaunchDaemons/local.nut-monitor.plist
fi

while pgrep -x upsmon >/dev/null; do
  sleep 0.1
done

if launchctl print system/local.nut-server >/dev/null 2>&1 ; then
    sudo launchctl bootout system /Library/LaunchDaemons/local.nut-server.plist
fi

if launchctl print system/local.nut-driver >/dev/null 2>&1 ; then
    sudo launchctl bootout system /Library/LaunchDaemons/local.nut-driver.plist
fi

sudo launchctl bootstrap system /Library/LaunchDaemons/local.nut-driver.plist

until test -S "$STATE_DIR/usbhid-ups-basement_ups"; do
  sleep 0.1
done

sudo launchctl bootstrap system /Library/LaunchDaemons/local.nut-server.plist

until ups_status="$(upsc basement_ups@localhost ups.status 2>/dev/null)" &&
      [[ "$ups_status" != *WAIT* ]] &&
      [[ "$ups_status" == *OL* || "$ups_status" == *OB* ]]; do
  sleep 0.1
done

sudo launchctl bootstrap system /Library/LaunchDaemons/local.nut-monitor.plist

log_success 'NUT installation and initialization complete!'
