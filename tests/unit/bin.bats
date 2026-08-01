#!/usr/bin/env bats

load ../helpers

setup() {
    setup_dingzhi_env
}

@test "both scripts exist and are executable" {
    [ -x "$DINGZHI_PATH/bin/myconvert" ]
    [ -x "$DINGZHI_PATH/bin/compressimage" ]
}

@test "myconvert has no hardcoded personal venv path" {
    run grep -E '/Users/(cche|u1149259|chongchonghe)' "$DINGZHI_PATH/bin/myconvert"
    [ "$status" -ne 0 ]
}

@test "myconvert reads the marker venv from the environment" {
    grep -q 'MYCONVERT_MARKER_VENV' "$DINGZHI_PATH/bin/myconvert"
}

@test "myconvert --help exits zero" {
    run "$DINGZHI_PATH/bin/myconvert" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"universal file format converter"* ]]
}

@test "compressimage --help exits zero" {
    run "$DINGZHI_PATH/bin/compressimage" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Batch image compressor"* ]]
}

@test "myconvert fails clearly when marker is requested but unconfigured" {
    printf 'x' > "$HOME/in.pdf"
    run env -u MYCONVERT_MARKER_VENV "$DINGZHI_PATH/bin/myconvert" \
        --force-marker "$HOME/in.pdf" "$HOME/out.md"
    [ "$status" -ne 0 ]
    [[ "$output" == *"MYCONVERT_MARKER_VENV"* ]]
}

@test "myconvert rejects an unsupported conversion" {
    printf 'x' > "$HOME/in.xyz"
    run "$DINGZHI_PATH/bin/myconvert" "$HOME/in.xyz" "$HOME/out.abc"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Unsupported conversion"* ]]
}

@test "myconvert tolerates an unset OPENAI_API_KEY under set -u" {
    # convert_marker's dry-run branch expanded $OPENAI_API_KEY unguarded, which
    # aborts under `set -u` on any machine that has not set one.
    printf 'x' > "$HOME/in.pdf"
    touch "$HOME/fake-venv-activate"
    run env -u OPENAI_API_KEY MYCONVERT_MARKER_VENV="$HOME/fake-venv-activate" \
        "$DINGZHI_PATH/bin/myconvert" --dry-run --force-marker "$HOME/in.pdf" "$HOME/out.md"
    [ "$status" -eq 0 ]
    [[ "$output" == *"dry-run"* ]]
}

@test "myconvert works with ImageMagick 6, whose binary is convert" {
    # Ubuntu 24.04 ships ImageMagick 6; `magick` does not exist there.
    grep -qE 'magick|convert' "$DINGZHI_PATH/bin/myconvert"
    run grep -n 'require magick' "$DINGZHI_PATH/bin/myconvert"
    [ "$status" -ne 0 ]
}

@test "compressimage passes shellcheck" {
    # myconvert is excluded: it embeds Python heredocs shellcheck cannot parse.
    run shellcheck -s bash -e SC1091,SC2016 "$DINGZHI_PATH/bin/compressimage"
    [ "$status" -eq 0 ] || { echo "$output"; return 1; }
}
