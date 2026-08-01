# shellcheck shell=bash
# Shared functions. Sourced by init.sh.

# mkcd <dir> — create a directory and enter it.
mkcd() {
    [ -n "$1" ] || { echo "usage: mkcd <dir>" >&2; return 1; }
    mkdir -p -- "$1" && cd -P -- "$1" || return 1
}

# up [n] — go up n directories (default 1).
up() {
    local n="${1:-1}" path=""
    while [ "$n" -gt 0 ]; do
        path="../$path"
        n=$((n - 1))
    done
    cd "$path" || return 1
}

# newest — print the most recently modified entry in the current directory.
# Parsing ls is unsafe for filenames containing newlines; these two are
# interactive conveniences for looking at your own working directory, where
# that trade is worth the portability (find -printf is GNU-only).
# shellcheck disable=SC2012
newest() {
    ls -Art | tail -n 1
}

# taillast — follow the most recently modified file.
# shellcheck disable=SC2012
taillast() {
    local f
    f="$(ls -t | head -n 1)"
    [ -n "$f" ] || { echo "taillast: nothing here" >&2; return 1; }
    tail -f "$f"
}

# extract <archive> — unpack any common archive format.
extract() {
    [ -f "$1" ] || { echo "extract: not a file: $1" >&2; return 1; }
    case "$1" in
        *.tar.bz2|*.tbz2) tar xjf "$1" ;;
        *.tar.gz|*.tgz)   tar xzf "$1" ;;
        *.tar.xz)         tar xJf "$1" ;;
        *.tar)            tar xf "$1" ;;
        *.zip)            unzip "$1" ;;
        *.gz)             gunzip "$1" ;;
        *.bz2)            bunzip2 "$1" ;;
        *.7z)             7z x "$1" ;;
        *) echo "extract: unknown format: $1" >&2; return 1 ;;
    esac
}

# cmtpush <message> — commit everything tracked and push the current branch.
cmtpush() {
    [ -n "$1" ] || { echo "usage: cmtpush <message>" >&2; return 1; }
    git commit -a -m "$1" && git push origin "$(git rev-parse --abbrev-ref HEAD)"
}
