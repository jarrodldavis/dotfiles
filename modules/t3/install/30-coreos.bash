log_substep "Collecting library paths..."
formulas=(at-spi2-core libxcomposite libxdamage)
lib_paths=()

log_info "Brew formulas:"
brew info "${formulas[@]}"

for formula in "${formulas[@]}"; do
    lib_paths+=("$(brew --prefix "$formula")/lib"/*.so)
done

log_info "Discovered library paths:"
for path in "${lib_paths[@]}"; do
    echo "  - $path"
done

log_substep "Creating symbolic links for library paths..."
for path in "${lib_paths[@]}"; do
    symlink "$path" ~/.t3/tools/t3-browser-libs/
done

log_substep 'Injecting Bash shell configuration block...'
ensure_source_block "$HOME/.bashrc" rc.coreos.t3 rc.coreos.t3.bash
