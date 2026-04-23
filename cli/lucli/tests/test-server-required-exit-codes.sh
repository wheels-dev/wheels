#!/usr/bin/env bash
# Regression tests for commands that require a running Wheels dev server.
#
# GH #2229 — commands that detected "no running server" previously printed a
# red diagnostic and `return ""`, producing exit 0. MCP clients and shell
# automation couldn't distinguish "succeeded with no output" from "server
# down, nothing ran". All such paths now throw `Wheels.ServerNotRunning` via
# the shared `$requireRunningServer()` helper so LuCLI's ExecutionException-
# Handler surfaces a non-zero exit.
#
# Commands exercised (issue-listed + same-bug-pattern paths found in audit):
#   wheels routes          — issue-listed
#   wheels reload          — issue-listed
#   wheels test            — issue-listed (via private runTests)
#   wheels migrate info    — surfaced by audit (same pattern)
#   wheels seed            — surfaced by audit (same pattern)
#   wheels db status       — surfaced by audit (same pattern)
#   wheels db version      — surfaced by audit (same pattern)
#
# `wheels console` is excluded — its success path reads from stdin, so driving
# it from a non-interactive shell test without a server is already covered by
# type-parity with the other throws. (Same rationale as the TemplateNotFound
# case in test-new-exit-codes.sh.)
#
# Prerequisites:
#   - wheels binary on PATH
#   - No Wheels dev server running on 8080/60000/3000/8500
#
# Usage:
#   bash cli/lucli/tests/test-server-required-exit-codes.sh

# NOTE: no `set -e` — we want to observe non-zero exits.
set -uo pipefail

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

if ! command -v wheels &>/dev/null; then
    echo "ERROR: wheels not found on PATH"
    exit 1
fi

# Isolate in a tmpdir so the commands don't find any project files (lucee.json,
# .env) that might hint at a port. The common-port probes (8080/60000/3000/
# 8500) still run, so ensure nothing is listening there before invoking.
TMPDIR=$(mktemp -d)
cleanup() { rm -rf "$TMPDIR"; }
trap cleanup EXIT
cd "$TMPDIR"

check_common_ports() {
    for port in 8080 60000 3000 8500; do
        if (echo > /dev/tcp/127.0.0.1/$port) &>/dev/null; then
            echo "ERROR: something is listening on port $port — stop it before running this test"
            exit 1
        fi
    done
}
check_common_ports

assert_exits_nonzero_with_diagnostic() {
    local label="$1"
    local cmd="$2"

    echo ""
    echo "--- $label ---"
    OUT=$(eval "$cmd" 2>&1)
    CODE=$?

    echo "$OUT" | tail -5
    echo "exit code: $CODE"

    if [ "$CODE" -ne 0 ]; then
        pass "$label exits non-zero"
    else
        fail "$label exited 0 despite no running server"
    fi

    if echo "$OUT" | grep -qi "No running Wheels server"; then
        pass "$label emits 'No running Wheels server' diagnostic"
    else
        fail "$label missing 'No running Wheels server' diagnostic"
    fi
}

echo "=== GH #2229: silent-exit regressions for server-required commands ==="

assert_exits_nonzero_with_diagnostic "wheels routes"       "wheels routes"
assert_exits_nonzero_with_diagnostic "wheels reload"       "wheels reload"
assert_exits_nonzero_with_diagnostic "wheels test"         "wheels test"
assert_exits_nonzero_with_diagnostic "wheels migrate info" "wheels migrate info"
assert_exits_nonzero_with_diagnostic "wheels seed"         "wheels seed"
assert_exits_nonzero_with_diagnostic "wheels db status"    "wheels db status"
assert_exits_nonzero_with_diagnostic "wheels db version"   "wheels db version"

echo ""
echo "=== Summary: $PASS pass, $FAIL fail ==="
[ "$FAIL" -eq 0 ]
