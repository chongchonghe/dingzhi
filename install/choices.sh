#!/usr/bin/env bash
# The only app-selection prompts dingzhi asks. Choices persist, so re-running
# the installer is non-interactive.
#
# Sets: DINGZHI_GROUPS DINGZHI_SHELLS DINGZHI_STATE
# Requires lib/ui.sh.

DINGZHI_STATE="${XDG_STATE_HOME:-$HOME/.local/state}/dingzhi"
export DINGZHI_STATE
mkdir -p "$DINGZHI_STATE"

DINGZHI_ALL_GROUPS="core terminal editors git filemanagers shell dev media misc"

if [ -f "$DINGZHI_STATE/choices" ]; then
    # The keys are DINGZHI_-prefixed on purpose: bash has a builtin GROUPS
    # array (the user's group IDs), and a bare GROUPS= here would collide.
    # shellcheck disable=SC1091
    . "$DINGZHI_STATE/choices"
    skip "using saved choices from $DINGZHI_STATE/choices"
else
    # shellcheck disable=SC2086
    DINGZHI_GROUPS="$(choose_multi \
        "Which app groups do you want?" \
        "core,terminal,editors,git,filemanagers,shell,dev,media,misc" \
        $DINGZHI_ALL_GROUPS | tr '\n' ' ')"
    DINGZHI_GROUPS="${DINGZHI_GROUPS% }"

    DINGZHI_SHELLS="$(choose_multi \
        "Which shells should dingzhi configure?" \
        "zsh" \
        zsh bash | tr '\n' ' ')"
    DINGZHI_SHELLS="${DINGZHI_SHELLS% }"

    # Quoted, so the file is safe to source back in with `.`.
    {
        printf 'DINGZHI_GROUPS="%s"\n' "$DINGZHI_GROUPS"
        printf 'DINGZHI_SHELLS="%s"\n' "$DINGZHI_SHELLS"
    } > "$DINGZHI_STATE/choices"
fi

export DINGZHI_GROUPS DINGZHI_SHELLS
say "Groups: $DINGZHI_GROUPS"
say "Shells: $DINGZHI_SHELLS"
