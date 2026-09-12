#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

log_step 'Configuring 1Password SSH Agent...'

cat > ~/Library/LaunchAgents/com.1password.SSH_AUTH_SOCK.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
        <key>Label</key>
        <string>com.1password.SSH_AUTH_SOCK</string>
        <key>ProgramArguments</key>
        <array>
            <string>/bin/sh</string>
            <string>-c</string>
            <string>/bin/ln -sf $HOME/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock \$SSH_AUTH_SOCK</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
    </dict>
</plist>
EOF

if launchctl list | grep -q com.1password.SSH_AUTH_SOCK ; then
    launchctl unload -w ~/Library/LaunchAgents/com.1password.SSH_AUTH_SOCK.plist
fi

launchctl load -w ~/Library/LaunchAgents/com.1password.SSH_AUTH_SOCK.plist
