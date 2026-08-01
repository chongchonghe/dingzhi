#!/usr/bin/env bash
# Output and prompt helpers. Prints and asks; never installs or writes config.
#
# Set DINGZHI_NONINTERACTIVE=1 to accept every default without prompting.

say()  { printf '==> %s\n' "$*"; }
step() { printf '    %s\n' "$*"; }
skip() { printf '    [skip] %s\n' "$*"; }
warn() { printf '!! %s\n' "$*" >&2; }
die()  { printf '!! %s\n' "$*" >&2; exit 1; }

_have_gum() { command -v gum >/dev/null 2>&1; }

# choose_multi <header> <default_csv> <item>...
# Prints the selected items, one per line.
choose_multi() {
    local header="$1" defaults="$2"
    shift 2

    if [ "${DINGZHI_NONINTERACTIVE:-0}" = "1" ] || ! _have_gum; then
        # Emit the defaults in the order the items were declared, keeping only
        # those actually on offer. Commas around both sides make this an exact
        # match, so "core" never selects "coreutils".
        local item
        for item in "$@"; do
            case ",$defaults," in
                *",$item,"*) printf '%s\n' "$item" ;;
            esac
        done
        return 0
    fi

    gum choose "$@" \
        --no-limit \
        --selected "$defaults" \
        --height "$(( $# + 2 ))" \
        --header "$header"
}

# prompt <question> <default>
# Prints the answer.
prompt() {
    local question="$1" default="$2" answer

    if [ "${DINGZHI_NONINTERACTIVE:-0}" = "1" ]; then
        printf '%s\n' "$default"
        return 0
    fi

    if _have_gum; then
        answer="$(gum input --placeholder "$default" --prompt "$question: ")"
    else
        # The prompt goes to stderr so it does not pollute the captured answer.
        printf '%s [%s]: ' "$question" "$default" >&2
        read -r answer
    fi

    [ -n "$answer" ] || answer="$default"
    printf '%s\n' "$answer"
}

# confirm <question> -> 0 for yes, 1 for no
confirm() {
    local question="$1" answer

    [ "${DINGZHI_NONINTERACTIVE:-0}" = "1" ] && return 0

    if _have_gum; then
        gum confirm "$question"
        return $?
    fi

    printf '%s [y/N]: ' "$question" >&2
    read -r answer
    case "$answer" in
        [yY]|[yY][eE][sS]) return 0 ;;
        *) return 1 ;;
    esac
}
