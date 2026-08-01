#!/usr/bin/env bats

load ../helpers

setup() {
    setup_dingzhi_env
}

@test "every expected config directory exists" {
    for d in kitty nvim tmux yazi vifm bat lazygit cheat git shell vim; do
        [ -d "$DINGZHI_PATH/configs/$d" ] || { echo "missing configs/$d"; return 1; }
    done
}

@test "gitconfig has no hardcoded user identity" {
    run grep -E '^[[:space:]]*(name|email)[[:space:]]*=' "$DINGZHI_PATH/configs/git/gitconfig"
    [ "$status" -ne 0 ]
}

@test "gitconfig includes gitconfig.local" {
    grep -q 'gitconfig.local' "$DINGZHI_PATH/configs/git/gitconfig"
}

@test "gitconfig does not reference a personal checkout path" {
    run grep -E 'git/catppuccin|Users/' "$DINGZHI_PATH/configs/git/gitconfig"
    [ "$status" -ne 0 ]
}

@test "gitconfig is valid and readable by git" {
    run git config --file "$DINGZHI_PATH/configs/git/gitconfig" --list
    [ "$status" -eq 0 ]
}

@test "the delta theme is vendored" {
    [ -f "$DINGZHI_PATH/themes/catppuccin/delta.gitconfig" ]
    grep -q 'catppuccin-mocha' "$DINGZHI_PATH/themes/catppuccin/delta.gitconfig"
}

@test "no config file contains a personal absolute path" {
    run grep -rIlE 'Users/(cche|u1149259|chongchonghe)|/home/(cche|chong)' "$DINGZHI_PATH/configs/"
    [ "$status" -ne 0 ] || { echo "$output"; return 1; }
}

@test "no config selects a light theme or the toggle sentinel" {
    # Note this looks for light theme *selection*. lazygit's `lightTheme: false`
    # is the correct dark setting and must not trip the guard.
    run grep -rIlE 'catppuccin-latte|catppuccin_flavor "latte"|\.lighttheme|\.darktheme|ToggleTheme' \
        "$DINGZHI_PATH/configs/"
    [ "$status" -ne 0 ] || { echo "$output"; return 1; }
}

@test "yazi uses catppuccin mocha, not another flavor" {
    grep -qE '^\s*dark\s*=\s*"catppuccin-mocha"' "$DINGZHI_PATH/configs/yazi/theme.toml"
    run grep -E '^\s*dark\s*=\s*"dracula"' "$DINGZHI_PATH/configs/yazi/theme.toml"
    [ "$status" -ne 0 ]
}

@test "nvim pins catppuccin mocha with no toggle command" {
    run grep -E 'ToggleTheme|toggle_theme' "$DINGZHI_PATH/configs/nvim/lua/plugins/colorscheme.lua"
    [ "$status" -ne 0 ]
    grep -q 'catppuccin-mocha' "$DINGZHI_PATH/configs/nvim/lua/plugins/colorscheme.lua"
}

@test "tmux pins the mocha flavor unconditionally" {
    grep -qE '@catppuccin_flavor "mocha"' "$DINGZHI_PATH/configs/tmux/tmux.conf"
    run grep -E 'if-shell.*lighttheme' "$DINGZHI_PATH/configs/tmux/tmux.conf"
    [ "$status" -ne 0 ]
}

@test "no stale backup or variant config files were carried over" {
    run bash -c "find '$DINGZHI_PATH/configs' \\( -name '*.bk' -o -name '*.trash' \\
        -o -name '*.orig' -o -name '*-before-*' -o -name '*.v2' -o -name '.DS_Store' \\) -print"
    [ -z "$output" ] || { echo "$output"; return 1; }
}

@test "the global gitignore is present" {
    [ -f "$DINGZHI_PATH/configs/git/gitignore_global" ]
}
