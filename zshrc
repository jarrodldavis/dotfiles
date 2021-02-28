#!/usr/bin/env zsh

# Ensure Homebrew-installed Zsh is used, if installed
homebrew_linux_zsh='/home/linuxbrew/.linuxbrew/bin/zsh'
if [ -f "$homebrew_linux_zsh" ] && [ "$SHELL" != "$homebrew_linux_zsh" ]; then
    exec env SHELL="$homebrew_linux_zsh" zsh -l
fi

# Initialize Homebrew
if [ "$(uname)" = "Linux" ]; then
    eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
fi

# Load Homebrew-installed completions
if [ "$(command -v brew)" ]; then
    FPATH="$(brew --prefix)/share/zsh/site-functions:$FPATH"
fi

# Completions
zstyle ':completion:*' completer _expand _complete _ignored _match _correct _approximate _prefix
zstyle ':completion:*' group-name ''
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list 'm:{[:lower:]}={[:upper:]}' 'm:{[:lower:]}={[:upper:]} m:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'm:{[:lower:]}={[:upper:]} m:{[:lower:][:upper:]}={[:upper:][:lower:]} r:|[._-]=** r:|=**' 'm:{[:lower:]}={[:upper:]} m:{[:lower:][:upper:]}={[:upper:][:lower:]} r:|[._-]=** r:|=** l:|=*'
zstyle ':completion:*' max-errors 3
zstyle ':completion:*' menu select=1
zstyle ':completion:*' preserve-prefix '//[^/]##/'
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' verbose true
zstyle :compinstall filename '~/.zshrc'

autoload -Uz compinit
compinit

# Additional Homebrew setup
if [ "$(command -v brew)" ]; then
    if [ "$(uname)" = "Darwin" ]; then
        HB_CNF_HANDLER="$(brew --prefix)/Homebrew/Library/Taps/homebrew/homebrew-command-not-found/handler.sh"
        source "$HB_CNF_HANDLER"
    fi

    # In order to use `code` as $EDITOR in dev containers, some environment variables from Visual Studio Code need to
    # be kept around. By default, Homebrew filters out all but a select set of environment variables. This overrides
    # that -- but only for the `brew edit` command, to minimize the potential for environment pollution.
    __brew_unfiltered_edit() {
        if [ "$1" = "edit" ]; then
            env HOMEBREW_NO_ENV_FILTERING=1 brew "$@"
        else
            brew "$@"
        fi
    }

    alias brew=__brew_unfiltered_edit
    compdef __brew_unfiltered_edit=brew

    if [ -f "$HOME/.homebrew-github-token.sh" ]; then
        source ~/.homebrew-github-token.sh
    fi
fi

# Set default editor
export EDITOR='vim'

# The Visual Studio Code Remote server's `code` (or `code-insiders`) binary is installed in various folders using
# unique identifiers, presumably for each installation or server connection. Even though Remote Development
# environments have a shim `code` binary, it still expects the real `code` or `code-insiders` binary to be present in
# $PATH, which is not true by default.
#
# Additionally, there's a different top-level directory for Remote - Containers (~/.vscode-server) and GitHub
# Codespaces (~/.vscode-remote). The (N) glob parameter allows globs that don't match anything to not cause an error
# and instead just be removed from the created array of paths.
if [ -d ~/.vscode-server/ ] || [ -d ~/.vscode-remote ]; then
    VSCODE_BIN_PATHS=(~/.vscode-server/bin/*/bin(N) ~/.vscode-remote/bin/*/bin(N))
    for VSCODE_BIN_PATH in $VSCODE_BIN_PATHS; do
      export PATH="$VSCODE_BIN_PATH:$PATH"
    done

    export EDITOR='code --wait'
fi

# custom functions
fpath+=~/.zshfunctions
autoload -Uz brewfile-diff
autoload -Uz ghq
autoload -Uz rebind-local
autoload -Uz upwork
autoload -Uz upgrade-backblaze
autoload -Uz vim-plugin

alias upwork="nocorrect upwork"
alias npm="nocorrect npm"

if [ "$(uname)" = "Darwin" ]; then
    autoload -Uz docker-destroy-devcontainer
    alias ddd="docker-destroy-devcontainer"
fi

if [ "$(command -v bat)" ]; then
    alias cat="bat"
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi

alias ls="ls -G"

# less
export LESS="-iJMRSw"

if ! [ "$(command -v delta)" ]; then
    export GIT_PAGER=less
fi

# starship prompt
if autoload -Uz async 2>/dev/null && [ "$(command -v starship)" ]; then
    async
    eval "$(starship init zsh)"
    export STARSHIP_CONFIG=~/.starship.toml
    PROMPT="$(PWD=~ starship prompt)"
fi

# override render function to account for slow performance in large git repositories
starship_render() {
    # render dimmed prompt to indicate render-in-progress
    PROMPT="$(echo "$PROMPT" | sed -E 's/%\{[^%]+%}//g')"
    PROMPT="$(printf '%%{\e[2m%%}%s%%{\e[0m%%}' "$PROMPT")"

    # Use length of jobstates array as number of jobs. Expansion fails inside
    # quotes so we set it here and then use the value later on.
    NUM_JOBS=$#jobstates

    # start async worker to render prompt without blocking input
    async_stop_worker starship_prompt
    async_start_worker starship_prompt
    async_register_callback starship_prompt starship_render_done
    async_job starship_prompt starship_render_worker
}

starship_render_worker() {
    PROMPT="$(starship prompt --keymap="${KEYMAP-}" --status=${STARSHIP_CMD_STATUS-"$STATUS"} --cmd-duration=${STARSHIP_DURATION-} --jobs="$NUM_JOBS")"
    print "$PROMPT"
}

starship_render_done() {
    PROMPT="$3"
    zle reset-prompt
}

# GPG pinentry
export GPG_TTY="$(tty)"

# GitHub Codespaces configures containers to automatically sign with GitHub's `web-flow` key, similar to editing files
# directly in the GitHub UI. If my own GPG key exists and is used to sign commits, the Codespaces configuration will
# cause those commits to be unverified since the committer won't match the GPG key.
if [ -f /.dockerenv ]; then
    if signing_key="$(git config --get user.signingkey)"; then
        if gpg --list-secret-keys "$signing_key" >/dev/null 2>&1; then
            unset GIT_COMMITTER_EMAIL GIT_COMMITTER_NAME

            if [ -d ./.git ]; then
                git config --local --unset gpg.program
            fi
        fi
    fi
fi

# hub
if [ "$(command -v hub)" ]; then
    alias git=hub
fi

# command editing options
setopt NO_CASE_GLOB
setopt AUTO_CD
setopt CORRECT
setopt CORRECT_ALL
export CORRECT_IGNORE_FILE='.*'

# tab completions
setopt COMPLETE_IN_WORD

# history options
HISTFILE=${ZDOTDIR:-$HOME}/.zsh_history
HISTSIZE=2000
SAVEHIST=1000

setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY

# key bindings and vim mode
export KEYTIMEOUT=1
bindkey -v

bindkey '^[[A' up-line-or-search
bindkey '^[[B' down-line-or-search

bindkey '^P' up-history
bindkey '^N' down-history
bindkey '^?' backward-delete-char
bindkey '^h' backward-delete-char
bindkey '^w' backward-kill-word
bindkey '^r' history-incremental-search-backward
bindkey -M vicmd 'j' down-line-or-search
bindkey -M vicmd 'k' up-line-or-search
bindkey -M vicmd '?' history-incremental-search-backward
bindkey -M vicmd '/' history-incremental-search-forward

autoload -Uz surround
zle -N delete-surround surround
zle -N change-surround surround
zle -N add-surround surround
bindkey -M vicmd cs change-surround
bindkey -M vicmd ds delete-surround
bindkey -M vicmd ys add-surround
bindkey -M vicmd S add-surround
