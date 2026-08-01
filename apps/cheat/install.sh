#!/usr/bin/env bash
# group: misc
# Not in Ubuntu's repositories, so apt falls back to the release binary.
if pkg_installed cheat; then
    skip "cheat already installed"
elif [ "$DINGZHI_BACKEND" = "apt" ]; then
    pkg_install_release cheat
else
    pkg_install cheat
fi

manage_symlink "$DINGZHI_PATH/configs/cheat/conf.yml" \
    "$HOME/.config/cheat/conf.yml" "cheat config"

CHEAT_DIR="$HOME/.config/cheat/cheatsheets/community"
if [ -d "$CHEAT_DIR" ]; then
    skip "community cheatsheets already present"
else
    step "cloning community cheatsheets"
    mkdir -p "$(dirname "$CHEAT_DIR")"
    git clone -q --depth=1 https://github.com/cheat/cheatsheets.git "$CHEAT_DIR"
fi
