#!/usr/bin/env bats

load ../helpers

setup() {
    setup_dingzhi_env
}

@test "init.sh sources cleanly under bash" {
    run bash -c "source '$DINGZHI_PATH/configs/shell/init.sh'; echo ok"
    [ "$status" -eq 0 ]
    [[ "$output" == *ok* ]]
}

@test "init.sh puts the dingzhi bin directory on PATH" {
    run bash -c "source '$DINGZHI_PATH/configs/shell/init.sh'; echo \$PATH"
    [[ "$output" == *"$DINGZHI_PATH/bin"* ]]
}

@test "init.sh defines the ll alias" {
    run bash -c "shopt -s expand_aliases; source '$DINGZHI_PATH/configs/shell/init.sh'; alias ll"
    [ "$status" -eq 0 ]
}

@test "init.sh defines the mkcd function" {
    run bash -c "source '$DINGZHI_PATH/configs/shell/init.sh'; type -t mkcd"
    [ "$output" = "function" ]
}

@test "no personal paths remain in the shell config" {
    run grep -rEl 'Users/(cche|u1149259)|HOME/tools|MOVE_ROOT|RC_HOME|quokka' \
        "$DINGZHI_PATH/configs/shell/"
    [ "$status" -ne 0 ]
}

@test "sourcing twice does not duplicate PATH entries" {
    run bash -c "
        source '$DINGZHI_PATH/configs/shell/init.sh'
        source '$DINGZHI_PATH/configs/shell/init.sh'
        echo \$PATH | tr ':' '\n' | grep -c '^$DINGZHI_PATH/bin\$'
    "
    [ "$output" = "1" ]
}

@test "init.sh derives DINGZHI_PATH itself, without inheriting it" {
    run env -u DINGZHI_PATH bash -c "
        source '$DINGZHI_PATH/configs/shell/init.sh'
        echo \$DINGZHI_PATH
    "
    [ "$output" = "$DINGZHI_PATH" ]
}

@test "init.sh sources cleanly under zsh when zsh is available" {
    command -v zsh >/dev/null 2>&1 || skip "zsh not installed in this container"
    run zsh -c "source '$DINGZHI_PATH/configs/shell/init.sh'; echo ok"
    [ "$status" -eq 0 ]
    [[ "$output" == *ok* ]]
}

@test "shell config files pass shellcheck" {
    for f in "$DINGZHI_PATH"/configs/shell/*.sh; do
        run shellcheck -s bash -e SC1090,SC1091,SC2148,SC2296,SC2168 "$f"
        [ "$status" -eq 0 ] || { echo "shellcheck failed: $f"; echo "$output"; return 1; }
    done
}

@test "shell config uses no bash 4+ syntax" {
    run grep -rnE 'declare -A|mapfile|readarray|\$\{[A-Za-z_]+\^\^\}|\$\{[A-Za-z_]+,,\}' \
        "$DINGZHI_PATH/configs/shell/"
    [ "$status" -ne 0 ]
}
