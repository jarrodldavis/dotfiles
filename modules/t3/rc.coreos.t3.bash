case ":${LD_LIBRARY_PATH:-}:" in
    *":\$ORIGIN/../../../t3-browser-libs:"*) ;;
    *) export LD_LIBRARY_PATH="\$ORIGIN/../../../t3-browser-libs${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" ;;
esac
