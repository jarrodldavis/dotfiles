#!/usr/bin/env zsh
# shellcheck disable=all

set -euo pipefail

user=$(id -un)
group=$(id -gn)

plist_replace() {
    local key=$1
    local value=$2
    plutil -replace $key -string $value - -o -
}

# initialize Home Assistant password
ha_password=$(openssl rand -hex 24)
sed -i '' "s/REPLACE_WITH_HA_PASSWORD/$ha_password/g" /opt/homebrew/etc/nut/upsd.users

# initialize UPSMON
upsmon_password="$(openssl rand -hex 24)"
sed -i '' "s/REPLACE_WITH_UPSMON_PASSWORD/$upsmon_password/g" /opt/homebrew/etc/nut/upsd.users

upsmon_password=$(
    awk '
      /^\[upsmon\]/ { flag=1; next }
      /^\[/         { flag=0 }
      flag && /^[[:space:]]*password[[:space:]]*=/ { print $3 }
    ' /opt/homebrew/etc/nut/upsd.users
)

cp -vf ~/.dotfiles/configs/nut/upsmon.conf /opt/homebrew/etc/nut/upsmon.conf
sed -i '' \
    -e "s/REPLACE_WITH_UPSMON_PASSWORD/$upsmon_password/g" \
    -e "s/REPLACE_WITH_UPSMON_USER/$user/g" \
    /opt/homebrew/etc/nut/upsmon.conf

# configure NUT driver daemon
cat ~/.dotfiles/configs/nut/local.nut-driver.plist | \
    # plist_replace UserName $user | plist_replace GroupName $group | \
    sudo tee /Library/LaunchDaemons/local.nut-driver.plist > /dev/null
sudo chown -v root:wheel /Library/LaunchDaemons/local.nut-driver.plist
sudo chmod -v 644 /Library/LaunchDaemons/local.nut-driver.plist
plutil -lint /Library/LaunchDaemons/local.nut-driver.plist

# configure NUT server daemon
cat ~/.dotfiles/configs/nut/local.nut-server.plist | \
    plist_replace UserName $user | plist_replace GroupName $group | \
    sudo tee /Library/LaunchDaemons/local.nut-server.plist > /dev/null
sudo chown -v root:wheel /Library/LaunchDaemons/local.nut-server.plist
sudo chmod -v 644 /Library/LaunchDaemons/local.nut-server.plist
plutil -lint /Library/LaunchDaemons/local.nut-server.plist

# configure NUT monitor daemon
cat ~/.dotfiles/configs/nut/local.nut-monitor.plist | \
    # plist_replace UserName $user | plist_replace GroupName $group | \
    sudo tee /Library/LaunchDaemons/local.nut-monitor.plist > /dev/null
sudo chown -v root:wheel /Library/LaunchDaemons/local.nut-monitor.plist
sudo chmod -v 644 /Library/LaunchDaemons/local.nut-monitor.plist
plutil -lint /Library/LaunchDaemons/local.nut-monitor.plist

# initialize logs
mkdir -pv /opt/homebrew/var/log
touch /opt/homebrew/var/log/nut-{driver,server,monitor}.log

# set config permissions
chmod -v 600 /opt/homebrew/etc/nut/upsd.{conf,users}
sudo chown root:$group /opt/homebrew/etc/nut/upsmon.conf
sudo chmod 640 /opt/homebrew/etc/nut/upsmon.conf

# initialize state
mkdir -pv /opt/homebrew/var/state/ups
chmod -v 700 /opt/homebrew/var/state/ups

# initialize run
mkdir -p /opt/homebrew/var/run
sudo chown root:$group /opt/homebrew/var/run
sudo chmod 775 /opt/homebrew/var/run

# initialize NUT daemons
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

until test -S /opt/homebrew/var/state/ups/usbhid-ups-basement_ups; do
  sleep 0.1
done

sudo launchctl bootstrap system /Library/LaunchDaemons/local.nut-server.plist

until ups_status="$(upsc basement_ups@localhost ups.status 2>/dev/null)" &&
      [[ "$ups_status" != *WAIT* ]] &&
      [[ "$ups_status" == *OL* || "$ups_status" == *OB* ]]; do
  sleep 0.1
done

sudo launchctl bootstrap system /Library/LaunchDaemons/local.nut-monitor.plist

launchctl print system/local.nut-server
launchctl print system/local.nut-driver
