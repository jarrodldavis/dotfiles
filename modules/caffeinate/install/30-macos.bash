SERVICE_NAME=local.caffeinate
DOMAIN_TARGET="gui/$(id -u)"
SERVICE_TARGET="$DOMAIN_TARGET/$SERVICE_NAME"
PLIST="$HOME/Library/LaunchAgents/$SERVICE_NAME.plist"
BINARY="$HOME/.local/bin/caffeinate-menubar"

log_substep 'Compiling Caffeinate menu bar utility...'
TEMP_DIR="$(mktemp -d "$HOME/.local/bin/.caffeinate-menubar.XXXXXX")"
TEMP_BINARY="$TEMP_DIR/caffeinate-menubar"
trap 'rm -rf "$TEMP_DIR"' EXIT
swiftc -O "$module_dir/caffeinate.swift" -o "$TEMP_BINARY"
chmod 755 "$TEMP_BINARY"

if cmp -s "$TEMP_BINARY" "$BINARY"; then
    log_info 'Caffeinate menu bar utility is up to date.'
    exit 0
fi

log_substep 'Installing Caffeinate LaunchAgent...'
mkdir -pv "$HOME/.local/bin" "$HOME/Library/LaunchAgents"
sed "s|REPLACE_WITH_HOME|$HOME|g" "$module_dir/$SERVICE_NAME.plist" > "$PLIST"
plutil -lint "$PLIST"

if launchctl print "$SERVICE_TARGET" >/dev/null 2>&1; then
    launchctl bootout "$DOMAIN_TARGET" "$PLIST"
fi

mv -f "$TEMP_BINARY" "$BINARY"
launchctl bootstrap "$DOMAIN_TARGET" "$PLIST"
