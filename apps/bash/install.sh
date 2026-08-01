#!/usr/bin/env bash
# group: shell
case " ${DINGZHI_SHELLS:-zsh} " in
    *" bash "*) _dingzhi_want=1 ;;
    *) _dingzhi_want=0 ;;
esac

if [ "$_dingzhi_want" != "1" ]; then
    skip "bash not selected"
    unset _dingzhi_want
    # `return` when sourced by install.sh, `exit` when run directly.
    # shellcheck disable=SC2317  # the exit is reached only when executed
    return 0 2>/dev/null || exit 0
fi
unset _dingzhi_want

# bash is present on every supported platform; only configuration is needed.
inject_line "$HOME/.bashrc" "dingzhi/configs/shell/init.sh" \
    "source \"$DINGZHI_PATH/configs/shell/init.sh\"" "$HOME/.bashrc"
