#!/usr/bin/env zsh
set -euo pipefail

defaults write org.xquartz.X11 nolisten_tcp -bool false
defaults write org.xquartz.X11 no_auth -bool false
defaults write org.xquartz.X11 enable_iglx -bool true

cat << EOF > ~/Library/LaunchAgents/org.xquartz.display.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
        <key>Label</key>
        <string>org.xquartz.display</string>
        <key>ProgramArguments</key>
        <array>
            <string>launchctl</string>
            <string>setenv</string>
            <string>DISPLAY</string>
            <string>:0</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
    </dict>
</plist>
EOF

if launchctl list | grep -q org.xquartz.display ; then
    launchctl unload -w ~/Library/LaunchAgents/org.xquartz.display.plist
fi

launchctl load -w ~/Library/LaunchAgents/org.xquartz.display.plist
