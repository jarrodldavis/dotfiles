create_distrobox discord

log_substep "Setting up Discord repository..."
distrobox enter discord -- "$module_dir/setup-repo.bash"

log_substep "Installing Discord in Distrobox..."
distrobox enter discord -- sudo dnf install -y --refresh discord

log_substep "Configuring autostart..."
distrobox enter discord -- distrobox-export --app /usr/share/applications/discord.desktop
symlink discord-distrobox.bash ~/.local/bin/discord-distrobox
copy discord-discord.desktop ~/.local/share/applications/discord-discord.desktop
copy discord-minimized.desktop ~/.config/autostart/discord-minimized.desktop
