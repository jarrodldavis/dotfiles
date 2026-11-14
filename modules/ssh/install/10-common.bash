log_substep 'Linking SSH configuration...'
symlink base.sshconfig ~/.ssh/config
symlink config.local.d ~/.ssh/config.local.d
symlink allowed_signers ~/.ssh/allowed_signers
