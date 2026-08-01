#!/usr/bin/env bash
# group: misc
# cheat itself is a Go binary with no packaging story we rely on; what dingzhi
# ships is the config and the community cheatsheets.
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
