SERVICE_NAME=local.caffeinate
DOMAIN_TARGET="gui/$(id -u)"
SERVICE_TARGET="$DOMAIN_TARGET/$SERVICE_NAME"
PLIST="$HOME/Library/LaunchAgents/$SERVICE_NAME.plist"
BINARY="$HOME/.local/bin/caffeinate-menubar"

mkdir -pv "${BINARY%/*}"

log_substep 'Compiling Caffeinate menu bar utility...'
TEMP_DIR="$(mktemp -d "$HOME/.local/bin/.caffeinate-menubar.XXXXXX")"
TEMP_BINARY="$TEMP_DIR/caffeinate-menubar"
TEMP_PLIST="$TEMP_DIR/$SERVICE_NAME.plist"
trap 'rm -rf "$TEMP_DIR"' EXIT
swiftc -O "$module_dir/caffeinate.swift" -o "$TEMP_BINARY"
chmod 755 "$TEMP_BINARY"

sed "s|REPLACE_WITH_HOME|$HOME|g" "$module_dir/$SERVICE_NAME.plist" > "$TEMP_PLIST"

binary_current=false
if [[ -x "$BINARY" ]] && cmp -s "$TEMP_BINARY" "$BINARY"; then
    binary_current=true
fi

plist_current=false
if cmp -s "$TEMP_PLIST" "$PLIST"; then
    plist_current=true
fi

service_loaded=false
if launchctl print "$SERVICE_TARGET" >/dev/null 2>&1; then
    service_loaded=true
fi

if "$binary_current" && "$plist_current" && "$service_loaded"; then
    log_info 'Caffeinate menu bar utility is up to date.'
    exit 0
fi

log_substep 'Installing Caffeinate LaunchAgent...'
plutil -lint "$TEMP_PLIST"
mkdir -pv "${PLIST%/*}"

if "$service_loaded"; then
    launchctl bootout "$SERVICE_TARGET"
fi

mv -f "$TEMP_BINARY" "$BINARY"
mv -f "$TEMP_PLIST" "$PLIST"

launchctl bootstrap "$DOMAIN_TARGET" "$PLIST"
