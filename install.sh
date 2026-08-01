#!/usr/bin/env bash
# dingzhi installer.
#
#   bash install.sh                 full install
#   source install.sh --lib-only    load libraries and helpers, install nothing
#
# Environment:
#   DINGZHI_NONINTERACTIVE=1  accept all defaults, prompt for nothing
#   DINGZHI_BACKEND=...       force brew | apt | noroot
#   DINGZHI_GIT_NAME/EMAIL    supply the git identity without prompting

set -e

DINGZHI_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DINGZHI_PATH

# shellcheck source=lib/detect.sh
. "$DINGZHI_PATH/lib/detect.sh"
# shellcheck source=lib/ui.sh
. "$DINGZHI_PATH/lib/ui.sh"
# shellcheck source=lib/pkg.sh
. "$DINGZHI_PATH/lib/pkg.sh"
# shellcheck source=lib/link.sh
. "$DINGZHI_PATH/lib/link.sh"

# dingzhi_app_group <app> -> the group declared on line 2 of its install.sh
dingzhi_app_group() {
    sed -n '2s/^# group: //p' "$DINGZHI_PATH/apps/$1/install.sh"
}

# dingzhi_apps_in_group <group> -> app names, one per line
dingzhi_apps_in_group() {
    local want="$1" d name
    for d in "$DINGZHI_PATH"/apps/*/; do
        name="$(basename "$d")"
        [ "$(dingzhi_app_group "$name")" = "$want" ] && printf '%s\n' "$name"
    done
    return 0
}

# dingzhi_all_apps -> every app name, one per line
dingzhi_all_apps() {
    local d
    for d in "$DINGZHI_PATH"/apps/*/; do
        basename "$d"
    done
}

# Sourced with --lib-only: stop here, having defined everything.
case "${1:-}" in
    --lib-only)
        # shellcheck disable=SC2317  # the exit is reached only when executed
        return 0 2>/dev/null || exit 0
        ;;
esac

trap 'echo "!! dingzhi installation failed. Retry with: bash $DINGZHI_PATH/install.sh" >&2' ERR

say "dingzhi $(cat "$DINGZHI_PATH/version")"

. "$DINGZHI_PATH/install/check-system.sh"
. "$DINGZHI_PATH/install/bootstrap.sh"
. "$DINGZHI_PATH/install/choices.sh"
. "$DINGZHI_PATH/install/identification.sh"

say "Installing applications"

DINGZHI_FAILED=""
for _group in $DINGZHI_GROUPS; do
    for _app in $(dingzhi_apps_in_group "$_group"); do
        step "$_app"
        # Each app runs in a subshell, so a `set -e` abort inside one cannot
        # end the run. One broken installer must not cost the user the other 32.
        if ! ( . "$DINGZHI_PATH/apps/$_app/install.sh" ); then
            warn "$_app failed"
            DINGZHI_FAILED="$DINGZHI_FAILED $_app"
        fi
    done
done
unset _group _app

link_summary

if [ -n "$DINGZHI_FAILED" ]; then
    warn "These apps failed:$DINGZHI_FAILED"
    warn "Re-run 'dingzhi install' to retry them individually."
else
    say "All selected apps installed."
fi

say "Done. Open a new terminal, or run: exec \$SHELL -l"
