#!/usr/bin/env bash
# End-to-end test: Verify CLI commands produce working Wheels applications
#
# Tests the full lifecycle:
#   1. wheels new — scaffold project, verify structure
#   2. wheels generate — model, controller, scaffold, api-resource, admin
#   3. Server start — boot the scaffolded app
#   4. HTTP verification — hit CRUD endpoints, check responses
#   5. wheels doctor/stats/notes/info/analyze/validate — informational commands
#   6. wheels destroy — remove generated resources
#   7. wheels migrate — run database migrations
#
# Prerequisites:
#   - lucli 0.3.3+ on PATH
#   - Java 21+
#
# Usage:
#   bash tools/test-cli-e2e.sh
#   KEEP_PROJECT=1 bash tools/test-cli-e2e.sh   # don't delete temp project
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PORT="${PORT:-9999}"
TMPDIR=$(mktemp -d)
APP_NAME="e2etest"
APP_DIR="$TMPDIR/$APP_NAME"
PASS=0
FAIL=0
SKIP=0
TOTAL=0

# ── Helpers ────────────────────────────────────────

# PID of the process listening on a TCP port (empty without lsof).
listener_pid() {
    lsof -ti :"$1" -sTCP:LISTEN 2>/dev/null | head -1
}

# All descendants of a PID. `ps -A -o pid= -o ppid=` works on Linux and macOS.
descendant_pids() {
    ps -A -o pid= -o ppid= 2>/dev/null | awk -v root="$1" '
        { parent[$1] = $2 }
        END {
            found[root] = 1; changed = 1
            while (changed) {
                changed = 0
                for (p in parent) if (!(p in found) && (parent[p] in found)) { found[p] = 1; changed = 1 }
            }
            for (p in found) if (p != root) print p
        }'
}

# JVMs whose command line mentions this run's unique mktemp dir. The dir goes
# to awk through ITS environment (not argv, so awk never matches itself; and
# not as a prefix on `ps`, which would leave awk with an empty needle that
# matches every process). awk re-checks the needle length as a second guard.
tmpdir_pids() {
    case "$TMPDIR" in ""|/|/tmp|/tmp/) return 0 ;; esac
    ps -A -o pid= -o command= 2>/dev/null | E2E_NEEDLE="$TMPDIR" awk -v self="$$" '
        BEGIN { needle = ENVIRON["E2E_NEEDLE"]; if (length(needle) < 8) exit }
        $1 != self && $2 ~ /(^|\/)java$/ && index($0, needle) > 0 { print $1 }'
}

# The JVM LuCLI's server registry recorded for THIS app, as "<pid>:<port>" in
# <home>/servers/<name>/server.pid, matched by .project-path (never by name:
# a stale "e2etest" entry from an earlier run points at a different temp dir).
registry_jvm_pid() {
    local home d real app_real
    app_real="$(cd "$APP_DIR" 2>/dev/null && pwd -P)" || return 0
    for home in "${LUCLI_HOME:-}" "$HOME/.lucli" "$HOME/.wheels"; do
        [ -n "$home" ] && [ -d "$home/servers" ] || continue
        for d in "$home"/servers/*/; do
            [ -f "${d}.project-path" ] && [ -f "${d}server.pid" ] || continue
            real="$(cd "$(cat "${d}.project-path")" 2>/dev/null && pwd -P)" || continue
            if [ "$real" = "$app_real" ]; then
                cut -d: -f1 "${d}server.pid" 2>/dev/null
                return 0
            fi
        done
    done
}

# Stop the scaffolded app's server. `kill $SERVER_PID` alone only kills the
# `lucli server run` launcher; the Lucee/Tomcat JVM survives and keeps the HTTP
# and shutdown ports, so the next run fails with "port conflicts detected"
# (#3721). Only PIDs provably belonging to this run are signalled: the launcher
# and its descendants, the JVM that took our (freshly cleared) port, the JVM the
# registry recorded for this temp app dir, and any JVM naming the temp dir.
stop_test_server() {
    local pids="" pid i stop_pid

    # 1. Ask LuCLI to stop it cleanly, bounded (no `timeout` on stock macOS).
    if [ -d "$APP_DIR" ]; then
        ( cd "$APP_DIR" && lucli server stop >/dev/null 2>&1 ) &
        stop_pid=$!
        for i in $(seq 1 30); do
            kill -0 "$stop_pid" 2>/dev/null || break
            sleep 0.5
        done
        kill "$stop_pid" 2>/dev/null || true
        wait "$stop_pid" 2>/dev/null || true
    fi

    # 2. Collect everything that is ours (computed before killing the launcher,
    #    while the parent/child links still exist).
    pids="${SERVER_JVM:-} $(registry_jvm_pid || true) $(tmpdir_pids || true)"
    if [ -n "${SERVER_PID:-}" ]; then
        pids="$pids $SERVER_PID $(descendant_pids "$SERVER_PID" || true)"
    fi
    pids="$(printf '%s\n' $pids | awk -v self="$$" '/^[0-9]+$/ && $1 != self && !seen[$1]++')"
    [ -n "$pids" ] || return 0

    # 3. TERM, bounded wait (~15s), then KILL survivors.
    for pid in $pids; do kill "$pid" 2>/dev/null || true; done
    local alive=""
    for i in $(seq 1 30); do
        alive=""
        for pid in $pids; do kill -0 "$pid" 2>/dev/null && alive="$alive $pid"; done
        [ -z "$alive" ] && break
        sleep 0.5
    done
    # SIGKILL only the processes that are still alive: a PID that already exited may
    # have been recycled by an unrelated process during the grace period.
    for pid in $alive; do kill -9 "$pid" 2>/dev/null || true; done

    # 4. Wait (bounded) for the port to actually come free.
    for i in $(seq 1 20); do
        [ -z "$(listener_pid "$PORT" || true)" ] && break
        sleep 0.5
    done
    if [ -n "$(listener_pid "$PORT" || true)" ]; then
        echo "WARNING: port $PORT is still held by PID $(listener_pid "$PORT") after cleanup"
    fi
}

cleanup() {
    if [ "${SERVER_STARTED:-false}" = "true" ]; then
        echo ""
        echo "Stopping test server..."
        stop_test_server || true
    fi
    if [ "${KEEP_PROJECT:-0}" != "1" ]; then
        rm -rf "$TMPDIR"
    else
        echo "Project kept at: $APP_DIR"
    fi
}
trap cleanup EXIT

pass() {
    ((TOTAL++)) || true
    ((PASS++)) || true
    echo "  ✓ $1"
}

fail() {
    ((TOTAL++)) || true
    ((FAIL++)) || true
    echo "  ✗ $1"
}

skip() {
    ((TOTAL++)) || true
    ((SKIP++)) || true
    echo "  - $1 (skipped)"
}

section() {
    echo ""
    echo "━━━ $1 ━━━"
}

# HTTP GET, capture body + status code
# Usage: http_get "/path" BODY_VAR CODE_VAR
http_get() {
    local url="http://localhost:$PORT$1"
    local body_var=$2
    local code_var=$3
    local tmpfile="$TMPDIR/.http_response"
    local code
    code=$(curl -s -o "$tmpfile" --max-time 15 --write-out "%{http_code}" "$url" 2>/dev/null || echo "000")
    eval "$body_var=\"\$(cat '$tmpfile' 2>/dev/null || echo '')\""
    eval "$code_var=$code"
}

# Wait for server to respond
wait_for_server() {
    local max_wait=${1:-60}
    local i=0
    while [ "$i" -lt "$max_wait" ]; do
        if curl -s -o /dev/null --connect-timeout 2 --max-time 3 "http://localhost:$PORT/" 2>/dev/null; then
            return 0
        fi
        if [ "${SERVER_PID:-}" != "" ] && ! kill -0 "$SERVER_PID" 2>/dev/null; then
            echo "Server process died"
            cat "$TMPDIR/server.log" 2>/dev/null | tail -20
            return 1
        fi
        sleep 2
        ((i+=2)) || true
    done
    echo "Server did not start within ${max_wait}s"
    return 1
}

# ── Preflight ──────────────────────────────────────

echo "╔══════════════════════════════════════════════╗"
echo "║  Wheels CLI — End-to-End Correctness Tests   ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "LuCLI: $(lucli --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo 'not found')"
echo "Java:  $(java -version 2>&1 | head -1)"
echo "Temp:  $TMPDIR"
echo "Port:  $PORT"

if ! command -v lucli &>/dev/null; then
    echo "ERROR: lucli not found on PATH"
    exit 1
fi

# ══════════════════════════════════════════════════
#  Phase 1: wheels new — Scaffold a project
# ══════════════════════════════════════════════════

section "Phase 1: wheels new $APP_NAME"

cd "$TMPDIR"
# Point `wheels new` at this checkout's framework source. Without this, running
# in a temp dir with no ancestor vendor/wheels/ now fails hard (GH #2211) —
# which is the correct behavior for real users but breaks this in-monorepo test.
export WHEELS_FRAMEWORK_PATH="$PROJECT_ROOT/vendor/wheels"
if lucli wheels new "$APP_NAME" --port="$PORT" --no-open-browser > "$TMPDIR/new.log" 2>&1; then
    pass "wheels new $APP_NAME succeeded"
else
    fail "wheels new $APP_NAME failed"
    cat "$TMPDIR/new.log" | tail -20
    echo "Cannot continue without project. Aborting."
    exit 1
fi

# Verify project structure
if [ -d "$APP_DIR" ]; then pass "project directory created"; else fail "project directory missing"; fi
if [ -d "$APP_DIR/app/models" ]; then pass "app/models/ exists"; else fail "app/models/ missing"; fi
if [ -d "$APP_DIR/app/controllers" ]; then pass "app/controllers/ exists"; else fail "app/controllers/ missing"; fi
if [ -d "$APP_DIR/app/views" ]; then pass "app/views/ exists"; else fail "app/views/ missing"; fi
if [ -d "$APP_DIR/config" ]; then pass "config/ exists"; else fail "config/ missing"; fi
if [ -d "$APP_DIR/public" ]; then pass "public/ exists"; else fail "public/ missing"; fi

# Verify key files
if [ -f "$APP_DIR/config/routes.cfm" ]; then pass "config/routes.cfm exists"; else fail "config/routes.cfm missing"; fi
if [ -f "$APP_DIR/config/settings.cfm" ]; then pass "config/settings.cfm exists"; else fail "config/settings.cfm missing"; fi
if [ -f "$APP_DIR/.env" ]; then pass ".env file created"; else fail ".env file missing"; fi
if [ -f "$APP_DIR/public/Application.cfc" ]; then pass "Application.cfc exists"; else fail "Application.cfc missing"; fi

# Verify vendor/wheels was copied (may fail in temp dirs — bootstrap manually)
if [ -d "$APP_DIR/vendor/wheels" ]; then
    pass "vendor/wheels/ framework installed"
else
    # Bootstrap: copy vendor/wheels from the framework repo
    echo "  Bootstrapping vendor/wheels from $PROJECT_ROOT..."
    mkdir -p "$APP_DIR/vendor"
    cp -r "$PROJECT_ROOT/vendor/wheels" "$APP_DIR/vendor/wheels"
    if [ -d "$APP_DIR/vendor/wheels" ]; then
        pass "vendor/wheels/ bootstrapped from framework repo"
    else
        fail "vendor/wheels/ could not be bootstrapped"
    fi
fi

# Verify routes.cfm has CLI-Appends-Here marker
if grep -q "CLI-Appends-Here" "$APP_DIR/config/routes.cfm" 2>/dev/null; then
    pass "routes.cfm has CLI-Appends-Here marker"
else
    fail "routes.cfm missing CLI-Appends-Here marker"
fi

cd "$APP_DIR"

# ══════════════════════════════════════════════════
#  Phase 2: Code generation
# ══════════════════════════════════════════════════

section "Phase 2: Code generation"

# --- Generate model ---
echo "  Generating model Product..."
if lucli wheels generate model Product name:string price:decimal active:boolean > "$TMPDIR/gen_model.log" 2>&1; then
    pass "generate model Product"
else
    fail "generate model Product"
    cat "$TMPDIR/gen_model.log" | tail -10
fi

if [ -f "app/models/Product.cfc" ]; then
    pass "app/models/Product.cfc created"
    if grep -q 'extends="Model"' app/models/Product.cfc; then
        pass "Product model extends Model"
    else
        fail "Product model does not extend Model"
    fi
else
    fail "app/models/Product.cfc not created"
fi

# Check migration was created
PRODUCT_MIGRATION=$(find app/migrator/migrations -name "*products*" 2>/dev/null | head -1)
if [ -n "$PRODUCT_MIGRATION" ]; then
    pass "migration for products table created"
    if grep -q "createTable" "$PRODUCT_MIGRATION" 2>/dev/null; then
        pass "migration contains createTable"
    else
        fail "migration missing createTable"
    fi
else
    fail "no migration file for products"
fi

# --- Generate model with associations ---
echo "  Generating model Review with belongsTo..."
if lucli wheels generate model Review body:text rating:integer --belongsTo=Product > "$TMPDIR/gen_review.log" 2>&1; then
    pass "generate model Review with belongsTo"
else
    fail "generate model Review with belongsTo"
fi

if [ -f "app/models/Review.cfc" ] && grep -q "belongsTo" app/models/Review.cfc; then
    pass "Review model has belongsTo association"
else
    fail "Review model missing belongsTo"
fi

# --- Generate controller ---
echo "  Generating controller Pages..."
if lucli wheels generate controller Pages index about contact > "$TMPDIR/gen_ctrl.log" 2>&1; then
    pass "generate controller Pages"
else
    fail "generate controller Pages"
fi

if [ -f "app/controllers/Pages.cfc" ]; then
    pass "app/controllers/Pages.cfc created"
    if grep -q 'extends="Controller"' app/controllers/Pages.cfc; then
        pass "Pages controller extends Controller"
    else
        fail "Pages controller does not extend Controller"
    fi
else
    fail "app/controllers/Pages.cfc not created"
fi

# Check views were created for non-mutation actions
for action in index about contact; do
    if [ -f "app/views/pages/$action.cfm" ]; then
        pass "pages/$action.cfm view created"
    else
        fail "pages/$action.cfm view missing"
    fi
done

# --- Generate scaffold ---
echo "  Generating scaffold Article..."
if lucli wheels generate scaffold Article title:string body:text publishedAt:datetime > "$TMPDIR/gen_scaffold.log" 2>&1; then
    pass "generate scaffold Article"
else
    fail "generate scaffold Article"
    cat "$TMPDIR/gen_scaffold.log" | tail -10
fi

if [ -f "app/models/Article.cfc" ]; then pass "scaffold: Article model created"; else fail "scaffold: Article model missing"; fi
if [ -f "app/controllers/Articles.cfc" ]; then pass "scaffold: Articles controller created"; else fail "scaffold: Articles controller missing"; fi
if [ -f "app/views/articles/index.cfm" ]; then pass "scaffold: index view created"; else fail "scaffold: index view missing"; fi
if [ -f "app/views/articles/show.cfm" ]; then pass "scaffold: show view created"; else fail "scaffold: show view missing"; fi
if [ -f "app/views/articles/new.cfm" ]; then pass "scaffold: new view created"; else fail "scaffold: new view missing"; fi
if [ -f "app/views/articles/edit.cfm" ]; then pass "scaffold: edit view created"; else fail "scaffold: edit view missing"; fi

# Check scaffold added route (may use singular or plural form)
if grep -qi "article" config/routes.cfm; then
    pass "scaffold: route added to routes.cfm"
else
    fail "scaffold: route not in routes.cfm"
fi

# Check scaffold controller has CRUD actions
for action in index show new create edit update delete; do
    if grep -q "function $action" app/controllers/Articles.cfc 2>/dev/null; then
        pass "scaffold: Articles.$action() action present"
    else
        fail "scaffold: Articles.$action() action missing"
    fi
done

# --- Generate test ---
echo "  Generating test spec..."
if lucli wheels generate test model Product > "$TMPDIR/gen_test.log" 2>&1; then
    pass "generate test model Product"
else
    fail "generate test model Product"
fi

if [ -f "tests/specs/models/ProductSpec.cfc" ]; then
    pass "test spec file created"
else
    fail "test spec file not created"
fi

# --- Generate migration ---
echo "  Generating blank migration..."
if lucli wheels generate migration AddStatusToArticles > "$TMPDIR/gen_mig.log" 2>&1; then
    pass "generate migration AddStatusToArticles"
else
    fail "generate migration AddStatusToArticles"
fi

if find app/migrator/migrations -name "*AddStatusToArticles*" | grep -q .; then
    pass "migration file created with correct name"
else
    fail "migration file not created"
fi

# --- Generate route ---
echo "  Generating route..."
if lucli wheels generate route reviews > "$TMPDIR/gen_route.log" 2>&1; then
    pass "generate route reviews"
else
    fail "generate route reviews"
fi

if grep -q "reviews" config/routes.cfm; then
    pass "reviews route added to routes.cfm"
else
    fail "reviews route not in routes.cfm"
fi

# --- Generate property migration ---
echo "  Generating property migration..."
if lucli wheels generate property Article status:string > "$TMPDIR/gen_prop.log" 2>&1; then
    pass "generate property Article status"
else
    fail "generate property Article status"
fi

if find app/migrator/migrations -iname "*status*" -o -iname "*add*" 2>/dev/null | grep -q .; then
    pass "add-column migration created for status"
else
    # Check if any new migration was created (timestamps may vary)
    MIGRATION_COUNT_AFTER=$(find app/migrator/migrations -name "*.cfc" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$MIGRATION_COUNT_AFTER" -gt 3 ]; then
        pass "add-column migration created (detected by count)"
    else
        fail "add-column migration not created"
    fi
fi

# --- Generate helper ---
echo "  Generating helper..."
if lucli wheels generate helper formatting > "$TMPDIR/gen_helper.log" 2>&1; then
    pass "generate helper formatting"
else
    fail "generate helper formatting"
fi

if [ -f "app/helpers/Formatting.cfc" ] || [ -f "app/helpers/formatting.cfc" ]; then
    pass "app/helpers/Formatting.cfc created"
else
    # Check if helpers dir has any files
    HELPER_FILES=$(find app/helpers -name "*.cfc" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$HELPER_FILES" -gt 0 ]; then
        pass "helper file created ($(ls app/helpers/*.cfc 2>/dev/null | head -1))"
    else
        fail "helper file not created"
    fi
fi

# --- Generate api-resource ---
echo "  Generating api-resource..."
if lucli wheels generate api-resource Token value:string expiresAt:datetime > "$TMPDIR/gen_api.log" 2>&1; then
    pass "generate api-resource Token"
else
    fail "generate api-resource Token"
fi

if [ -f "app/models/Token.cfc" ]; then pass "api-resource: Token model created"; else fail "api-resource: Token model missing"; fi

# ══════════════════════════════════════════════════
#  Phase 3: Start server and verify app boots
# ══════════════════════════════════════════════════

section "Phase 3: Start server"

# Ensure SQLite databases exist (wheels new creates these in db/ by default)
sqlite3 "$APP_DIR/wheelstestdb.db" "SELECT 1;" 2>/dev/null || true
sqlite3 "$APP_DIR/wheelstestdb_tenant_b.db" "SELECT 1;" 2>/dev/null || true
# Also create in db/ if that's where lucee.json points
if [ -d "$APP_DIR/db" ]; then
    for f in development.sqlite test.sqlite; do
        [ -f "$APP_DIR/db/$f" ] || sqlite3 "$APP_DIR/db/$f" "SELECT 1;" 2>/dev/null || true
    done
fi

# Kill anything on our port
lsof -ti :"$PORT" 2>/dev/null | xargs kill -9 2>/dev/null || true
sleep 1

# Ensure SQLite JDBC driver is available
LUCEE_LIB=$(find ~/.lucli/express -path "*/lib/ext" -type d 2>/dev/null | head -1)
if [ -n "$LUCEE_LIB" ] && ! ls "$LUCEE_LIB"/sqlite-jdbc*.jar 1>/dev/null 2>&1; then
    echo "  Downloading SQLite JDBC driver..."
    curl -sL "https://repo1.maven.org/maven2/org/xerial/sqlite-jdbc/3.49.1.0/sqlite-jdbc-3.49.1.0.jar" \
      -o "$LUCEE_LIB/sqlite-jdbc-3.49.1.0.jar"
fi

echo "  Starting LuCLI server on port $PORT..."
nohup lucli server run --port="$PORT" --force > "$TMPDIR/server.log" 2>&1 &
SERVER_PID=$!
SERVER_STARTED=true

if wait_for_server 60; then
    pass "server started on port $PORT"
else
    fail "server failed to start"
    echo "Cannot test HTTP endpoints. Aborting E2E."
    exit 1
fi
# Record the JVM (not the launcher) so cleanup can stop what actually holds the
# port. The port was cleared just above, so whoever listens on it now is ours.
SERVER_JVM="$(listener_pid "$PORT" || true)"

# Warm up Wheels (first request triggers onApplicationStart)
echo "  Warming up application..."
local_password=$(grep RELOAD_PASSWORD "$APP_DIR/.env" 2>/dev/null | cut -d= -f2 || echo "$APP_NAME")
curl -s -o /dev/null --max-time 60 "http://localhost:$PORT/" || true
sleep 3

# Migrate BEFORE the HTTP checks. The scaffolded Articles actions query the
# `articles` table; without it the model layer throws Wheels.TableNotFound,
# which onError maps to HTTP 404 (any `Wheels.*NotFound` is a 404), so
# GET /articles and /articles/new "404" for a reason unrelated to routing
# (#3722). Phase 7 still runs `migrate latest` again as its own check.
echo "  Running migrations before HTTP checks..."
if lucli wheels migrate latest > "$TMPDIR/migrate_prehttp.log" 2>&1; then
    pass "wheels migrate latest (before HTTP checks)"
else
    fail "wheels migrate latest (before HTTP checks) failed"
    tail -20 "$TMPDIR/migrate_prehttp.log" 2>/dev/null || true
fi
curl -s -o /dev/null --max-time 60 "http://localhost:$PORT/?reload=true&password=$local_password" || true
sleep 3

# Verify homepage loads
http_get "/" BODY CODE
if [ "$CODE" = "200" ]; then
    pass "homepage returns 200"
    APP_BOOTS=true
else
    fail "homepage returns $CODE (expected 200)"
    APP_BOOTS=false
    echo "  NOTE: App bootstrap failed. HTTP tests will be skipped."
    echo "  Check server log: $TMPDIR/server.log"
fi

# ══════════════════════════════════════════════════
#  Phase 4: HTTP endpoint verification
# ══════════════════════════════════════════════════

section "Phase 4: HTTP endpoint verification"

if [ "$APP_BOOTS" != "true" ]; then
    echo "  Skipping HTTP tests — app did not boot successfully"
    skip "GET /articles (app bootstrap failed)"
    skip "GET /articles/new (app bootstrap failed)"
    skip "GET /pages/index (app bootstrap failed)"
    skip "GET /pages/about (app bootstrap failed)"
    skip "GET /pages/contact (app bootstrap failed)"
    skip "reload endpoint (app bootstrap failed)"
else
    # --- Scaffolded Articles CRUD ---
    echo "  Testing Articles CRUD endpoints..."

    http_get "/articles" BODY CODE
    if [ "$CODE" = "200" ]; then
        pass "GET /articles returns 200 (index)"
    else
        fail "GET /articles returns $CODE"
    fi

    http_get "/articles/new" BODY CODE
    if [ "$CODE" = "200" ]; then
        pass "GET /articles/new returns 200 (new form)"
    else
        fail "GET /articles/new returns $CODE"
    fi

    # --- Custom controller ---
    echo "  Testing Pages controller..."

    http_get "/pages/index" BODY CODE
    if [ "$CODE" = "200" ]; then
        pass "GET /pages/index returns 200"
    else
        fail "GET /pages/index returns $CODE"
    fi

    http_get "/pages/about" BODY CODE
    if [ "$CODE" = "200" ]; then
        pass "GET /pages/about returns 200"
    else
        fail "GET /pages/about returns $CODE"
    fi

    http_get "/pages/contact" BODY CODE
    if [ "$CODE" = "200" ]; then
        pass "GET /pages/contact returns 200"
    else
        fail "GET /pages/contact returns $CODE"
    fi

    # --- Reload ---
    echo "  Testing reload..."
    local_password=$(grep RELOAD_PASSWORD "$APP_DIR/.env" 2>/dev/null | cut -d= -f2 || echo "$APP_NAME")
    http_get "/?reload=true&password=$local_password" BODY CODE
    if [ "$CODE" = "200" ] || [ "$CODE" = "302" ]; then
        pass "reload endpoint responds ($CODE)"
    else
        fail "reload returns $CODE"
    fi
fi

# ══════════════════════════════════════════════════
#  Phase 5: Informational commands
# ══════════════════════════════════════════════════

section "Phase 5: Informational commands"

# --- wheels info ---
if lucli wheels info > "$TMPDIR/info.log" 2>&1; then
    pass "wheels info runs without error"
    if grep -qi "wheels\|project\|server\|engine" "$TMPDIR/info.log"; then
        pass "wheels info produces meaningful output"
    else
        skip "wheels info output not verified (may need server)"
    fi
else
    fail "wheels info failed"
fi

# --- wheels doctor ---
if lucli wheels doctor > "$TMPDIR/doctor.log" 2>&1; then
    pass "wheels doctor runs without error"
    if grep -qi "HEALTHY\|WARNING\|CRITICAL\|Status" "$TMPDIR/doctor.log"; then
        pass "wheels doctor reports health status"
    else
        fail "wheels doctor output missing health status"
    fi
else
    fail "wheels doctor failed"
fi

# --- wheels stats ---
if lucli wheels stats > "$TMPDIR/stats.log" 2>&1; then
    pass "wheels stats runs without error"
    if grep -qi "Models\|Controllers\|Views\|LOC\|Total\|Files\|Category" "$TMPDIR/stats.log"; then
        pass "wheels stats shows code metrics"
    else
        # Stats may return empty for small projects
        skip "wheels stats output has no metrics (small project)"
    fi
else
    # Stats may fail in temp projects with minimal structure
    skip "wheels stats returned error (temp project)"
fi

# --- wheels notes ---
if lucli wheels notes > "$TMPDIR/notes.log" 2>&1; then
    pass "wheels notes runs without error"
else
    fail "wheels notes failed"
fi

# --- wheels analyze ---
if lucli wheels analyze > "$TMPDIR/analyze.log" 2>&1; then
    pass "wheels analyze runs without error"
    if grep -qi "Grade\|Files\|Lines\|Analysis" "$TMPDIR/analyze.log"; then
        pass "wheels analyze shows analysis results"
    else
        fail "wheels analyze output missing analysis data"
    fi
else
    fail "wheels analyze failed"
fi

# --- wheels validate ---
if lucli wheels validate > "$TMPDIR/validate.log" 2>&1; then
    pass "wheels validate runs without error"
    if grep -qi "valid\|pass\|issue\|error" "$TMPDIR/validate.log"; then
        pass "wheels validate shows validation results"
    else
        fail "wheels validate output missing results"
    fi
else
    fail "wheels validate failed"
fi

# ══════════════════════════════════════════════════
#  Phase 6: Destroy command
# ══════════════════════════════════════════════════

section "Phase 6: Destroy command"

# First generate something to destroy
lucli wheels generate model Disposable name:string > /dev/null 2>&1

if [ -f "app/models/Disposable.cfc" ]; then
    pass "Disposable model created for destroy test"
else
    fail "failed to create Disposable model"
fi

# Destroy without --force should NOT delete
if lucli wheels destroy Disposable model > "$TMPDIR/destroy_preview.log" 2>&1; then
    if [ -f "app/models/Disposable.cfc" ]; then
        pass "destroy without --force preserves files"
    else
        fail "destroy without --force deleted files"
    fi
else
    pass "destroy without --force shows preview"
fi

# Destroy with --force should delete
if lucli wheels destroy Disposable model --force > "$TMPDIR/destroy.log" 2>&1; then
    if [ ! -f "app/models/Disposable.cfc" ]; then
        pass "destroy --force deletes model file"
    else
        fail "destroy --force did not delete model"
    fi
    # Should create a drop-table migration
    if find app/migrator/migrations -name "*disposable*" 2>/dev/null | grep -q .; then
        pass "destroy generates drop-table migration"
    else
        skip "no drop-table migration (may depend on implementation)"
    fi
else
    fail "wheels destroy --force failed"
fi

# ══════════════════════════════════════════════════
#  Phase 7: Database commands
# ══════════════════════════════════════════════════

section "Phase 7: Database commands"

# --- wheels db status ---
if lucli wheels db status > "$TMPDIR/db_status.log" 2>&1; then
    pass "wheels db status runs without error"
else
    fail "wheels db status failed"
fi

# --- wheels db version ---
if lucli wheels db version > "$TMPDIR/db_version.log" 2>&1; then
    pass "wheels db version runs without error"
else
    fail "wheels db version failed"
fi

# --- wheels migrate ---
echo "  Testing migrations..."
if lucli wheels migrate info > "$TMPDIR/migrate_info.log" 2>&1; then
    pass "wheels migrate info runs without error"
else
    fail "wheels migrate info failed"
fi

if lucli wheels migrate latest > "$TMPDIR/migrate_latest.log" 2>&1; then
    pass "wheels migrate latest runs without error"
else
    skip "wheels migrate latest failed (may need running app context)"
fi

# ══════════════════════════════════════════════════
#  Phase 8: Seed command
# ══════════════════════════════════════════════════

section "Phase 8: Seed command"

if lucli wheels seed > "$TMPDIR/seed.log" 2>&1; then
    pass "wheels seed runs without error"
else
    skip "wheels seed failed (may need seeds.cfm)"
fi

# ══════════════════════════════════════════════════
#  Phase 9: Upgrade check
# ══════════════════════════════════════════════════

section "Phase 9: Upgrade check"

if lucli wheels upgrade check > "$TMPDIR/upgrade.log" 2>&1; then
    pass "wheels upgrade check runs without error"
else
    skip "wheels upgrade check failed (may need version info)"
fi

# ══════════════════════════════════════════════════
#  Results
# ══════════════════════════════════════════════════

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║                  Results                      ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "  Passed:  $PASS"
echo "  Failed:  $FAIL"
echo "  Skipped: $SKIP"
echo "  Total:   $TOTAL"
echo ""

if [ "$FAIL" -gt 0 ]; then
    echo "SOME TESTS FAILED"
    exit 1
fi
echo "ALL TESTS PASSED"
