#! /usr/bin/env bash

# Environment variables
export EDITOR=vim
export PATH=$HOME/.dotfiles-scripts:$HOME/.dotfiles-scripts/bash:$PATH
export PATH="$HOME/.cargo/bin:$PATH"

# Bash options
# shellcheck disable=SC2143
if [ "$(shopt -p | grep -q globstar)" ]; then shopt -s globstar; fi

# Check for updated bash
echo "Welcome to bash v$BASH_VERSION"

# Prompt customization
function __prompt_command_start() {
  local PS1_CLEAR_LINE='\r'             # ensure prompt always starts at the beginning
  local PS1_COLOR_START='\e[0;37m\e[2m' # dim text + light gray
  local PS1_USER_INFO='\u@\h:\w'        # user@host:path
  local PS1_DATE='[\d \@]'              # [date 12-hour-time]

  # shell version info
  local PS1_SHELL_START
  local PS1_SHELL_END
  local PS1_SHELL_COLOR_START

  if [ "$0" == "-bash" ]; then
    # login shell
    PS1_SHELL_START="${BASH} v\V"
  else
    # sub-shell
    PS1_SHELL_START="${SHELL} > ${BASH} \V"
    PS1_SHELL_COLOR_START='\e[0;33m' # yellow
  fi

  if [ ! "$(command -v brew)" ]; then
    PS1_SHELL_END=" (no homebrew)"
    PS1_SHELL_COLOR_START='\e[0;31m' # red
  elif [ "$BASH" != "$(brew --prefix)/bin/bash" ]; then
    PS1_SHELL_END=" (system-provided)"
    PS1_SHELL_COLOR_START='\e[0;31m' # red
  elif [ "$BASH" != "$(command -v bash)" ]; then
    PS1_SHELL_END=" (non-default in \$PATH)"
    PS1_SHELL_COLOR_START='\e[0;31m' # red
  elif [ "$BASH_VERSION" != "$(bash -c 'echo $BASH_VERSION')" ]; then
    PS1_SHELL_END=" (out-of-date)"
    PS1_SHELL_COLOR_START='\e[0;31m' # red
  fi

  local PS1_SHELL="${PS1_SHELL_COLOR_START}${PS1_SHELL_START}${PS1_SHELL_END}${PS1_COLOR_START}"

  echo "${PS1_CLEAR_LINE}${PS1_COLOR_START}${PS1_DATE} ${PS1_SHELL} ${PS1_USER_INFO}"
}

function __prompt_command_end() {
  printf "\e[m\n$ "
}

function __prompt_command_base() {
  PS1="$(__prompt_command_start) $(__prompt_command_end)"
}

if [ "$TERM_PROGRAM" == 'Apple_Terminal' ]; then
  PROMPT_COMMAND='__prompt_command_base'
fi
