eval "$(hub alias -s)"

eval "$(thefuck --alias)"

if brew command command-not-found-init > /dev/null; then eval "$(brew command-not-found-init)"; fi

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
