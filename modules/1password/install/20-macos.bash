SERVICE_NAME="com.1password.SSH_AUTH_SOCK"
PLIST=~/Library/LaunchAgents/"$SERVICE_NAME".plist
DOMAIN_TARGET="gui/$(id -u)"
SERVICE_TARGET="$DOMAIN_TARGET/$SERVICE_NAME"

log_substep 'Installing 1Password SSH agent LaunchAgent...'

cat "$module_dir/com.1password.SSH_AUTH_SOCK.plist" | \
    sed \
    -e "s|REPLACE_WITH_HOME|$HOME|g" \
    -e "s/REPLACE_WITH_SERVICE_NAME/$SERVICE_NAME/g" \
    | tee "$PLIST" > /dev/null

plutil -lint "$PLIST"

mkdir -pv ~/Library/Logs/1Password

if launchctl print "$SERVICE_TARGET" >/dev/null 2>&1; then
    launchctl bootout "$DOMAIN_TARGET" "$PLIST"
fi

launchctl bootstrap "$DOMAIN_TARGET" "$PLIST"
