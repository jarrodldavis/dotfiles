create_distrobox sseedit

log_substep "Installing packages in Distrobox..."
distrobox enter sseedit -- sudo dnf install -y --refresh wine icoutils

log_substep "Installing Desktop Entry..."
symlink launch.bash ~/.local/bin/sseedit
symlink sseedit.desktop ~/.local/share/applications/sseedit.desktop
