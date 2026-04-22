#!/usr/bin/env bash
# Regression test for GH #2211: wheels new must exit non-zero when the
# Wheels framework source cannot be located.
#
# Prerequisites:
#   - wheels binary on PATH
#
# Usage:
#   bash cli/lucli/tests/test-new-exit-codes.sh

# NOTE: no `set -e` — we want to observe non-zero exits from `wheels new`
set -uo pipefail

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

if ! command -v wheels &>/dev/null; then
    echo "ERROR: wheels not found on PATH"
    exit 1
fi

# Isolate from any vendor/wheels/ discoverable via cwd or the binary's module dir.
TMPDIR=$(mktemp -d)
cleanup() { rm -rf "$TMPDIR"; }
trap cleanup EXIT

echo "=== GH #2211: wheels new framework-not-found regression ==="
echo "Working dir: $TMPDIR"
echo ""

cd "$TMPDIR"

# Unset WHEELS_FRAMEWORK_PATH so discovery relies solely on cwd/module root
# (both of which should miss in this temp dir).
unset WHEELS_FRAMEWORK_PATH

OUT=$(wheels new fixture --no-open-browser 2>&1)
CODE=$?

echo "--- output (last 8 lines) ---"
echo "$OUT" | tail -8
echo "--- exit code: $CODE ---"
echo ""

if [ "$CODE" -ne 0 ]; then
    pass "wheels new exits non-zero when framework source is not found"
else
    fail "wheels new exited 0 despite framework-not-found error (GH #2211)"
fi

if echo "$OUT" | grep -qi "WHEELS_FRAMEWORK_PATH"; then
    pass "error message mentions WHEELS_FRAMEWORK_PATH hint"
else
    fail "error message missing WHEELS_FRAMEWORK_PATH hint"
fi

if [ ! -d "$TMPDIR/fixture" ]; then
    pass "no partial fixture/ directory left behind"
else
    fail "partial fixture/ directory left behind"
fi

echo ""
echo "=== Summary: $PASS pass, $FAIL fail ==="
[ "$FAIL" -eq 0 ]
