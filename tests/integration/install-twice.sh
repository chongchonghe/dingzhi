#!/usr/bin/env bash
# Run the full dingzhi installer twice and assert the second run changes
# nothing. Intended to run INSIDE a test container.
#
#   tests/docker-run.sh --gh-auth -- bash tests/integration/install-twice.sh
#
# --gh-auth is worth passing: the no-root path makes many GitHub API calls,
# and unauthenticated access is capped at 60 per hour per IP.
set -uo pipefail

DINGZHI_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export DINGZHI_NONINTERACTIVE=1
export DINGZHI_GIT_NAME="Test User"
export DINGZHI_GIT_EMAIL="test@example.com"

fail() { echo "FAIL: $*" >&2; exit 1; }

backend="$(bash -c "source '$DINGZHI_PATH/lib/detect.sh' && echo \$DINGZHI_BACKEND")"
echo "### backend: $backend"

echo "### first install"
bash "$DINGZHI_PATH/install.sh" > /tmp/run1.log 2>&1 \
    || { tail -30 /tmp/run1.log; fail "first run exited non-zero"; }
grep -q "All selected apps installed." /tmp/run1.log \
    || { grep '^!!' /tmp/run1.log; fail "first run reported app failures"; }

echo "### doctor after first install"
"$DINGZHI_PATH/bin/dingzhi" doctor > /tmp/doctor1.log 2>&1 || true
grep -q "No problems found." /tmp/doctor1.log \
    || { grep -E "MISSING" /tmp/doctor1.log; fail "doctor reported problems"; }

echo "### second install (must change nothing)"
bash "$DINGZHI_PATH/install.sh" > /tmp/run2.log 2>&1 \
    || { tail -30 /tmp/run2.log; fail "second run exited non-zero"; }

# Idempotency: the second run must not install, link, or clone anything.
if grep -qE '^\s+(installing|linking|cloning|backing up)' /tmp/run2.log; then
    grep -E '^\s+(installing|linking|cloning|backing up)' /tmp/run2.log
    fail "second run did real work; it should have been all skips"
fi

# No file should have been displaced, since everything was already correct.
if ls "$HOME"/*.backup.* >/dev/null 2>&1; then
    fail "second run backed up a file it had already linked"
fi

# The shell rc must be wired exactly once, however many times we run.
for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
    [ -f "$rc" ] || continue
    n="$(grep -c 'dingzhi/configs/shell/init.sh' "$rc" || true)"
    [ "$n" -le 1 ] || fail "$rc has $n dingzhi source lines; expected at most 1"
done

echo "### doctor after second install"
"$DINGZHI_PATH/bin/dingzhi" doctor >/dev/null 2>&1 || fail "doctor failed after re-run"

# The shipped utilities must actually run, not merely be present.
echo "### shipped utilities"
tmp="$(mktemp -d)"
printf '# Title\n\nBody.\n' > "$tmp/in.md"
"$DINGZHI_PATH/bin/myconvert" "$tmp/in.md" "$tmp/out.html" >/dev/null 2>&1 \
    || fail "myconvert md->html failed"
grep -q '<h1' "$tmp/out.html" || fail "myconvert produced no heading"
rm -rf "$tmp"

echo "### PASS: install is idempotent on backend $backend"
