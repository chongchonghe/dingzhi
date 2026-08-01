#!/usr/bin/env bats

load ../helpers

setup() {
    setup_dingzhi_env
    source "$DINGZHI_PATH/lib/ui.sh"
}

@test "say writes to stdout with a prefix" {
    run say "hello"
    [ "$status" -eq 0 ]
    [ "$output" = "==> hello" ]
}

@test "step writes an indented line" {
    run step "doing a thing"
    [ "$output" = "    doing a thing" ]
}

@test "skip writes an indented skip marker" {
    run skip "already there"
    [ "$status" -eq 0 ]
    [ "$output" = "    [skip] already there" ]
}

@test "warn writes to stderr" {
    run bash -c "source '$DINGZHI_PATH/lib/ui.sh'; warn oops 2>&1 1>/dev/null"
    [ "$output" = "!! oops" ]
}

@test "die exits non-zero" {
    run bash -c "source '$DINGZHI_PATH/lib/ui.sh'; die 'fatal'"
    [ "$status" -eq 1 ]
}

@test "prompt returns the default when non-interactive" {
    export DINGZHI_NONINTERACTIVE=1
    run prompt "Your name" "Nobody"
    [ "$status" -eq 0 ]
    [ "$output" = "Nobody" ]
}

@test "confirm succeeds when non-interactive" {
    export DINGZHI_NONINTERACTIVE=1
    run confirm "Proceed?"
    [ "$status" -eq 0 ]
}

@test "choose_multi returns defaults when non-interactive" {
    export DINGZHI_NONINTERACTIVE=1
    run choose_multi "Pick" "core,git" core terminal git
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "core" ]
    [ "${lines[1]}" = "git" ]
    [ "${#lines[@]}" -eq 2 ]
}

@test "choose_multi preserves declaration order, not default order" {
    export DINGZHI_NONINTERACTIVE=1
    run choose_multi "Pick" "git,core" core terminal git
    [ "${lines[0]}" = "core" ]
    [ "${lines[1]}" = "git" ]
}

@test "choose_multi ignores defaults that are not offered" {
    export DINGZHI_NONINTERACTIVE=1
    run choose_multi "Pick" "core,nonexistent" core terminal
    [ "${#lines[@]}" -eq 1 ]
    [ "${lines[0]}" = "core" ]
}

@test "choose_multi does not match a default by substring" {
    # "core" must not select "coreutils", nor vice versa.
    export DINGZHI_NONINTERACTIVE=1
    run choose_multi "Pick" "core" core coreutils
    [ "${#lines[@]}" -eq 1 ]
    [ "${lines[0]}" = "core" ]
}

@test "ui.sh passes shellcheck" {
    run shellcheck -s bash -e SC1091 "$DINGZHI_PATH/lib/ui.sh"
    [ "$status" -eq 0 ] || { echo "$output"; return 1; }
}
