# shellcheck shell=bash
# Dispatch to the platform-specific config. Sourced by init.sh.

case "$(uname -s)" in
    Darwin) . "$DINGZHI_PATH/configs/shell/mac.sh" ;;
    Linux)  . "$DINGZHI_PATH/configs/shell/linux.sh" ;;
esac
