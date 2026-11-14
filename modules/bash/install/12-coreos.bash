log_substep 'Injecting CoreOS shell configuration blocks...'

ensure_source_block "$HOME/.bashrc" rc.coreos rc.coreos.bash
