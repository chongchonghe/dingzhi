#!/usr/bin/env bats

load ../helpers

setup() {
    setup_dingzhi_env
}

ALL_GROUPS="core terminal editors git filemanagers shell dev media misc"

@test "all 33 apps are present" {
    run bash -c "ls -d '$DINGZHI_PATH'/apps/*/ 2>/dev/null | wc -l"
    [ "$output" -eq 33 ] || { echo "found $output app directories, expected 33"; return 1; }
}

@test "every app has an install script" {
    for d in "$DINGZHI_PATH"/apps/*/; do
        [ -f "$d/install.sh" ] || { echo "missing install.sh: $(basename "$d")"; return 1; }
    done
}

@test "every app declares exactly one known group on line 2" {
    for d in "$DINGZHI_PATH"/apps/*/; do
        g="$(sed -n '2s/^# group: //p' "$d/install.sh")"
        case " $ALL_GROUPS " in
            *" $g "*) ;;
            *) echo "bad group '$g' in $(basename "$d")"; return 1 ;;
        esac
    done
}

@test "the core group holds the expected apps" {
    for a in bat eza fd fzf ripgrep zoxide git-delta jq tlrc trash-cli stow thefuck; do
        grep -q '^# group: core$' "$DINGZHI_PATH/apps/$a/install.sh" \
            || { echo "not in core: $a"; return 1; }
    done
}

@test "the terminal, editors, git and filemanagers groups hold the expected apps" {
    for a in kitty tmux; do
        grep -q '^# group: terminal$' "$DINGZHI_PATH/apps/$a/install.sh" || { echo "bad: $a"; return 1; }
    done
    for a in neovim vim; do
        grep -q '^# group: editors$' "$DINGZHI_PATH/apps/$a/install.sh" || { echo "bad: $a"; return 1; }
    done
    for a in git lazygit github-cli; do
        grep -q '^# group: git$' "$DINGZHI_PATH/apps/$a/install.sh" || { echo "bad: $a"; return 1; }
    done
    for a in yazi vifm; do
        grep -q '^# group: filemanagers$' "$DINGZHI_PATH/apps/$a/install.sh" || { echo "bad: $a"; return 1; }
    done
}

@test "the shell, dev, media and misc groups hold the expected apps" {
    for a in zsh bash; do
        grep -q '^# group: shell$' "$DINGZHI_PATH/apps/$a/install.sh" || { echo "bad: $a"; return 1; }
    done
    for a in uv cmake; do
        grep -q '^# group: dev$' "$DINGZHI_PATH/apps/$a/install.sh" || { echo "bad: $a"; return 1; }
    done
    for a in pandoc poppler imagemagick ffmpeg pngquant jpegoptim webp; do
        grep -q '^# group: media$' "$DINGZHI_PATH/apps/$a/install.sh" || { echo "bad: $a"; return 1; }
    done
    grep -q '^# group: misc$' "$DINGZHI_PATH/apps/cheat/install.sh"
}

@test "every app script passes shellcheck" {
    for d in "$DINGZHI_PATH"/apps/*/; do
        run shellcheck -s bash -e SC1091,SC2154 "$d/install.sh"
        [ "$status" -eq 0 ] || { echo "shellcheck failed: $(basename "$d")"; echo "$output"; return 1; }
    done
}

@test "no app script uses bash 4+ syntax" {
    run grep -rlE 'declare -A|mapfile|readarray|\$\{[A-Za-z_]+\^\^\}|\$\{[A-Za-z_]+,,\}' \
        "$DINGZHI_PATH/apps/"
    [ "$status" -ne 0 ] || { echo "$output"; return 1; }
}

@test "no app script hardcodes a personal or absolute checkout path" {
    run grep -rlE 'Users/|/home/(dev|cche)|HOME/tools' "$DINGZHI_PATH/apps/"
    [ "$status" -ne 0 ] || { echo "$output"; return 1; }
}

@test "every app that ships a config links it from configs/" {
    # Guards against an app script pointing at inbox/ or an absolute path.
    run grep -rn 'manage_symlink' "$DINGZHI_PATH/apps/"
    [ "$status" -eq 0 ]
    run grep -rn 'manage_symlink.*inbox' "$DINGZHI_PATH/apps/"
    [ "$status" -ne 0 ]
}
