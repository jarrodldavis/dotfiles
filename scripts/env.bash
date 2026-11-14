case "$(realpath "$0" 2>/dev/null)" in
    "$(realpath "$HOME/.dotfiles")"/*)
        # shellcheck source=scripts/helpers.bash
        source "$HOME/.dotfiles/scripts/helpers.bash"
        ;;
esac
