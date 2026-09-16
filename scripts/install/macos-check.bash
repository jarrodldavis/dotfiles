#!/usr/bin/env bash
set -euo pipefail

PATH="/bin:$PATH" /usr/bin/env bash --version
PATH="/bin:$PATH" ~/.dotfiles/install.bash
