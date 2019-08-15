#! /usr/bin/env bash

# Carbon Copy Cloner preflight script for Hourly Criticals

function __run_command() {
  sudo -u jarrodldavis -- bash -l -c "reattach-to-user-namespace $*" || exit $?
}

__run_command dotbot-update
__run_command export-user-defaults
__run_command export-user-defaults --private
