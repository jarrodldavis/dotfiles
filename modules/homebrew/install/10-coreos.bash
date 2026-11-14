log_substep 'Linking CoreOS Homebrew configuration...'

symlink coreos.Brewfile ~/.Brewfile
symlink coreos.Brewfile ~/.homebrew/Brewfile

# workaround for Homebrew's poor support for symlinked `/home` directories
mkdir -pv "$(brew --prefix)/lib/docker/cli-plugins"
