#!/usr/bin/env bats

load ../helpers

setup() {
    setup_dingzhi_env
    export DINGZHI_NONINTERACTIVE=1
    source "$DINGZHI_PATH/lib/detect.sh"
    source "$DINGZHI_PATH/lib/ui.sh"
}

@test "non-interactive choices select every group" {
    source "$DINGZHI_PATH/install/choices.sh"
    for g in core terminal editors git filemanagers shell dev media misc; do
        [[ " $DINGZHI_GROUPS " == *" $g "* ]] || { echo "missing group: $g"; return 1; }
    done
}

@test "non-interactive choices default to zsh only" {
    source "$DINGZHI_PATH/install/choices.sh"
    [ "$DINGZHI_SHELLS" = "zsh" ]
}

@test "choices are persisted to the state file" {
    source "$DINGZHI_PATH/install/choices.sh"
    [ -f "$HOME/.local/state/dingzhi/choices" ]
    grep -q '^DINGZHI_GROUPS=' "$HOME/.local/state/dingzhi/choices"
    grep -q '^DINGZHI_SHELLS=' "$HOME/.local/state/dingzhi/choices"
}

@test "persisted choices are reused on the next run" {
    mkdir -p "$HOME/.local/state/dingzhi"
    printf 'DINGZHI_GROUPS="core git"\nDINGZHI_SHELLS="bash"\n' > "$HOME/.local/state/dingzhi/choices"
    source "$DINGZHI_PATH/install/choices.sh"
    [ "$DINGZHI_GROUPS" = "core git" ]
    [ "$DINGZHI_SHELLS" = "bash" ]
}

@test "the state file does not shadow bash's builtin GROUPS array" {
    source "$DINGZHI_PATH/install/choices.sh"
    run grep -c '^GROUPS=' "$HOME/.local/state/dingzhi/choices"
    [ "$output" = "0" ]
}

@test "the persisted file round-trips through a second run" {
    source "$DINGZHI_PATH/install/choices.sh"
    first="$DINGZHI_GROUPS"
    unset DINGZHI_GROUPS DINGZHI_SHELLS
    source "$DINGZHI_PATH/install/choices.sh"
    [ "$DINGZHI_GROUPS" = "$first" ]
}

@test "XDG_STATE_HOME is honored" {
    export XDG_STATE_HOME="$HOME/xdgstate"
    source "$DINGZHI_PATH/install/choices.sh"
    [ -f "$HOME/xdgstate/dingzhi/choices" ]
}

@test "identification writes a gitconfig.local" {
    export DINGZHI_GIT_NAME="Test User" DINGZHI_GIT_EMAIL="test@example.com"
    source "$DINGZHI_PATH/install/identification.sh"
    [ -f "$HOME/.gitconfig.local" ]
    grep -q 'name = Test User' "$HOME/.gitconfig.local"
    grep -q 'email = test@example.com' "$HOME/.gitconfig.local"
}

@test "identification does not overwrite an existing gitconfig.local" {
    printf '[user]\n\tname = Existing\n' > "$HOME/.gitconfig.local"
    export DINGZHI_GIT_NAME="Test User" DINGZHI_GIT_EMAIL="test@example.com"
    source "$DINGZHI_PATH/install/identification.sh"
    grep -q 'name = Existing' "$HOME/.gitconfig.local"
}

@test "the written gitconfig.local is valid git config" {
    export DINGZHI_GIT_NAME="Test User" DINGZHI_GIT_EMAIL="test@example.com"
    source "$DINGZHI_PATH/install/identification.sh"
    run git config --file "$HOME/.gitconfig.local" user.name
    [ "$status" -eq 0 ]
    [ "$output" = "Test User" ]
}

@test "both scripts pass shellcheck" {
    for f in choices identification; do
        run shellcheck -s bash -e SC1090,SC1091,SC2034 "$DINGZHI_PATH/install/$f.sh"
        [ "$status" -eq 0 ] || { echo "shellcheck failed: $f"; echo "$output"; return 1; }
    done
}
