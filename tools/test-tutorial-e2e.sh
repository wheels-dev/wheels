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
    for i in $(seq 1 120); do
        if curl -s -o /dev/null --connect-timeout 2 --max-time 3 "http://localhost:$PORT/" 2>/dev/null; then
            return 0
        fi
        sleep 2
    done
    return 1
}
if wait_for_server; then
    pass "server up on :$PORT"
else
    fail "server did not become ready"
    exit 1
fi

reload_app() {
    run_cli reload > /dev/null 2>&1 || true
    sleep 2
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
echo "==> console: create a Post"
# The scaffold adds validatesPresenceOf("title,body,publishedAt"), so pass all three.
printf '%s\n' 'model("Post").create(title="Console Post", body="Created from the console", publishedAt=Now())' \
    | run_cli console > "$TMPDIR/console.log" 2>&1 \
    && pass "console create exited 0" || { fail "console create failed"; cat "$TMPDIR/console.log"; }

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
if curl -s "http://localhost:$PORT/posts" | grep -q "Console Post"; then
    pass "console-created Post appears in /posts"
else
    fail "console-created Post missing from /posts"
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
reload_app
echo ""
echo "==> test"
run_cli test > "$TMPDIR/test.log" 2>&1 \
    && pass "test exited 0" || { fail "test failed"; tail -40 "$TMPDIR/test.log"; }
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
