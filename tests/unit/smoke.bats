#!/usr/bin/env bats

load ../helpers

setup() {
    setup_dingzhi_env
}

@test "HOME is redirected away from the real home" {
    [ "$HOME" != "/home/dev" ]
    [ "$HOME" != "/root" ]
    [ -d "$HOME" ]
}

@test "DINGZHI_PATH points at the repository root" {
    [ -f "$DINGZHI_PATH/version" ]
}

@test "version file contains a semver string" {
    run cat "$DINGZHI_PATH/version"
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "the container has the Claude Code CLI" {
    run claude --version
    [ "$status" -eq 0 ]
}
