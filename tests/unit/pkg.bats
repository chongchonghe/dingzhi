#!/usr/bin/env bats

load ../helpers

setup() {
    setup_dingzhi_env
    source "$DINGZHI_PATH/lib/ui.sh"
}

@test "resolve fd for brew" {
    export DINGZHI_BACKEND=brew
    source "$DINGZHI_PATH/lib/detect.sh"
    source "$DINGZHI_PATH/lib/pkg.sh"
    run pkg_resolve fd brew
    [ "$output" = "fd" ]
}

@test "resolve fd for apt uses the Debian package name" {
    export DINGZHI_BACKEND=apt
    source "$DINGZHI_PATH/lib/detect.sh"
    source "$DINGZHI_PATH/lib/pkg.sh"
    run pkg_resolve fd apt
    [ "$output" = "fd-find" ]
}

@test "resolve fd for noroot uses an eget spec" {
    export DINGZHI_BACKEND=noroot
    source "$DINGZHI_PATH/lib/detect.sh"
    source "$DINGZHI_PATH/lib/pkg.sh"
    run pkg_resolve fd noroot
    [[ "$output" == eget:sharkdp/fd* ]]
}

@test "resolve tmux for noroot uses pixi" {
    export DINGZHI_BACKEND=noroot
    source "$DINGZHI_PATH/lib/detect.sh"
    source "$DINGZHI_PATH/lib/pkg.sh"
    run pkg_resolve tmux noroot
    [[ "$output" == pixi:* ]]
}

@test "resolve an unknown package returns empty" {
    export DINGZHI_BACKEND=apt
    source "$DINGZHI_PATH/lib/detect.sh"
    source "$DINGZHI_PATH/lib/pkg.sh"
    run pkg_resolve definitely-not-a-package apt
    [ "$output" = "" ]
}

@test "pkg_binary maps poppler to pdftotext" {
    source "$DINGZHI_PATH/lib/detect.sh"
    source "$DINGZHI_PATH/lib/pkg.sh"
    run pkg_binary poppler
    [ "$output" = "pdftotext" ]
}

@test "pkg_binary maps tlrc to tldr" {
    source "$DINGZHI_PATH/lib/detect.sh"
    source "$DINGZHI_PATH/lib/pkg.sh"
    run pkg_binary tlrc
    [ "$output" = "tldr" ]
}

@test "pkg_binary maps git-delta to delta" {
    source "$DINGZHI_PATH/lib/detect.sh"
    source "$DINGZHI_PATH/lib/pkg.sh"
    run pkg_binary git-delta
    [ "$output" = "delta" ]
}

@test "pkg_binary knows the names that differ from the package" {
    source "$DINGZHI_PATH/lib/detect.sh"
    source "$DINGZHI_PATH/lib/pkg.sh"
    # A wrong answer here means pkg_installed is always false and the app
    # reinstalls on every run.
    [ "$(pkg_binary ripgrep)" = "rg" ]
    [ "$(pkg_binary neovim)" = "nvim" ]
    [ "$(pkg_binary github-cli)" = "gh" ]
    [ "$(pkg_binary trash-cli)" = "trash-put" ]
    [ "$(pkg_binary git-delta)" = "delta" ]
    [ "$(pkg_binary poppler)" = "pdftotext" ]
    [ "$(pkg_binary webp)" = "cwebp" ]
    [ "$(pkg_binary tlrc)" = "tldr" ]
}

@test "imagemagick accepts either the v7 or v6 binary name" {
    source "$DINGZHI_PATH/lib/detect.sh"
    source "$DINGZHI_PATH/lib/pkg.sh"
    run pkg_binaries imagemagick
    [ "$output" = "magick convert" ]
}

@test "pkg_binary defaults to the generic name" {
    source "$DINGZHI_PATH/lib/detect.sh"
    source "$DINGZHI_PATH/lib/pkg.sh"
    run pkg_binary fzf
    [ "$output" = "fzf" ]
}

@test "pkg_installed is true for a command that exists" {
    source "$DINGZHI_PATH/lib/detect.sh"
    source "$DINGZHI_PATH/lib/pkg.sh"
    run pkg_installed git
    [ "$status" -eq 0 ]
}

@test "pkg_installed is false for a command that does not exist" {
    source "$DINGZHI_PATH/lib/detect.sh"
    source "$DINGZHI_PATH/lib/pkg.sh"
    run pkg_installed lazygit
    [ "$status" -ne 0 ]
}

@test "every package resolves on brew" {
    source "$DINGZHI_PATH/lib/detect.sh"
    source "$DINGZHI_PATH/lib/pkg.sh"
    for p in $(pkg_all_names); do
        [ -n "$(pkg_resolve "$p" brew)" ] || { echo "no brew mapping: $p"; return 1; }
    done
}

@test "only the documented packages lack a noroot mapping" {
    source "$DINGZHI_PATH/lib/detect.sh"
    source "$DINGZHI_PATH/lib/pkg.sh"
    # jpegoptim is not on conda-forge; conda-forge's vifm is osx-64 only.
    # Their app scripts degrade explicitly. Anything else missing here is a
    # typo, and would silently fail to install for every no-root user.
    missing=""
    for p in $(pkg_all_names); do
        [ -n "$(pkg_resolve "$p" noroot)" ] || missing="$missing $p"
    done
    missing="$(echo "$missing" | tr ' ' '\n' | grep -v '^$' | sort | tr '\n' ' ')"
    [ "$missing" = "jpegoptim vifm " ] || { echo "unexpected noroot gaps: $missing"; return 1; }
}

@test "noroot specs use a known kind" {
    source "$DINGZHI_PATH/lib/detect.sh"
    source "$DINGZHI_PATH/lib/pkg.sh"
    for p in $(pkg_all_names); do
        spec="$(pkg_resolve "$p" noroot)"
        # An empty spec means "unavailable on this backend", covered by the
        # documented-gaps test above.
        [ -n "$spec" ] || continue
        case "${spec%%:*}" in
            eget|pixi|uv) ;;
            *) echo "bad noroot spec for $p: $spec"; return 1 ;;
        esac
    done
}

@test "pkg.sh passes shellcheck" {
    run shellcheck -s bash -e SC1091 "$DINGZHI_PATH/lib/pkg.sh"
    [ "$status" -eq 0 ] || { echo "$output"; return 1; }
}

@test "pkg.sh uses no bash 4+ syntax" {
    run grep -nE 'declare -A|mapfile|readarray|\$\{[A-Za-z_]+\^\^\}|\$\{[A-Za-z_]+,,\}' \
        "$DINGZHI_PATH/lib/pkg.sh"
    [ "$status" -ne 0 ]
}
