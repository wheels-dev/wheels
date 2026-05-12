#!/usr/bin/env bash
# Regression tests for wheels new exit-code contracts.
#
#   GH #2211 — framework source not found anywhere must exit non-zero
#   GH #2215 — explicit WHEELS_FRAMEWORK_PATH pointing at a non-existent
#              directory must hard-fail (not silently fall through to
#              auto-discovery)
#   GH #2214 — target directory already exists must exit non-zero
#   GH #2214 — app name missing (args supplied but none parsed) must exit non-zero
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
echo "=== GH #2215: invalid WHEELS_FRAMEWORK_PATH must hard-fail ==="
echo ""

# Fresh subdir so a leftover fixture/ from case #2211 doesn't poison the check.
SUBDIR="$TMPDIR/case-2215"
mkdir -p "$SUBDIR"
cd "$SUBDIR"

BAD_PATH="$SUBDIR/does-not-exist/vendor/wheels"
export WHEELS_FRAMEWORK_PATH="$BAD_PATH"

OUT=$(wheels new fixture --no-open-browser 2>&1)
CODE=$?

echo "--- output (last 8 lines) ---"
echo "$OUT" | tail -8
echo "--- exit code: $CODE ---"
echo ""

if [ "$CODE" -ne 0 ]; then
    pass "wheels new exits non-zero when WHEELS_FRAMEWORK_PATH is invalid"
else
    fail "wheels new exited 0 despite invalid WHEELS_FRAMEWORK_PATH (GH #2215)"
fi

if echo "$OUT" | grep -qF "$BAD_PATH"; then
    pass "error message echoes the invalid path"
else
    fail "error message does not mention the invalid path"
fi

if [ ! -d "$SUBDIR/fixture" ]; then
    pass "no partial fixture/ directory left behind (case 2215)"
else
    fail "partial fixture/ directory left behind (case 2215)"
fi

unset WHEELS_FRAMEWORK_PATH

echo ""
echo "=== GH #2214: wheels new target-directory-exists regression ==="

# Use a second tmpdir so we have a predictable pre-existing directory and a
# discoverable framework source (so the only failure surface is the dir check).
TMPDIR2=$(mktemp -d)
cleanup2() { rm -rf "$TMPDIR2"; }
trap 'cleanup; cleanup2' EXIT

# Point at this repo's checkout so we bypass the framework-not-found path
# and exercise only the target-directory-exists path. Resolve the repo root
# relative to this script so it works regardless of cwd.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
if [ -d "$REPO_ROOT/vendor/wheels" ]; then
    export WHEELS_FRAMEWORK_PATH="$REPO_ROOT/vendor/wheels"
else
    echo "  SKIP: could not locate vendor/wheels from $REPO_ROOT — skipping #2214 dir-exists case"
    echo ""
    echo "=== Summary: $PASS pass, $FAIL fail (dir-exists case skipped) ==="
    [ "$FAIL" -eq 0 ] && exit 0 || exit 1
fi

cd "$TMPDIR2"
mkdir collision
OUT=$(wheels new collision --no-open-browser 2>&1)
CODE=$?

echo "--- output (last 6 lines) ---"
echo "$OUT" | tail -6
echo "--- exit code: $CODE ---"
echo ""

if [ "$CODE" -ne 0 ]; then
    pass "wheels new exits non-zero when target directory already exists"
else
    fail "wheels new exited 0 despite target-directory-exists error (GH #2214)"
fi

if echo "$OUT" | grep -qi "already exists"; then
    pass "error message mentions 'already exists'"
else
    fail "error message missing 'already exists' diagnostic"
fi

echo ""
echo "=== GH #2214: wheels new app-name-missing regression ==="

cd "$TMPDIR2"
# Args supplied, but none parse as an app name. The zero-args path still
# prints usage and exits 0 (see issue "Not in scope"); this case must throw.
OUT=$(wheels new --port=3000 --no-open-browser 2>&1)
CODE=$?

echo "--- output (last 6 lines) ---"
echo "$OUT" | tail -6
echo "--- exit code: $CODE ---"
echo ""

if [ "$CODE" -ne 0 ]; then
    pass "wheels new exits non-zero when args supplied but no app name parsed"
else
    fail "wheels new exited 0 despite missing app name (GH #2214)"
fi

if echo "$OUT" | grep -qi "app name is required"; then
    pass "error message mentions 'app name is required'"
else
    fail "error message missing 'app name is required' diagnostic"
fi

echo ""
echo "=== Summary: $PASS pass, $FAIL fail ==="
[ "$FAIL" -eq 0 ]
