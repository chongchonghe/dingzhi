# Shared setup for every dingzhi bats test.
#
# CRITICAL: this points HOME at a throwaway directory. No test may run without
# calling setup_dingzhi_env first — dingzhi writes to ~/.config, ~/.zshrc, and
# ~/.gitconfig, and a test that skips this would edit the real home.

setup_dingzhi_env() {
    DINGZHI_PATH="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd)"
    export DINGZHI_PATH
    export HOME="$BATS_TEST_TMPDIR/home"
    mkdir -p "$HOME"
    cd "$HOME"
}
