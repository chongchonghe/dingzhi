#!/usr/bin/env bash
# group: shell
case " ${DINGZHI_SHELLS:-zsh} " in
    *" zsh "*) _dingzhi_want=1 ;;
    *) _dingzhi_want=0 ;;
esac

if [ "$_dingzhi_want" != "1" ]; then
    skip "zsh not selected"
    unset _dingzhi_want
    # `return` when sourced by install.sh, `exit` when run directly.
    # shellcheck disable=SC2317  # the exit is reached only when executed
    return 0 2>/dev/null || exit 0
fi
unset _dingzhi_want

pkg_install zsh

OMZ="$HOME/.oh-my-zsh"
if [ -d "$OMZ" ]; then
    skip "oh-my-zsh already installed"
else
    step "installing oh-my-zsh"
    # KEEP_ZSHRC matters: the installer would otherwise replace a .zshrc that
    # may already source dingzhi.
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

P10K="$OMZ/custom/themes/powerlevel10k"
if [ -d "$P10K" ]; then
    skip "powerlevel10k already installed"
else
    step "installing powerlevel10k"
    git clone -q --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K"
fi

inject_line "$HOME/.zshrc" "dingzhi/configs/shell/init.sh" \
    "source \"$DINGZHI_PATH/configs/shell/init.sh\"" "$HOME/.zshrc"
