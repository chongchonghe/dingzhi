#!/usr/bin/env bats

load ../helpers

setup() {
    setup_dingzhi_env
}

@test "install.sh passes shellcheck" {
    run shellcheck -s bash -e SC1090,SC1091 "$DINGZHI_PATH/install.sh"
    [ "$status" -eq 0 ] || { echo "$output"; return 1; }
}

@test "dingzhi_app_group reads the header" {
    source "$DINGZHI_PATH/install.sh" --lib-only
    run dingzhi_app_group bat
    [ "$output" = "core" ]
}

@test "dingzhi_apps_in_group lists the media group only" {
    source "$DINGZHI_PATH/install.sh" --lib-only
    run dingzhi_apps_in_group media
    [[ "$output" == *pandoc* ]]
    [[ "$output" == *ffmpeg* ]]
    [[ "$output" != *bat* ]]
}

@test "dingzhi_all_apps lists every app exactly once" {
    source "$DINGZHI_PATH/install.sh" --lib-only
    run bash -c "source '$DINGZHI_PATH/install.sh' --lib-only && dingzhi_all_apps | sort | uniq -d"
    [ -z "$output" ]
    run bash -c "source '$DINGZHI_PATH/install.sh' --lib-only && dingzhi_all_apps | wc -l"
    [ "$output" -eq 33 ]
}

@test "every app belongs to exactly one group, and the groups partition the apps" {
    source "$DINGZHI_PATH/install.sh" --lib-only
    total=0
    for g in core terminal editors git filemanagers shell dev media misc; do
        n="$(dingzhi_apps_in_group "$g" | wc -l)"
        total=$((total + n))
    done
    [ "$total" -eq 33 ] || { echo "groups cover $total apps, expected 33"; return 1; }
}

@test "--lib-only installs nothing" {
    source "$DINGZHI_PATH/install.sh" --lib-only
    run command -v lazygit
    [ "$status" -ne 0 ]
}

@test "--lib-only still loads the libraries" {
    source "$DINGZHI_PATH/install.sh" --lib-only
    [ -n "$DINGZHI_BACKEND" ]
    run type -t pkg_install
    [ "$output" = "function" ]
    run type -t manage_symlink
    [ "$output" = "function" ]
}
