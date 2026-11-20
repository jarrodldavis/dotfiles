log_substep 'Installing VSCode Insiders extensions...'
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
ln -s "$(command -v code-insiders)" "$tmpdir/code"
PATH="$tmpdir:$PATH" code --version
grep '^vscode' ~/.Brewfile | PATH="$tmpdir:$PATH"  brew bundle install --file /dev/stdin --verbose
