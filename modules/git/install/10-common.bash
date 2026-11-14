log_substep 'Linking Git configuration...'
symlink ../../scripts/maintenance/pre-commit.bash ~/.dotfiles/.git/hooks/pre-commit

# Isolate managed Git configuration from machine-specific settings.
symlink base.gitconfig "${XDG_CONFIG_HOME:-$HOME/.config}/git/config"
touch ~/.gitconfig

symlink ssh.gitconfig ~/.gitconfigs/ssh.gitconfig
symlink gitignore ~/.gitignore
