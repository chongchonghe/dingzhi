#!/usr/bin/env bats

load ../helpers

setup() {
    setup_dingzhi_env
}

@test "detect sets DINGZHI_OS to linux in the container" {
    source "$DINGZHI_PATH/lib/detect.sh"
    [ "$DINGZHI_OS" = "linux" ]
}

@test "detect sets DINGZHI_ARCH to a known value" {
    source "$DINGZHI_PATH/lib/detect.sh"
    [[ "$DINGZHI_ARCH" == "x86_64" || "$DINGZHI_ARCH" == "arm64" ]]
}

@test "detect picks a valid backend" {
    source "$DINGZHI_PATH/lib/detect.sh"
    [[ "$DINGZHI_BACKEND" == "brew" || "$DINGZHI_BACKEND" == "apt" || "$DINGZHI_BACKEND" == "noroot" ]]
}

@test "an explicitly set backend is respected" {
    export DINGZHI_BACKEND=noroot
    source "$DINGZHI_PATH/lib/detect.sh"
    [ "$DINGZHI_BACKEND" = "noroot" ]
}

@test "noroot backend points DINGZHI_BIN into HOME" {
    export DINGZHI_BACKEND=noroot
    source "$DINGZHI_PATH/lib/detect.sh"
    [ "$DINGZHI_BIN" = "$HOME/local/bin" ]
}

@test "apt backend points DINGZHI_BIN at /usr/local/bin" {
    export DINGZHI_BACKEND=apt
    source "$DINGZHI_PATH/lib/detect.sh"
    [ "$DINGZHI_BIN" = "/usr/local/bin" ]
}

@test "DINGZHI_PATH resolves to the repository root" {
    source "$DINGZHI_PATH/lib/detect.sh"
    [ -f "$DINGZHI_PATH/version" ]
}

@test "dingzhi_has_sudo agrees with the image it runs in" {
    source "$DINGZHI_PATH/lib/detect.sh"
    if sudo -n true 2>/dev/null; then
        dingzhi_has_sudo
    else
        ! dingzhi_has_sudo
    fi
}

@test "detect.sh passes shellcheck" {
    run shellcheck -s bash -e SC1091 "$DINGZHI_PATH/lib/detect.sh"
    [ "$status" -eq 0 ] || { echo "$output"; return 1; }
}
