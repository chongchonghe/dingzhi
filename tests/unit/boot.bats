#!/usr/bin/env bats

load ../helpers

setup() {
    setup_dingzhi_env
}

@test "boot.sh passes shellcheck" {
    run shellcheck -s bash -e SC1090,SC1091 "$DINGZHI_PATH/boot.sh"
    [ "$status" -eq 0 ] || { echo "$output"; return 1; }
}

@test "boot.sh honors DINGZHI_INSTALL_DIR" {
    grep -q 'DINGZHI_INSTALL_DIR' "$DINGZHI_PATH/boot.sh"
}

@test "boot.sh refuses to clobber a non-dingzhi directory" {
    mkdir -p "$HOME/occupied" && echo precious > "$HOME/occupied/file"
    run env DINGZHI_INSTALL_DIR="$HOME/occupied" DINGZHI_SKIP_INSTALL=1 \
        bash "$DINGZHI_PATH/boot.sh"
    [ "$status" -ne 0 ]
    [[ "$output" == *"already exists"* ]]
    [ "$(cat "$HOME/occupied/file")" = "precious" ]
}

@test "boot.sh clones into a scratch directory" {
    run env DINGZHI_REPO="file://$DINGZHI_PATH" \
        DINGZHI_INSTALL_DIR="$HOME/scratch" \
        DINGZHI_SKIP_INSTALL=1 \
        bash "$DINGZHI_PATH/boot.sh"
    [ "$status" -eq 0 ]
    [ -f "$HOME/scratch/version" ]
    [ -f "$HOME/scratch/install.sh" ]
}

@test "boot.sh updates an existing checkout instead of failing" {
    env DINGZHI_REPO="file://$DINGZHI_PATH" DINGZHI_INSTALL_DIR="$HOME/scratch" \
        DINGZHI_SKIP_INSTALL=1 bash "$DINGZHI_PATH/boot.sh" >/dev/null
    run env DINGZHI_REPO="file://$DINGZHI_PATH" DINGZHI_INSTALL_DIR="$HOME/scratch" \
        DINGZHI_SKIP_INSTALL=1 bash "$DINGZHI_PATH/boot.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"updating"* ]]
}

@test "boot.sh aborts when git is missing" {
    run env PATH=/nonexistent DINGZHI_SKIP_INSTALL=1 \
        /bin/bash "$DINGZHI_PATH/boot.sh"
    [ "$status" -ne 0 ]
}
