#!/usr/bin/env zsh

# Homebrew
if [ -f "$HOME/.homebrew-github-token.sh" ]; then
    source ~/.homebrew-github-token.sh
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

alias cat="bat"
alias ls="ls -G"

# less
export LESS="-RS"

# async
autoload -Uz async
async

# starship prompt
autoload -Uz starship-init
starship-init
export STARSHIP_CONFIG=~/.starship.toml

# hub
alias git=hub

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
