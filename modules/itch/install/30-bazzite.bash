url="https://broth.itch.zone/install-itch/linux-appimage-amd64/LATEST/unpacked"

log_substep 'Downloading itch-setup...'
download_path="$(mktemp)"
curl -fLo "$download_path" "$url"

log_substep 'Installing itch...'
chmod +x "$download_path"
"$download_path" --silent

log_substep 'Making itch tray icon monochrome...'
symlink monochrome-tray.bash ~/.local/bin/itch-monochrome-tray
symlink monochrome-tray.service ~/.config/systemd/user/itch-monochrome-tray.service
symlink monochrome-tray.path ~/.config/systemd/user/itch-monochrome-tray.path
systemctl --verbose --user daemon-reload
systemctl --verbose --user enable --now itch-monochrome-tray.path
systemctl --verbose --user start itch-monochrome-tray.service
