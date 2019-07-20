#! /usr/bin/env bash

function __run_command() {
  sudo -u jarrodldavis -- bash -l -c "reattach-to-user-namespace $*" || exit $?
}

__run_command update-dotbot-lists
__run_command export-user-defaults
__run_command export-user-defaults --private
