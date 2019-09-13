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
  EXIT_CODES=${PIPESTATUS[*]}      # save now before value is reset by subsequent commands

  local PS1_COLOR_START='\e[0;90m' # dark gray
  local PS1_USER_INFO='\u@\h:\w'   # user@host:path
  local PS1_DATE='[\d \@]'         # [date 12-hour-time]

  # exit status
  local PS1_CMD_COLOR_START
  local PS1_CMD_CODE

  for CODE in "${EXIT_CODES[@]}"; do
    if [ "$CODE" != 0 ]; then
      PS1_CMD_COLOR_START='\e[31m' # red
    fi
  done
  PS1_CMD_CODE=${EXIT_CODES// / | }

  local PS1_CMD="${PS1_CMD_COLOR_START}exit status: ${PS1_CMD_CODE}${PS1_COLOR_START}"

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
    PS1_SHELL_COLOR_START='\e[33m' # yellow
  fi

  if [ ! "$(command -v brew)" ]; then
    PS1_SHELL_END=" (no homebrew)"
    PS1_SHELL_COLOR_START='\e[31m' # red
  elif [ "$BASH" != "$(brew --prefix)/bin/bash" ]; then
    PS1_SHELL_END=" (system-provided)"
    PS1_SHELL_COLOR_START='\e[31m' # red
  elif [ "$BASH" != "$(command -v bash)" ]; then
    PS1_SHELL_END=" (non-default in \$PATH)"
    PS1_SHELL_COLOR_START='\e[31m' # red
  elif [ "$BASH_VERSION" != "$(bash -c 'echo $BASH_VERSION')" ]; then
    PS1_SHELL_END=" (out-of-date)"
    PS1_SHELL_COLOR_START='\e[31m' # red
  fi

  local PS1_SHELL="${PS1_SHELL_COLOR_START}${PS1_SHELL_START}${PS1_SHELL_END}${PS1_COLOR_START}"

  # assembled prompt
  echo -e "${PS1_COLOR_START}\r\n${PS1_DATE}\r\n${PS1_CMD}\r\n${PS1_SHELL}\r\n${PS1_USER_INFO}"
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
