#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

SERVICE_NAME=local.caffeinate
DOMAIN_TARGET="gui/$(id -u)"
SERVICE_TARGET="$DOMAIN_TARGET/$SERVICE_NAME"
PLIST="$HOME/Library/LaunchAgents/$SERVICE_NAME.plist"
BINARY="$HOME/.local/bin/caffeinate-menubar"

log_substep 'Compiling Caffeinate menu bar utility...'
mkdir -pv "$HOME/.local/bin" "$HOME/Library/LaunchAgents"
# Compile separately so a failed build does not replace a working executable.
TEMP_BINARY=$(mktemp "$HOME/.local/bin/.caffeinate-menubar.XXXXXX")
trap 'rm -f "$TEMP_BINARY"' EXIT
swiftc -O "$module_dir/caffeinate.swift" -o "$TEMP_BINARY"
chmod 755 "$TEMP_BINARY"

log_substep 'Installing Caffeinate LaunchAgent...'
sed "s|REPLACE_WITH_HOME|$HOME|g" "$module_dir/$SERVICE_NAME.plist" > "$PLIST"
plutil -lint "$PLIST"

if launchctl print "$SERVICE_TARGET" >/dev/null 2>&1; then
    launchctl bootout "$DOMAIN_TARGET" "$PLIST"
fi

mv -f "$TEMP_BINARY" "$BINARY"
launchctl bootstrap "$DOMAIN_TARGET" "$PLIST"
