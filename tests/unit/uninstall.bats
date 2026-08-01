#!/usr/bin/env bats

load ../helpers

UNINSTALLABLE="bat eza fd fzf ripgrep zoxide jq tlrc vifm cmake pandoc ffmpeg pngquant jpegoptim cheat"

setup() {
    setup_dingzhi_env
}

@test "the expected apps have uninstall scripts" {
    for a in $UNINSTALLABLE; do
        [ -f "$DINGZHI_PATH/apps/$a/uninstall.sh" ] || { echo "missing: $a"; return 1; }
    done
}

@test "uninstall scripts pass shellcheck" {
    for d in "$DINGZHI_PATH"/apps/*/; do
        [ -f "$d/uninstall.sh" ] || continue
        run shellcheck -s bash -e SC1091,SC2154 "$d/uninstall.sh"
        [ "$status" -eq 0 ] || { echo "shellcheck failed: $(basename "$d")"; echo "$output"; return 1; }
    done
}

@test "apps with config symlinks unlink them on removal" {
    grep -q 'unlink_managed' "$DINGZHI_PATH/apps/bat/uninstall.sh"
    grep -q 'unlink_managed' "$DINGZHI_PATH/apps/vifm/uninstall.sh"
    grep -q 'unlink_managed' "$DINGZHI_PATH/apps/cheat/uninstall.sh"
}

@test "no uninstall script exists for an app that cannot be cleanly removed" {
    # kitty, the shells, and git all leave state we will not delete on the
    # user's behalf: a login shell, terminfo, or the user's own gitconfig.
    for a in kitty zsh bash git neovim uv; do
        [ ! -f "$DINGZHI_PATH/apps/$a/uninstall.sh" ] \
            || { echo "unexpected uninstall.sh: $a"; return 1; }
    done
}

@test "install then uninstall then install leaves the app working" {
    source "$DINGZHI_PATH/lib/detect.sh"
    source "$DINGZHI_PATH/lib/ui.sh"
    source "$DINGZHI_PATH/lib/pkg.sh"
    source "$DINGZHI_PATH/lib/link.sh"
    sudo apt-get update -qq 2>/dev/null
    ( . "$DINGZHI_PATH/apps/jq/install.sh" ) >/dev/null 2>&1
    command -v jq >/dev/null
    ( . "$DINGZHI_PATH/apps/jq/uninstall.sh" ) >/dev/null 2>&1
    run command -v jq
    [ "$status" -ne 0 ]
    ( . "$DINGZHI_PATH/apps/jq/install.sh" ) >/dev/null 2>&1
    command -v jq >/dev/null
}
