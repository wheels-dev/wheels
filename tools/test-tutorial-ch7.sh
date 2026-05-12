#!/usr/bin/env bash
# tools/test-tutorial-ch7.sh — Canary for chapter 7's `wheels test` story.
#
# Scaffolds a fresh app, drops a chapter-6-equivalent user into the dev DB,
# adds a minimal model spec, and runs `wheels test`. Verifies:
#
# 1. wheels test succeeds (exit 0)
# 2. The test runs against db/test.sqlite, not db/development.sqlite —
#    chapter 6's manual `[email protected]` in the dev DB does NOT bleed
#    into the test run.
# 3. tests/populate.cfm shipped with `wheels new` (so the user doesn't
#    have to write it themselves).
# 4. The test DB has the schema after the run (auto-bootstrapped from
#    populate.cfm).
#
# This is the canary that fails before users see the chapter-7 break.
# Browser-spec coverage (the full SignupFlowSpec from chapter 7) requires
# Playwright JARs and is left as a follow-up enhancement.
#
# Usage:
#   bash tools/test-tutorial-ch7.sh
#   KEEP_TEMP=1 bash tools/test-tutorial-ch7.sh   # preserve harness dir
#   PORT=9876 bash tools/test-tutorial-ch7.sh     # custom port

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PORT="${PORT:-9876}"
APP_NAME="ch7-canary"
HARNESS_TMP=$(mktemp -d)

PASS=0
FAIL=0

cleanup() {
    if [[ -n "${SERVER_PID:-}" ]]; then
        kill "$SERVER_PID" 2>/dev/null || true
        wait "$SERVER_PID" 2>/dev/null || true
    fi
    if [[ "${KEEP_TEMP:-0}" != "1" ]]; then
        rm -rf "$HARNESS_TMP"
    else
        echo "Preserved harness dir: $HARNESS_TMP"
    fi
}
trap cleanup EXIT

check() {
    local label="$1"
    local condition="$2"
    if eval "$condition"; then
        echo "  ✓ $label"
        PASS=$((PASS + 1))
    else
        echo "  ✗ $label"
        FAIL=$((FAIL + 1))
    fi
}

echo "==> Phase 1: scaffold app"
cd "$HARNESS_TMP"
WHEELS_FRAMEWORK_PATH="$PROJECT_ROOT/vendor/wheels" wheels new "$APP_NAME" --no-open-browser >/dev/null
cd "$APP_NAME"

check "tests/populate.cfm shipped with wheels new" \
    '[ -f tests/populate.cfm ]'

check "db/test.sqlite scaffolded as separate file" \
    '[ -f db/test.sqlite ]'

echo "==> Phase 2: chapter-2 minimum (model + migrate)"
wheels generate model Post title:string body:text >/dev/null
wheels migrate latest >/dev/null

check "dev DB has posts table after migrate" \
    'sqlite3 db/development.sqlite ".tables" | grep -q posts'

check "test DB still empty before wheels test" \
    '[ -z "$(sqlite3 db/test.sqlite ".tables" 2>/dev/null | grep -E "^posts$" || true)" ]'

echo "==> Phase 3: chapter-6 equivalent (seed [email protected] in DEV DB)"
sqlite3 db/development.sqlite "INSERT INTO posts (title, body, createdat, updatedat) VALUES ('Chapter-6 contamination', 'should not appear in test DB', datetime('now'), datetime('now'));"

DEV_COUNT=$(sqlite3 db/development.sqlite "SELECT count(*) FROM posts")
check "dev DB has 1 post (the contamination row)" \
    '[ "$DEV_COUNT" = "1" ]'

echo "==> Phase 4: write a minimal app spec that asserts on the post count"
cat > tests/specs/PostsCountSpec.cfc <<'CFM'
component extends="wheels.WheelsTest" {
    function run() {
        describe("test DB isolation", () => {
            it("starts with 0 posts (dev-DB contamination must not bleed in)", () => {
                var posts = model("Post").findAll();
                expect(posts.recordCount).toBe(0);
            });
        });
    }
}
CFM

echo "==> Phase 5: boot server + run wheels test (default useTestDB=true)"
wheels start --port="$PORT" >/dev/null 2>&1 &
SERVER_PID=$!
sleep 6

set +e
TEST_OUTPUT=$(wheels test 2>&1)
TEST_EXIT=$?
set -e

echo "$TEST_OUTPUT" | tail -3 | sed 's/^/    /'

check "wheels test exited 0" \
    '[ "$TEST_EXIT" = "0" ]'

check "wheels test output reports 1 passed" \
    'echo "$TEST_OUTPUT" | grep -qE "1 passed"'

check "test DB now has posts table (auto-bootstrapped from populate.cfm)" \
    'sqlite3 db/test.sqlite ".tables" | grep -q posts'

TEST_COUNT=$(sqlite3 db/test.sqlite "SELECT count(*) FROM posts" 2>/dev/null || echo "?")
check "test DB has 0 posts (proves the contamination row stayed in dev)" \
    '[ "$TEST_COUNT" = "0" ]'

echo "==> Phase 6: verify --no-test-db opts back to dev DB"
set +e
NO_TEST_OUTPUT=$(wheels test --no-test-db 2>&1)
NO_TEST_EXIT=$?
set -e

# When --no-test-db is set, the spec runs against the dev DB which has 1
# row, so the assertion `posts.recordCount.toBe(0)` should now FAIL.
check "wheels test --no-test-db hits dev DB (spec fails on contamination row)" \
    '[ "$NO_TEST_EXIT" != "0" ]'

echo "==> Summary: $PASS passed, $FAIL failed"

if [[ $FAIL -ne 0 ]]; then
    echo "FAIL: chapter-7 canary harness detected regressions in test-DB isolation."
    exit 1
fi

echo "PASS: chapter-7 canary green — wheels test isolates dev/test databases."
