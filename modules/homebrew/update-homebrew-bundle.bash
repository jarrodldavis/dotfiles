log_step 'Updating Homebrew Bundle...'

brew bundle dump    --global --force --verbose
brew bundle install --global --force --verbose
brew bundle cleanup --global --force --verbose
