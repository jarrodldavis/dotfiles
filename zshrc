#!/usr/bin/env zsh

# Homebrew
if [ -f "$HOME/.homebrew-github-token.sh" ]; then
    source ~/.homebrew-github-token.sh
fi

if [ "$(command -v brew)" ]; then
  FPATH="$(brew --prefix)/share/zsh/site-functions:$FPATH"


  if [ "$(uname)" = "Darwin" ]; then
    HB_CNF_HANDLER="$(brew --prefix)/Homebrew/Library/Taps/homebrew/homebrew-command-not-found/handler.sh"
    source "$HB_CNF_HANDLER"
  fi
fi

if [ "$(uname)" = "Linux" ]; then
    eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)

    # https://github.com/Homebrew/linuxbrew-core/issues/21601
    export HOMEBREW_PATCHELF_RB_WRITE=1

    # ensure Homebrew-installed Zsh is used, if installed
    homebrew_zsh="$(command -v zsh)"
    if [ "$SHELL" != "$homebrew_zsh" ]; then
        exec env SHELL="$homebrew_zsh" zsh
    fi
fi

# Set default editor
export EDITOR='vim'

# custom functions
fpath+=~/.zshfunctions
autoload -Uz ghq
autoload -Uz rebind-local
autoload -Uz upwork
autoload -Uz upgrade-backblaze
autoload -Uz vim-plugin

alias upwork="nocorrect upwork"
alias npm="nocorrect npm"

if [ "$(command -v bat)" ]; then
    alias cat="bat"
fi

alias ls="ls -G"

# less
export LESS="-RS"

# async
fpath+=~/.zshasync
autoload -Uz async
async

# starship prompt
if [ "$(command -v starship)" ]; then
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

# hub
if [ "$(command -v hub)" ]; then
    alias git=hub
fi

# man pager
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

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

# The following lines were added by compinstall

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

# End of lines added by compinstall
