#!/usr/bin/env bash
# tools/test-tutorial-e2e.sh — Full user-journey e2e for the Wheels CLI.
#
# Scaffolds a fresh app, boots a server, and runs the tutorial beats as SEPARATE
# CLI invocations (not in-process), asserting each step and the generated HTTP
# surface. This closes the seam that let three recent regressions slip through
# the per-layer tests:
#
#   - serverUrlBase       — the `$`-prefix call in migrate/routes/test's
#                           server-fetch path (only hit against a LIVE server)
#   - scaffold default='' — scaffold codegen output vs the migrator hardener S14
#   - .json/.xml format   — the shipped rewrite.config vs the router's
#                           `.[format]` suffix
#
# Usage:
#   bash tools/test-tutorial-e2e.sh
#   PORT=60107 bash tools/test-tutorial-e2e.sh
#   LUCLI_BIN=/path/to/raw-lucli bash tools/test-tutorial-e2e.sh
#
# Requirements: a raw LuCLI binary (generic `lucli` in CI, or the brew
# `libexec/wheels` locally — NOT the brew `wheels` wrapper, which hardcodes
# LUCLI_HOME), JDK 21, network for the first Lucee Express download. SQLite
# JDBC is staged by `wheels start` automatically.
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PORT="${PORT:-60107}"
SHUTDOWN_PORT="$((PORT + 1))"
APP_NAME="tutorial-e2e"
TMPDIR=$(mktemp -d -t wheels-e2e.XXXXXX)
APP_DIR="$TMPDIR/$APP_NAME"
LUCLI_HOME="$TMPDIR/.lucli"

PASS=0
FAIL=0
pass() { PASS=$((PASS + 1)); echo "  ✓ $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  ✗ $1"; }

cleanup() {
    (cd "$APP_DIR" 2>/dev/null && "$CLI" wheels stop >/dev/null 2>&1 || true) || true
    rm -rf "$TMPDIR"
}
trap cleanup EXIT

# ── Java resolution ────────────────────────────────────────────────────────
# Re-resolve when JAVA_HOME is unset OR points at a stale/nonexistent JDK.
if [ -z "${JAVA_HOME:-}" ] || [ ! -x "$JAVA_HOME/bin/java" ]; then
    if command -v /usr/libexec/java_home >/dev/null 2>&1; then
        CANDIDATE="$(/usr/libexec/java_home -v 21 2>/dev/null || /usr/libexec/java_home 2>/dev/null || true)"
        [ -n "$CANDIDATE" ] && export JAVA_HOME="$CANDIDATE"
    fi
    if { [ -z "${JAVA_HOME:-}" ] || [ ! -x "$JAVA_HOME/bin/java" ]; } && command -v brew >/dev/null 2>&1; then
        BREW_OPENJDK="$(brew --prefix openjdk@21 2>/dev/null || true)"
        if [ -d "$BREW_OPENJDK/libexec/openjdk.jdk/Contents/Home" ]; then
            export JAVA_HOME="$BREW_OPENJDK/libexec/openjdk.jdk/Contents/Home"
        fi
    fi
fi
if [ -z "${JAVA_HOME:-}" ] || [ ! -x "$JAVA_HOME/bin/java" ]; then
    echo "ERROR: JAVA_HOME is unset or invalid — install JDK 21" >&2
    exit 2
fi

# ── Raw LuCLI binary resolution ───────────────────────────────────────────
# We need the RAW self-extracting binary (~40MB shell bootstrap + JAR), which
# honors LUCLI_HOME. The brew `wheels` wrapper is a ~15KB script that hardcodes
# LUCLI_HOME=~/.wheels, so it cannot be used for an isolated worktree module.
file_size() { stat -f%z "$1" 2>/dev/null || stat -c%s "$1" 2>/dev/null || echo 0; }
RAW=""
for candidate in "${LUCLI_BIN:-}" \
    "$(command -v lucli 2>/dev/null || true)" \
    "$(brew --prefix 2>/dev/null || true)/opt/wheels/libexec/wheels" \
    "$(brew --prefix 2>/dev/null || true)/opt/wheels-be/libexec/wheels"; do
    [ -n "$candidate" ] || continue
    [ -x "$candidate" ] || continue
    if [ "$(file_size "$candidate")" -gt 1000000 ]; then
        RAW="$candidate"
        break
    fi
done
if [ -z "$RAW" ]; then
    echo "ERROR: could not locate a raw LuCLI binary. Set LUCLI_BIN=/path/to/lucli" >&2
    exit 2
fi

# Normalize to a generic `lucli`-named binary so invocation is uniform across
# CI (`lucli`) and local brew (libexec/wheels, whose $0 basename is "wheels").
mkdir -p "$TMPDIR/bin"
ln -s "$RAW" "$TMPDIR/bin/lucli"
CLI="$TMPDIR/bin/lucli"
run_cli() { "$CLI" wheels "$@"; }

# ── Isolated module home (worktree cli/lucli as the wheels module) ─────────
export LUCLI_HOME
mkdir -p "$LUCLI_HOME/modules"
# Copy the worktree module. Codegen/crud templates are committed at
# cli/lucli/templates/codegen/, so the copied module is self-contained. A copy
# (not symlink) keeps the worktree clean; the e2e flow doesn't exercise the
# `packages` command that needs the `cli.lucli` real-path ancestor walk.
cp -R "$PROJECT_ROOT/cli/lucli" "$LUCLI_HOME/modules/wheels"
export WHEELS_FRAMEWORK_PATH="$PROJECT_ROOT/vendor/wheels"

# Reuse an existing Lucee Express if available to skip the ~74MB re-download.
for src in "$HOME/.wheels/express" "$HOME/.lucli/express"; do
    if [ -d "$src" ]; then
        ln -s "$src" "$LUCLI_HOME/express"
        break
    fi
done

echo "Raw LuCLI: $RAW"
echo "Port:      $PORT"
echo "JAVA_HOME: $JAVA_HOME"

# ── Beat 1: wheels new ────────────────────────────────────────────────────
echo ""
echo "==> new $APP_NAME"
cd "$TMPDIR"
if run_cli new "$APP_NAME" > "$TMPDIR/new.log" 2>&1; then
    pass "new exited 0"
else
    fail "new failed"
    cat "$TMPDIR/new.log"
    exit 1
fi
[ -d "$APP_DIR" ] && pass "app dir created" || { fail "app dir missing"; exit 1; }

# The scaffolded app must carry the fixed rewrite.config (json/xml excluded
# from the static passthrough) so `.[format]` routes reach the router.
if grep -q 'json|xml' "$APP_DIR/rewrite.config"; then
    fail "rewrite.config still passes json/xml statically"
else
    pass "rewrite.config excludes json/xml from static passthrough"
fi

# Pin the server port + disable the browser open so the e2e run is headless
# and `detectServerPort()` (which reads lucee.json) resolves our isolated port.
perl -0pi -e "s/\"port\": *[0-9]+/\"port\": $PORT/; s/\"shutdownPort\": *[0-9]+/\"shutdownPort\": $SHUTDOWN_PORT/; s/\"openBrowser\": *(true|false)/\"openBrowser\": false/" "$APP_DIR/lucee.json"

cd "$APP_DIR"

# ── Beat 1 (cont): wheels start ───────────────────────────────────────────
echo ""
echo "==> start (--force)"
if run_cli start --force > "$TMPDIR/start.log" 2>&1; then
    pass "start exited 0"
else
    fail "start failed"
    cat "$TMPDIR/start.log"
    exit 1
fi

wait_for_server() {
    # Any HTTP response (including 500 during applicationStop() / first
    # compile after `wheels reload` purges cfclasses) used to count as
    # "up". Require 200 so later beats do not race a half-started app.
    local code=""
    for i in $(seq 1 120); do
        code="$(curl -s -o /dev/null --connect-timeout 2 --max-time 10 -w '%{http_code}' "http://localhost:$PORT/" 2>/dev/null || echo 000)"
        if [ "$code" = "200" ]; then
            return 0
        fi
        sleep 2
    done
    echo "  last HTTP status from /: ${code:-000}"
    return 1
}
if wait_for_server; then
    pass "server up on :$PORT"
else
    fail "server did not become ready"
    exit 1
fi

# Fresh-VM first boot: LuCLI downloads + extracts Lucee Express and boots the
# server before the module's post-start staging can drop the SQLite JDBC into
# the server's OSGi bundles dir (the pre-start staging has no express/ dir to
# target). The running server's bundle scan has already happened, so the first
# `migrate latest` would fail with ClassException org.sqlite.JDBC. Restart once:
# the pre-start staging now finds the bundles dir and stages the JAR before
# Lucee boots. (This is the "seed for the next start" gap the CLI's staging
# documents; the restart is what makes the FIRST start also work.)
run_cli stop > /dev/null 2>&1 || true
if run_cli start --force > "$TMPDIR/restart.log" 2>&1; then
    pass "restart after driver staging exited 0"
else
    fail "restart after driver staging failed"
    cat "$TMPDIR/restart.log"
fi
if wait_for_server; then
    pass "server up after restart on :$PORT"
else
    fail "server did not become ready after restart"
    exit 1
fi

reload_app() {
    # `wheels reload` applicationStop()s; the next request re-runs
    # onApplicationStart. A fixed sleep raced the first-compile of a
    # freshly scaffolded Post model on cold CI runners. Wait for `/`
    # to answer again instead.
    run_cli reload > /dev/null 2>&1 || true
    wait_for_server || true
}

# POST /wheels/console/eval __ping__ until the eval surface is actually
# ready (password + JSON + success=true). `/` coming up is not enough:
# after reload the first eval can still 500 while models compile.
wait_for_console() {
    local password=""
    if [ -f "$APP_DIR/.env" ]; then
        # First matching RELOAD_PASSWORD assignment; strip quotes/CR.
        password="$(grep -E '^(WHEELS_)?RELOAD_PASSWORD=' "$APP_DIR/.env" | head -1 | cut -d= -f2- | tr -d '\r\n\t "')"
    fi
    local i body
    for i in $(seq 1 30); do
        body="$(curl -s --connect-timeout 2 --max-time 10 \
            -X POST -H "Content-Type: application/json" \
            -d "{\"expression\":\"__ping__\",\"password\":\"${password}\"}" \
            "http://localhost:$PORT/wheels/console/eval" 2>/dev/null || true)"
        # serializeJSON key case varies by engine (success vs SUCCESS).
        if printf '%s' "$body" | grep -qiE '"success"[[:space:]]*:[[:space:]]*true'; then
            return 0
        fi
        sleep 2
    done
    echo "  last console ping body: ${body:0:300}"
    return 1
}

# Run one console expression. Fails the check (and dumps the log) when the
# CLI exits non-zero, prints `Error:`, or reports a validation failure —
# so a silent no-op create cannot look like success.
run_console_expr() {
    local expr="$1" label="$2" expect_re="${3:-}"
    local code=0
    # pipefail + set -e would abort the whole script on a non-zero
    # console exit before we can dump the log — capture it instead.
    printf '%s\n' "$expr" | run_cli console > "$TMPDIR/console.log" 2>&1 || code=$?
    if [ "$code" -ne 0 ]; then
        fail "$label — console exited $code"
        cat "$TMPDIR/console.log"
        return 0
    fi
    if grep -q '^Error:' "$TMPDIR/console.log"; then
        fail "$label — console printed Error:"
        cat "$TMPDIR/console.log"
        return 0
    fi
    if grep -q 'Validation failed' "$TMPDIR/console.log"; then
        fail "$label — model validation failed"
        cat "$TMPDIR/console.log"
        return 0
    fi
    if [ -n "$expect_re" ] && ! grep -qiE "$expect_re" "$TMPDIR/console.log"; then
        fail "$label — console output missing /$expect_re/"
        cat "$TMPDIR/console.log"
        return 0
    fi
    pass "$label"
    return 0
}

# ── Beat 2: scaffold Post + migrate + routes ──────────────────────────────
echo ""
echo "==> generate scaffold Post title:string body:text publishedAt:datetime"
run_cli generate scaffold Post title:string body:text publishedAt:datetime > "$TMPDIR/scaffold.log" 2>&1 \
    && pass "scaffold Post exited 0" || { fail "scaffold Post failed"; cat "$TMPDIR/scaffold.log"; }

if grep -Rq "default=''" app/migrator/migrations/ 2>/dev/null; then
    fail "scaffold migration still emits default=''"
else
    pass "scaffold migration has no default=''"
fi

echo "==> migrate latest"
run_cli migrate latest > "$TMPDIR/migrate.log" 2>&1 \
    && pass "migrate latest exited 0" || { fail "migrate latest failed"; cat "$TMPDIR/migrate.log"; }

reload_app
if wait_for_console; then
    pass "console eval endpoint ready after reload"
else
    fail "console eval endpoint not ready after reload"
fi
echo "==> console: create a Post"
# The scaffold adds validatesPresenceOf("title,body,publishedAt"), so pass all three.
# create() returns the model even when validation fails — the CLI now treats
# `_hasErrors` as a failed expression (non-zero on EOF). Also assert the
# row is actually queryable before we look at /posts.
run_console_expr \
    'model("Post").create(title="Console Post", body="Created from the console", publishedAt=Now())' \
    "console create persisted" \
    '_isNew: (false|no)'
run_console_expr \
    'model("Post").count()' \
    "console count of posts is 1" \
    '=> 1'

echo "==> routes"
run_cli routes > "$TMPDIR/routes.log" 2>&1 \
    && pass "routes exited 0" || { fail "routes failed"; cat "$TMPDIR/routes.log"; }
grep -q "posts" "$TMPDIR/routes.log" && pass "routes include posts" || fail "routes missing posts"

# ── .format suffix through the rewrite layer ──────────────────────────────
assert_http() {
    local url="$1" expect="$2" label="$3"
    local code
    code="$(curl -s -o /dev/null --connect-timeout 2 --max-time 15 -w '%{http_code}' "http://localhost:$PORT$url" 2>/dev/null || echo 000)"
    if [ "$code" = "$expect" ]; then
        pass "$label ($code)"
    else
        fail "$label — expected $expect, got $code"
    fi
}
echo ""
echo "==> HTTP surface"
assert_http "/posts" 200 "GET /posts"
assert_http "/posts.json" 200 "GET /posts.json (format suffix)"
POSTS_BODY="$(curl -s --connect-timeout 2 --max-time 15 "http://localhost:$PORT/posts" 2>/dev/null || true)"
# Avoid `printf | grep -q` under `set -o pipefail`: grep -q closes the pipe
# as soon as it matches, printf then SIGPIPEs, and the pipeline is treated
# as a failure even when "Console Post" is in the HTML (debug-bar pages are
# large enough to hit this every time).
if [[ "$POSTS_BODY" == *"Console Post"* ]]; then
    pass "console-created Post appears in /posts"
else
    fail "console-created Post missing from /posts"
    echo "  --- /posts body (first 2k) ---"
    printf '%s\n' "${POSTS_BODY:0:2048}"
    echo "  --- end /posts body ---"
fi

# ── Beat 7: api-resource + .json ──────────────────────────────────────────
echo ""
echo "==> generate api-resource Product name price:decimal sku:string"
run_cli generate api-resource Product name price:decimal sku:string > "$TMPDIR/api.log" 2>&1 \
    && pass "api-resource exited 0" || { fail "api-resource failed"; cat "$TMPDIR/api.log"; }
run_cli migrate latest > "$TMPDIR/migrate2.log" 2>&1 \
    && pass "migrate (api-resource) exited 0" || { fail "migrate (api-resource) failed"; cat "$TMPDIR/migrate2.log"; }
reload_app
assert_http "/api/products" 200 "GET /api/products"
assert_http "/api/products.json" 200 "GET /api/products.json (format suffix)"

# ── Beat 5: auth + migrate ────────────────────────────────────────────────
echo ""
echo "==> generate auth --strategy=session"
run_cli generate auth --strategy=session > "$TMPDIR/auth.log" 2>&1 \
    && pass "auth exited 0" || { fail "auth failed"; cat "$TMPDIR/auth.log"; }
run_cli migrate latest > "$TMPDIR/migrate3.log" 2>&1 \
    && pass "migrate (auth) exited 0" || { fail "migrate (auth) failed"; cat "$TMPDIR/migrate3.log"; }

# ── Beat 6: test ──────────────────────────────────────────────────────────
# `wheels test` hits the isolated `#3374` application (`<name>_wheelsTest`).
# Reloading the *live* app immediately beforehand is unnecessary (the
# isolated app cold-starts from current source) and harmful: `wheels reload`
# wipes Lucee's cfclass cache, then the first TestBox directory scan can
# return 0 bundles. The CLI then reports every on-disk *Spec.cfc as
# "failed to compile" even when the runner JSON is a populate/constructor
# error or an empty discovery — which is what CI showed after the console
# flake was fixed (6 specs, 0 passed, ~2s).
echo ""
echo "==> test"
if wait_for_server; then
    pass "server HTTP 200 before test"
else
    fail "server not HTTP 200 before test"
fi

wait_for_test_app() {
    # Start the isolated test application on a cheap request so `wheels test`
    # is not the first hit after a cfclass purge / live-app restart.
    local i code=""
    for i in $(seq 1 30); do
        code="$(curl -s -o /dev/null --connect-timeout 2 --max-time 30 -w '%{http_code}' \
            -H "X-Wheels-Test-Context: 1" \
            "http://localhost:$PORT/" 2>/dev/null || echo 000)"
        if [ "$code" = "200" ]; then
            return 0
        fi
        sleep 2
    done
    echo "  isolated test app last HTTP status: ${code:-000}"
    return 1
}

dump_test_runner_json() {
    echo "  --- /wheels/app/tests?format=json ---"
    local body
    body="$(curl -s --connect-timeout 2 --max-time 90 \
        "http://localhost:$PORT/wheels/app/tests?format=json&useTestDB=true" 2>/dev/null || true)"
    if command -v python3 >/dev/null 2>&1 && [ -n "$body" ]; then
        printf '%s' "$body" | python3 -c '
import json, sys
raw = sys.stdin.read()
try:
    d = json.loads(raw)
except Exception:
    print(raw[:4096])
    sys.exit(0)
keys = (
    "success", "error", "message", "detail",
    "bundlesDiscovered", "directoryRejected", "directoryResolved",
    "testDirectoryPath", "testDirectoryExists", "warnings",
    "totalPass", "totalFail", "totalError",
)
for k in keys:
    if k in d:
        print("  %s: %r" % (k, d[k]))
snippet = d.get("RootCause") or d.get("rootCause")
if snippet:
    print("  RootCause: %r" % (snippet,))
' || printf '%s\n' "${body:0:4096}"
    else
        printf '%s\n' "${body:0:4096}"
    fi
    echo "  --- end runner JSON ---"
}

run_wheels_test() {
    local code=0
    run_cli test > "$TMPDIR/test.log" 2>&1 || code=$?
    if [ "$code" -ne 0 ]; then
        return 1
    fi
    if grep -q 'failed to load' "$TMPDIR/test.log"; then
        return 1
    fi
    if ! grep -qE '[1-9][0-9]* passed' "$TMPDIR/test.log"; then
        return 1
    fi
    return 0
}

if wait_for_test_app; then
    pass "isolated test app ready"
else
    echo "  WARN isolated test app not HTTP 200 yet; continuing to wheels test"
fi

if run_wheels_test; then
    pass "test exited 0"
else
    echo "  first wheels test attempt failed; dumping runner JSON and retrying"
    dump_test_runner_json
    tail -40 "$TMPDIR/test.log" || true
    wait_for_server || true
    wait_for_test_app || true
    if run_wheels_test; then
        pass "test exited 0 (after retry)"
    else
        fail "test failed"
        dump_test_runner_json
        tail -40 "$TMPDIR/test.log" || true
    fi
fi
grep -qE 'passed' "$TMPDIR/test.log" && pass "test reported results" || fail "test output missing pass count"

# ── Report ────────────────────────────────────────────────────────────────
echo ""
echo "=============================================="
TOTAL=$((PASS + FAIL))
echo "$PASS/$TOTAL checks passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
    echo "TUTORIAL E2E FAILED" >&2
    exit 1
fi
echo "TUTORIAL E2E PASSED"
