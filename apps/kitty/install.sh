#!/usr/bin/env bash
# group: terminal
# The upstream installer already handles the no-root case, so it is used on
# every backend rather than going through pkg_install.
if command -v kitty >/dev/null 2>&1 || [ -d "$HOME/.local/kitty.app" ]; then
    skip "kitty already installed"
else
    step "installing kitty"
    curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin launch=n
fi

if [ -d "$HOME/.local/kitty.app" ]; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$HOME/.local/kitty.app/bin/kitty" "$HOME/.local/bin/kitty"
    ln -sf "$HOME/.local/kitty.app/bin/kitten" "$HOME/.local/bin/kitten"

    # Make xterm-kitty terminfo available to everything else: vim, and any host
    # you ssh into from a kitty window.
    if [ -d "$HOME/.local/kitty.app/lib/kitty/terminfo" ]; then
        mkdir -p "$HOME/.terminfo"
        cp -R "$HOME/.local/kitty.app/lib/kitty/terminfo/." "$HOME/.terminfo/"
    fi
fi

manage_symlink "$DINGZHI_PATH/configs/kitty" "$HOME/.config/kitty" "kitty config"
