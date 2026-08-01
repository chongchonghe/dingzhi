#!/usr/bin/env bash
# Package abstraction over three backends: brew, apt, and eget+pixi (noroot).
#
# Requires lib/detect.sh and lib/ui.sh to be sourced first.
#
# The table below is the single place a package's per-platform identity lives.
# bash 3.2 has no associative arrays, so it is a case statement. Adding apt
# support for every package is a table edit, not an edit to 34 app scripts.
#
# noroot spec formats:
#   eget:<owner>/<repo>[|<asset-filter>[|<file-in-archive>]]
#   pixi:<conda-forge-package>
#   uv:<pypi-package>
#
# An empty apt mapping is meaningful: the package is not in Ubuntu's
# repositories and its app script falls back to a release binary.

# Every generic name the table knows. Used by tests and by `dingzhi doctor`.
pkg_all_names() {
    cat <<'EOF'
bat
eza
fd
fzf
ripgrep
zoxide
git-delta
jq
tlrc
trash-cli
stow
thefuck
tmux
neovim
vim
git
lazygit
github-cli
yazi
vifm
zsh
cmake
pandoc
poppler
imagemagick
ffmpeg
pngquant
jpegoptim
webp
EOF
}

# pkg_resolve <generic> <backend> -> backend-specific spec, or empty
pkg_resolve() {
    local name="$1" backend="$2"
    case "$name:$backend" in
        # ---- core CLI ----
        bat:brew)            echo "bat" ;;
        bat:apt)             echo "bat" ;;
        bat:noroot)          echo "eget:sharkdp/bat|x86_64-unknown-linux-gnu.tar.gz" ;;

        eza:brew)            echo "eza" ;;
        eza:apt)             echo "eza" ;;
        eza:noroot)          echo "eget:eza-community/eza|x86_64-unknown-linux-musl.tar.gz" ;;

        fd:brew)             echo "fd" ;;
        fd:apt)              echo "fd-find" ;;
        fd:noroot)           echo "eget:sharkdp/fd|x86_64-unknown-linux-gnu.tar.gz" ;;

        fzf:brew)            echo "fzf" ;;
        fzf:apt)             echo "fzf" ;;
        fzf:noroot)          echo "eget:junegunn/fzf|linux_amd64.tar.gz" ;;

        ripgrep:brew)        echo "ripgrep" ;;
        ripgrep:apt)         echo "ripgrep" ;;
        ripgrep:noroot)      echo "eget:BurntSushi/ripgrep|x86_64-unknown-linux-musl.tar.gz" ;;

        zoxide:brew)         echo "zoxide" ;;
        zoxide:apt)          echo "zoxide" ;;
        zoxide:noroot)       echo "eget:ajeetdsouza/zoxide|x86_64-unknown-linux-musl.tar.gz" ;;

        git-delta:brew)      echo "git-delta" ;;
        git-delta:apt)       echo "git-delta" ;;
        git-delta:noroot)    echo "eget:dandavison/delta|x86_64-unknown-linux-musl.tar.gz" ;;

        jq:brew)             echo "jq" ;;
        jq:apt)              echo "jq" ;;
        jq:noroot)           echo "eget:jqlang/jq|linux-amd64" ;;

        tlrc:brew)           echo "tlrc" ;;
        tlrc:apt)            echo "" ;;
        tlrc:noroot)         echo "eget:tldr-pages/tlrc|x86_64-unknown-linux-musl.tar.gz|tldr" ;;

        trash-cli:brew)      echo "trash-cli" ;;
        trash-cli:apt)       echo "trash-cli" ;;
        trash-cli:noroot)    echo "uv:trash-cli" ;;

        stow:brew)           echo "stow" ;;
        stow:apt)            echo "stow" ;;
        stow:noroot)         echo "pixi:stow" ;;

        thefuck:brew)        echo "thefuck" ;;
        thefuck:apt)         echo "uv:thefuck" ;;
        thefuck:noroot)      echo "uv:thefuck" ;;


        # ---- terminal ----
        # tmux 3.5+ has a Landlock sandbox bug that crashes on some kernels.
        tmux:brew)           echo "tmux" ;;
        tmux:apt)            echo "tmux" ;;
        tmux:noroot)         echo "pixi:tmux==3.4" ;;

        # ---- editors ----
        neovim:brew)         echo "neovim" ;;
        # Ubuntu 24.04 ships 0.9; the shipped config needs 0.10+.
        neovim:apt)          echo "" ;;
        neovim:noroot)       echo "eget:neovim/neovim|nvim-linux-x86_64.tar.gz|nvim-linux-x86_64/bin/nvim" ;;

        vim:brew)            echo "vim" ;;
        vim:apt)             echo "vim" ;;
        vim:noroot)          echo "pixi:vim" ;;

        # ---- git ----
        git:brew)            echo "git" ;;
        git:apt)             echo "git" ;;
        git:noroot)          echo "pixi:git" ;;

        lazygit:brew)        echo "lazygit" ;;
        lazygit:apt)         echo "" ;;
        lazygit:noroot)      echo "eget:jesseduffield/lazygit|linux_x86_64.tar.gz|lazygit" ;;

        github-cli:brew)     echo "gh" ;;
        # Needs a third-party apt repository; the release binary avoids that.
        github-cli:apt)      echo "" ;;
        github-cli:noroot)   echo "eget:cli/cli|linux_amd64.tar.gz|gh_*/bin/gh" ;;

        # ---- file managers ----
        yazi:brew)           echo "yazi" ;;
        yazi:apt)            echo "" ;;
        yazi:noroot)         echo "eget:sxyazi/yazi|x86_64-unknown-linux-musl.zip|yazi-x86_64-unknown-linux-musl/yazi" ;;

        vifm:brew)           echo "vifm" ;;
        vifm:apt)            echo "vifm" ;;
        # conda-forge's vifm has an osx-64 build only.
        vifm:noroot)         echo "" ;;

        # ---- shell ----
        zsh:brew)            echo "zsh" ;;
        zsh:apt)             echo "zsh" ;;
        zsh:noroot)          echo "pixi:zsh" ;;

        # ---- dev ----
        cmake:brew)          echo "cmake" ;;
        cmake:apt)           echo "cmake" ;;
        cmake:noroot)        echo "pixi:cmake" ;;

        # ---- media ----
        pandoc:brew)         echo "pandoc" ;;
        pandoc:apt)          echo "pandoc" ;;
        pandoc:noroot)       echo "pixi:pandoc" ;;

        poppler:brew)        echo "poppler" ;;
        poppler:apt)         echo "poppler-utils" ;;
        poppler:noroot)      echo "pixi:poppler" ;;

        imagemagick:brew)    echo "imagemagick" ;;
        imagemagick:apt)     echo "imagemagick" ;;
        imagemagick:noroot)  echo "pixi:imagemagick" ;;

        ffmpeg:brew)         echo "ffmpeg" ;;
        ffmpeg:apt)          echo "ffmpeg" ;;
        ffmpeg:noroot)       echo "pixi:ffmpeg" ;;

        pngquant:brew)       echo "pngquant" ;;
        pngquant:apt)        echo "pngquant" ;;
        pngquant:noroot)     echo "pixi:pngquant" ;;

        jpegoptim:brew)      echo "jpegoptim" ;;
        jpegoptim:apt)       echo "jpegoptim" ;;
        # Not packaged on conda-forge at all.
        jpegoptim:noroot)    echo "" ;;

        webp:brew)           echo "webp" ;;
        webp:apt)            echo "webp" ;;
        webp:noroot)         echo "pixi:libwebp" ;;

        *) echo "" ;;
    esac
}

# pkg_binaries <generic> -> every command name that would satisfy this package,
# most-preferred first. ImageMagick is the reason this returns a list: version 7
# provides `magick`, but Ubuntu 24.04 still ships version 6, whose binary is
# `convert`. Treating only one as valid would report a working install missing.
pkg_binaries() {
    case "$1" in
        git-delta)   echo "delta" ;;
        github-cli)  echo "gh" ;;
        ripgrep)     echo "rg" ;;
        neovim)      echo "nvim" ;;
        poppler)     echo "pdftotext" ;;
        webp)        echo "cwebp" ;;
        imagemagick) echo "magick convert" ;;
        trash-cli)   echo "trash-put" ;;
        tlrc)        echo "tldr" ;;
        *)           echo "$1" ;;
    esac
}

# pkg_binary <generic> -> the preferred command name.
pkg_binary() {
    # Word splitting is the point: pkg_binaries returns a space-separated list.
    # shellcheck disable=SC2046
    set -- $(pkg_binaries "$1")
    echo "$1"
}

pkg_installed() {
    local b
    # shellcheck disable=SC2046
    for b in $(pkg_binaries "$1"); do
        command -v "$b" >/dev/null 2>&1 && return 0
    done
    return 1
}

# Install one package via the active backend. Idempotent.
pkg_install() {
    local name="$1" spec

    if pkg_installed "$name"; then
        skip "$name already installed"
        return 0
    fi

    spec="$(pkg_resolve "$name" "$DINGZHI_BACKEND")"
    if [ -z "$spec" ]; then
        warn "no $DINGZHI_BACKEND mapping for '$name'; its app script must handle it"
        return 1
    fi

    step "installing $name ($spec)"
    case "$spec" in
        eget:*|pixi:*|uv:*)
            # Kind-prefixed specs are backend-agnostic.
            _pkg_install_noroot "$spec"
            ;;
        *)
            case "$DINGZHI_BACKEND" in
                brew)   brew install "$spec" ;;
                apt)    sudo apt-get install -y "$spec" ;;
                noroot) _pkg_install_noroot "$spec" ;;
            esac
            ;;
    esac
}

_pkg_install_noroot() {
    local spec="$1" kind payload repo filter file rest

    kind="${spec%%:*}"
    payload="${spec#*:}"

    case "$kind" in
        pixi)
            pixi global install "$payload"
            ;;
        uv)
            uv tool install "$payload"
            ;;
        eget)
            # payload is repo[|filter[|file]]
            repo="${payload%%|*}"
            filter=""
            file=""
            if [ "$payload" != "$repo" ]; then
                rest="${payload#*|}"
                filter="${rest%%|*}"
                [ "$rest" != "$filter" ] && file="${rest#*|}"
            fi
            mkdir -p "$DINGZHI_BIN"
            _pkg_eget "$repo" "$filter" "$file" "$DINGZHI_BIN"
            ;;
        *)
            warn "unknown noroot spec kind: $kind"
            return 1
            ;;
    esac
}

# GitHub allows 60 unauthenticated API requests per hour, per IP. That is a
# real constraint on the no-root path: HPC login nodes NAT many users behind a
# single address, so the budget can already be gone before dingzhi starts.
# eget reads GITHUB_TOKEN itself; this just finds one if the user has not
# exported it.
_pkg_github_token() {
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        printf '%s' "$GITHUB_TOKEN"
    elif [ -n "${GH_TOKEN:-}" ]; then
        printf '%s' "$GH_TOKEN"
    elif command -v gh >/dev/null 2>&1; then
        gh auth token 2>/dev/null || true
    fi
}

# _pkg_eget <repo> <filter> <file> <dest> [sudo]
# Shared by the noroot backend and by app scripts that fall back to a release
# binary on apt. Pass a non-empty fifth argument to run eget under sudo.
_pkg_eget() {
    local repo="$1" filter="$2" file="$3" dest="$4" use_sudo="${5:-}"
    local -a args

    args=(--to "$dest")
    [ -n "$filter" ] && args+=(--asset "$filter")
    [ -n "$file" ] && args+=(--file "$file")

    # Many projects publish checksums, signatures, and SBOMs alongside the
    # archive, and those filenames contain the archive's name. Without these
    # exclusions eget finds several candidates, prompts for a choice, and dies
    # with "Error reading selection" in any non-interactive run.
    args+=(--asset "^.sbom")
    args+=(--asset "^.sig")
    args+=(--asset "^.asc")
    args+=(--asset "^.sha256")
    args+=(--asset "^.pem")

    local token status
    token="$(_pkg_github_token)"

    if [ -n "$use_sudo" ]; then
        # -E would carry the whole environment; pass only what eget needs.
        sudo GITHUB_TOKEN="$token" "$(command -v eget)" "$repo" "${args[@]}"
        status=$?
    else
        GITHUB_TOKEN="$token" eget "$repo" "${args[@]}"
        status=$?
    fi

    if [ "$status" -ne 0 ] && [ -z "$token" ]; then
        warn "eget failed for $repo. If the message mentions a rate limit, set"
        warn "GITHUB_TOKEN (or run 'gh auth login') and re-run: unauthenticated"
        warn "GitHub API access is capped at 60 requests per hour per IP."
    fi
    return "$status"
}

# Install a package's release binary regardless of backend. Used by app scripts
# for the tools Ubuntu does not package (lazygit, gh, yazi, neovim, tlrc): the
# noroot spec already names the right asset, so reuse it rather than repeating
# the filter in every script.
pkg_install_release() {
    local name="$1" spec payload repo filter file rest dest use_sudo=""

    spec="$(pkg_resolve "$name" noroot)"
    case "${spec%%:*}" in
        eget) ;;
        *) warn "$name has no release-binary spec"; return 1 ;;
    esac

    payload="${spec#*:}"
    repo="${payload%%|*}"
    filter=""
    file=""
    if [ "$payload" != "$repo" ]; then
        rest="${payload#*|}"
        filter="${rest%%|*}"
        [ "$rest" != "$filter" ] && file="${rest#*|}"
    fi

    dest="$DINGZHI_BIN"
    [ "$DINGZHI_BACKEND" = "apt" ] && use_sudo=1

    step "installing $name from GitHub releases"
    [ -n "$use_sudo" ] || mkdir -p "$dest"
    _pkg_eget "$repo" "$filter" "$file" "$dest" "$use_sudo"
}

pkg_remove() {
    local name="$1" spec kind payload
    spec="$(pkg_resolve "$name" "$DINGZHI_BACKEND")"
    [ -n "$spec" ] || { warn "no $DINGZHI_BACKEND mapping for '$name'"; return 1; }

    step "removing $name"
    case "$spec" in
        eget:*|pixi:*|uv:*)
            kind="${spec%%:*}"
            payload="${spec#*:}"
            case "$kind" in
                pixi) pixi global uninstall "${payload%%==*}" ;;
                uv)   uv tool uninstall "$payload" ;;
                eget) rm -f "$DINGZHI_BIN/$(pkg_binary "$name")" ;;
            esac
            ;;
        *)
            case "$DINGZHI_BACKEND" in
                brew) brew uninstall "$spec" ;;
                apt)  sudo apt-get remove -y "$spec" ;;
            esac
            ;;
    esac
}
