#!/usr/bin/env bash
# Symlink management. Creates and removes links; never installs packages.
#
# Requires lib/ui.sh.

DINGZHI_SKIPPED_LINKS=""
DINGZHI_BACKED_UP=""

# Resolve a path to its absolute form. macOS has no `readlink -f`, so this is
# done with cd/pwd rather than a GNU-only flag.
_abspath() {
    local p="$1"
    if [ -d "$p" ]; then
        (cd "$p" && pwd)
    else
        printf '%s/%s\n' "$(cd "$(dirname "$p")" && pwd)" "$(basename "$p")"
    fi
}

# manage_symlink <src> <dest> <description>
manage_symlink() {
    local src="$1" dest="$2" desc="$3"
    local src_abs target current backup

    src_abs="$(_abspath "$src")"

    if [ -L "$dest" ]; then
        # Compare where the link points, not the link's own path. A relative
        # target is resolved against the directory holding the link.
        target="$(readlink "$dest")"
        case "$target" in
            /*) current="$target" ;;
            *)  current="$(cd "$(dirname "$dest")" && pwd)/$target" ;;
        esac
        # Normalise, so ~/dest -> src/file and ~/dest -> /abs/src/file compare equal.
        current="$(_abspath "$current" 2>/dev/null || printf '%s' "$current")"
        if [ "$current" = "$src_abs" ]; then
            skip "$desc already linked"
            DINGZHI_SKIPPED_LINKS="$DINGZHI_SKIPPED_LINKS$dest
"
            return 0
        fi
        rm -f "$dest"
    elif [ -e "$dest" ]; then
        backup="${dest}.backup.$(date +%Y%m%d%H%M%S)"
        step "backing up existing $desc to $(basename "$backup")"
        mv "$dest" "$backup"
        DINGZHI_BACKED_UP="$DINGZHI_BACKED_UP$dest -> $backup
"
    fi

    step "linking $desc"
    mkdir -p "$(dirname "$dest")"
    # -n matters: without it, relinking a directory creates the link *inside*
    # the existing one instead of replacing it.
    ln -sfn "$src_abs" "$dest"
}

# unlink_managed <dest> <description>
unlink_managed() {
    local dest="$1" desc="$2"
    if [ -L "$dest" ]; then
        step "removing $desc"
        rm -f "$dest"
    elif [ -e "$dest" ]; then
        warn "not removing $dest ($desc): not a symlink"
    fi
}

link_summary() {
    [ -n "$DINGZHI_SKIPPED_LINKS$DINGZHI_BACKED_UP" ] || return 0
    say "Link summary"
    if [ -n "$DINGZHI_BACKED_UP" ]; then
        step "backed up:"
        printf '%s' "$DINGZHI_BACKED_UP" | while IFS= read -r l; do
            [ -n "$l" ] && printf '        %s\n' "$l"
        done
    fi
    return 0
}

# inject_line <file> <marker> <line> <label>
inject_line() {
    local file="$1" marker="$2" line="$3" label="$4"

    [ -e "$file" ] || touch "$file"

    if grep -qF "$marker" "$file" 2>/dev/null; then
        skip "$label already configured"
        return 0
    fi

    printf '\n%s\n' "$line" >> "$file"
    step "$label configured"
}
