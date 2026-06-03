#!/usr/bin/env bash
# Verifies the exact command pr.yml uses to lint a PR title.
# Good titles pass; bad titles (no type, >100 chars, ALL-CAPS) fail.
set -uo pipefail
cd "$(dirname "$0")/.."

run() { echo "$1" | npx --no-install commitlint --verbose >/dev/null 2>&1; }

fail=0
assert_pass() { if run "$1"; then echo "ok  (pass): $1"; else echo "FAIL (should pass): $1"; fail=1; fi; }
assert_fail() { if run "$1"; then echo "FAIL (should fail): $1"; fail=1; else echo "ok  (fail): $1"; fi; }

assert_pass "fix(model): correct association eager loading"
assert_pass "docs(web/guides): document reserved CFML scope names"
assert_pass "feat: add route model binding"
assert_fail "just a plain sentence with no type"
assert_fail "FIX(model): THIS IS ALL CAPS SUBJECT"
assert_fail "docs(web/guides): note that framework helpers are automatically excluded from the routable action surface"

exit $fail
