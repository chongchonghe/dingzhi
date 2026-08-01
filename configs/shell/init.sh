# shellcheck shell=bash
# dingzhi shell entry point. One line in ~/.zshrc or ~/.bashrc sources this.
#
# Must be valid under both bash and zsh: no bashism zsh rejects, no zsh-ism
# bash rejects.

# Locate the dingzhi checkout from this file, under either shell.
if [ -n "${BASH_SOURCE[0]:-}" ]; then
    _dingzhi_self="${BASH_SOURCE[0]}"
elif [ -n "${ZSH_VERSION:-}" ]; then
    _dingzhi_self="${(%):-%N}"
else
    _dingzhi_self="$0"
fi
DINGZHI_PATH="$(cd "$(dirname "$_dingzhi_self")/../.." && pwd)"
export DINGZHI_PATH
unset _dingzhi_self

. "$DINGZHI_PATH/configs/shell/env.sh"
. "$DINGZHI_PATH/configs/shell/aliases.sh"
. "$DINGZHI_PATH/configs/shell/functions.sh"
. "$DINGZHI_PATH/configs/shell/platform.sh"

if command -v zoxide >/dev/null 2>&1; then
    if [ -n "${ZSH_VERSION:-}" ]; then
        eval "$(zoxide init zsh)"
    else
        eval "$(zoxide init bash)"
    fi
fi
