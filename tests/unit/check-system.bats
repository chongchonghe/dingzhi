#!/usr/bin/env bats

load ../helpers

setup() {
    setup_dingzhi_env
}

@test "check-system passes on linux" {
    run bash -c "
        source '$DINGZHI_PATH/lib/detect.sh'
        source '$DINGZHI_PATH/lib/ui.sh'
        source '$DINGZHI_PATH/install/check-system.sh'
    "
    [ "$status" -eq 0 ]
}

@test "check-system aborts on an unsupported OS" {
    run bash -c "
        source '$DINGZHI_PATH/lib/detect.sh'
        source '$DINGZHI_PATH/lib/ui.sh'
        DINGZHI_OS=unsupported
        source '$DINGZHI_PATH/install/check-system.sh'
    "
    [ "$status" -ne 0 ]
    [[ "$output" == *"not supported"* ]]
}

@test "check-system aborts when git is missing" {
    run bash -c "
        source '$DINGZHI_PATH/lib/detect.sh'
        source '$DINGZHI_PATH/lib/ui.sh'
        PATH=/nonexistent
        source '$DINGZHI_PATH/install/check-system.sh'
    "
    [ "$status" -ne 0 ]
}

@test "check-system reports the detected backend" {
    run bash -c "
        source '$DINGZHI_PATH/lib/detect.sh'
        source '$DINGZHI_PATH/lib/ui.sh'
        source '$DINGZHI_PATH/install/check-system.sh'
    "
    [[ "$output" == *"backend="* ]]
}

@test "both install scripts pass shellcheck" {
    for f in check-system bootstrap; do
        run shellcheck -s bash -e SC1090,SC1091 "$DINGZHI_PATH/install/$f.sh"
        [ "$status" -eq 0 ] || { echo "shellcheck failed: $f"; echo "$output"; return 1; }
    done
}
