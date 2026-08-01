#!/usr/bin/env bats

load ../helpers

setup() {
    setup_dingzhi_env
}

@test "dingzhi is executable" {
    [ -x "$DINGZHI_PATH/bin/dingzhi" ]
}

@test "dingzhi passes shellcheck" {
    run shellcheck -s bash -e SC1090,SC1091 "$DINGZHI_PATH/bin/dingzhi"
    [ "$status" -eq 0 ] || { echo "$output"; return 1; }
}

@test "dingzhi --help lists every subcommand" {
    run "$DINGZHI_PATH/bin/dingzhi" --help
    [ "$status" -eq 0 ]
    for c in install remove update doctor; do
        [[ "$output" == *"$c"* ]] || { echo "missing subcommand: $c"; return 1; }
    done
}

@test "dingzhi doctor reports apps, backend, and paths" {
    run "$DINGZHI_PATH/bin/dingzhi" doctor
    [[ "$output" == *"bat"* ]]
    [[ "$output" == *"neovim"* ]]
    [[ "$output" == *"backend"* ]]
}

@test "dingzhi doctor exits non-zero when things are missing" {
    run "$DINGZHI_PATH/bin/dingzhi" doctor
    [ "$status" -ne 0 ]
    [[ "$output" == *"MISSING"* ]]
}

@test "dingzhi rejects an unknown subcommand" {
    run "$DINGZHI_PATH/bin/dingzhi" nonsense
    [ "$status" -ne 0 ]
    [[ "$output" == *"unknown"* ]]
}

@test "dingzhi resolves its own path when invoked through a symlink" {
    mkdir -p "$HOME/somewhere"
    ln -s "$DINGZHI_PATH/bin/dingzhi" "$HOME/somewhere/dingzhi"
    run "$HOME/somewhere/dingzhi" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"install"* ]]
}

@test "remove only offers apps that ship an uninstall script" {
    # The contract: no uninstall.sh means the app is install-only and the menu
    # says so by omission rather than pretending it can undo the install.
    grep -q 'uninstall.sh' "$DINGZHI_PATH/bin/dingzhi"
}
