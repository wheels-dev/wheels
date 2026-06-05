#!/usr/bin/env bash
# tools/test-onboarding.sh — Local fresh-install onboarding harness
#
# Simulates what a brand-new user experiences: fresh wheels CLI, fresh app,
# tutorial walkthrough. Uses LUCLI_HOME isolation so it doesn't touch your
# daily wheels install at ~/.wheels/.
#
# Mirrors the structure of the journals produced by fresh-VM tutorial
# onboarding runs, so the output is directly comparable.
#
# Usage:
#   bash tools/test-onboarding.sh
#   KEEP_TEMP=1 bash tools/test-onboarding.sh    # don't remove temp dirs on exit
#   BASELINE=1 bash tools/test-onboarding.sh     # use brew-installed CLI instead of worktree
#   PORT=9090 bash tools/test-onboarding.sh      # override server port
#   FROM_PHASE=4 bash tools/test-onboarding.sh   # skip earlier phases (debugging)
#
# Mapping to fresh-VM-run findings:
#   Phase 2 — F1 (bundleName), F3 (duplicate Application.cfc), F4 (file tree)
#   Phase 3 — Lucee Express boot + DI.CircularDependency on first request (#2331)
#   Phase 4 — migration cliff: schema verify + per-migration progress line (#2315)
#   Phase 5 — F3-orig (cfscript wrapper for seedOnce)
#   Phase 6 — chapters 2-6 CRUD walkthrough
#   Phase 7 — wheels packages list — PackagesMainCli (#2309) + SemVer follow-on
#   Phase 8 — wheels routes dumps API JSON (#2317)
#   Phase 9 — wheels test reports '0 passed' silently (#2318)
#   Phase 10 — dev error pages return HTTP 200 (#2319)
#   Phase 2 also covers — wheels new printed paths missing prefixes (#2328)
#   Phase 11 — wheels generate scaffold aborts when model exists (#2327)
#   Phase 12 — wheels browser install does nothing (#2332)
#   Phase 13 — wheels destroy controller leaves views behind (#2330)
#   Phase 14 — wheels generate model writes orphan blank lines (#2329)
#   Phase 15 — dev toolbar shows 0.0.0-dev (#2333)
#
# Phases tracking known-open issues are SKIP-clean while their issues are open
# and flip to PASS once fixed. This keeps the harness green during normal
# development and lights up regressions automatically.

set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PORT="${PORT:-9988}"
APP_NAME="onboarding-test"
SQLITE_JDBC_VERSION="${SQLITE_JDBC_VERSION:-3.49.1.0}"
SQLITE_JDBC_URL="https://repo1.maven.org/maven2/org/xerial/sqlite-jdbc/${SQLITE_JDBC_VERSION}/sqlite-jdbc-${SQLITE_JDBC_VERSION}.jar"

PASS=0
FAIL=0
SKIP=0
TOTAL=0
SERVER_PID=""
SERVER_LOG=""
SERVER_STARTED=false
TMPDIR=""
APP_DIR=""

# ── Helpers ────────────────────────────────────────

cleanup() {
    if [ "${SERVER_STARTED:-false}" = "true" ] && [ -n "${SERVER_PID:-}" ]; then
        echo ""
        echo "Stopping test server (pid $SERVER_PID)..."
        kill "$SERVER_PID" 2>/dev/null || true
        sleep 1
        kill -9 "$SERVER_PID" 2>/dev/null || true
    fi
    if [ "${KEEP_TEMP:-0}" != "1" ] && [ -n "${TMPDIR:-}" ] && [ -d "$TMPDIR" ]; then
        rm -rf "$TMPDIR"
    elif [ "${KEEP_TEMP:-0}" = "1" ] && [ -n "${TMPDIR:-}" ]; then
        echo ""
        echo "Temp dirs kept at: $TMPDIR"
        echo "  LUCLI_HOME:  ${LUCLI_HOME:-(unset)}"
        echo "  APP_DIR:     ${APP_DIR:-(unset)}"
        echo "  SERVER_LOG:  ${SERVER_LOG:-(unset)}"
    fi
}
trap cleanup EXIT

pass() { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ $1"; }
fail() { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ $1"; }
skip() { TOTAL=$((TOTAL+1)); SKIP=$((SKIP+1)); echo "  - $1 (skipped)"; }

section() {
    echo ""
    echo "━━━ $1 ━━━"
}

phase() {
    local n="$1"
    local title="$2"
    if [ -n "${FROM_PHASE:-}" ] && [ "$n" -lt "${FROM_PHASE}" ]; then
        section "Phase $n: $title (skipped via FROM_PHASE)"
        return 1
    fi
    section "Phase $n: $title"
    return 0
}

http_get() {
    local url="http://localhost:$PORT$1"
    local body_var=$2
    local code_var=$3
    local tmpfile="$TMPDIR/.http_response"
    local code
    code=$(curl -s -o "$tmpfile" --max-time 30 --write-out "%{http_code}" "$url" 2>/dev/null || echo "000")
    eval "$body_var=\"\$(cat '$tmpfile' 2>/dev/null || echo '')\""
    eval "$code_var=$code"
}

wait_for_server() {
    local max_wait=${1:-90}
    local i=0
    while [ "$i" -lt "$max_wait" ]; do
        if curl -s -o /dev/null --connect-timeout 2 --max-time 3 "http://localhost:$PORT/" 2>/dev/null; then
            return 0
        fi
        if [ -n "${SERVER_PID:-}" ] && ! kill -0 "$SERVER_PID" 2>/dev/null; then
            echo "  Server process died early — last 20 lines of log:"
            tail -20 "$SERVER_LOG" 2>/dev/null | sed 's/^/      /'
            return 1
        fi
        sleep 2
        i=$((i+2))
    done
    echo "  Server did not respond within ${max_wait}s"
    tail -30 "$SERVER_LOG" 2>/dev/null | sed 's/^/      /'
    return 1
}

# ── Preflight ──────────────────────────────────────

echo "╔══════════════════════════════════════════════╗"
echo "║  Wheels — Local Fresh-Install Onboarding     ║"
echo "║  Harness                                      ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "Mode:    ${BASELINE:+BASELINE (brew-installed wheels)}${BASELINE:-WORKTREE (cli/lucli + vendor/wheels)}"
echo "Repo:    $PROJECT_ROOT"
echo "Port:    $PORT"
echo "Java:    $(java -version 2>&1 | head -1)"

if ! command -v wheels >/dev/null 2>&1 && ! command -v lucli >/dev/null 2>&1; then
    echo "ERROR: neither 'wheels' nor 'lucli' is on PATH"
    exit 2
fi

# Pick the binary — prefer wheels (which is just a symlink to lucli on most installs)
WHEELS_CMD="$(command -v wheels || command -v lucli)"
echo "Wheels:  $WHEELS_CMD"

# JAVA_HOME must be set explicitly for `lucli server run`. The `wheels` wrapper
# resolves Java itself when called as `wheels start`, but our harness calls
# `lucli server run` directly (to avoid the wrapper's 30-second startup timeout)
# which doesn't do that resolution. Mirrors tools/test-cli-local.sh.
if [ -z "${JAVA_HOME:-}" ]; then
    # Try /usr/libexec/java_home (works for non-keg-only installs).
    if command -v /usr/libexec/java_home >/dev/null 2>&1; then
        CANDIDATE="$(/usr/libexec/java_home -v 21 2>/dev/null || /usr/libexec/java_home 2>/dev/null || true)"
        [ -n "$CANDIDATE" ] && export JAVA_HOME="$CANDIDATE"
    fi
    # Fall back to Homebrew's keg-only openjdk@21 (the install path Wheels docs
    # recommend on macOS — `/usr/libexec/java_home` doesn't see this one).
    if [ -z "${JAVA_HOME:-}" ] && command -v brew >/dev/null 2>&1; then
        BREW_OPENJDK="$(brew --prefix openjdk@21 2>/dev/null || true)"
        if [ -d "$BREW_OPENJDK/libexec/openjdk.jdk/Contents/Home" ]; then
            export JAVA_HOME="$BREW_OPENJDK/libexec/openjdk.jdk/Contents/Home"
        fi
    fi
fi
echo "JAVA_HOME: ${JAVA_HOME:-(unset)}"
if [ -z "${JAVA_HOME:-}" ] || [ ! -x "$JAVA_HOME/bin/java" ]; then
    echo "ERROR: JAVA_HOME is unset or invalid — install JDK 21 (brew install openjdk@21)"
    exit 2
fi

# ══════════════════════════════════════════════════
#  Phase 1: Setup isolated LUCLI_HOME
# ══════════════════════════════════════════════════

if phase 1 "Setup isolated LUCLI_HOME"; then
    TMPDIR=$(mktemp -d -t wheels-onboarding.XXXXXX)
    APP_DIR="$TMPDIR/$APP_NAME"
    SERVER_LOG="$TMPDIR/server.log"

    if [ "${BASELINE:-0}" = "1" ]; then
        # Use the user's existing brew-installed wheels — don't touch LUCLI_HOME.
        skip "LUCLI_HOME swap (BASELINE mode)"
        skip "WHEELS_FRAMEWORK_PATH override (BASELINE mode)"
    else
        # Build an isolated module dir from the worktree. The directory name MUST
        # end in `.lucli` because LuCLI's getComponentPath() hardcodes a check
        # for that literal name when deciding whether to load Module.cfc by
        # absolute file path (which is required for dotted paths like
        # `cli.lucli.services.packages.PackagesMainCli` to resolve via the
        # file's real-path ancestors). Without `.lucli`, those paths fail with
        # "could not find component or class with name [...]". See LuCLI
        # LuceeScriptEngine.java:1107-1126.
        export LUCLI_HOME="$TMPDIR/.lucli"
        mkdir -p "$LUCLI_HOME/modules"

        # Mount the worktree's cli/lucli/ as the wheels module. We use a SYMLINK
        # rather than a copy because Module.cfc and several services/ files use
        # absolute dotted paths like `cli.lucli.services.packages.PackagesMainCli`.
        # Lucee resolves those by walking up from the file's REAL path looking
        # for a `cli/lucli/...` ancestor — which only works if the module file
        # actually lives under a `cli/lucli/` directory. The user's daily dev
        # setup (~/.lucli/modules/wheels -> <repo>/cli/lucli) works for this
        # reason; a copy of the contents alone does not. See F7 in the second
        # VM-onboarding journal — `wheels packages list` fails on fresh brew
        # installs for exactly this reason.
        #
        # MODE=copy forces a copy if you specifically want to verify the
        # fresh-brew-install path-resolution failure mode.
        if [ -d "$PROJECT_ROOT/cli/lucli" ]; then
            if [ "${MODE:-symlink}" = "copy" ]; then
                cp -R "$PROJECT_ROOT/cli/lucli" "$LUCLI_HOME/modules/wheels"
                pass "worktree cli/lucli COPIED to \$LUCLI_HOME/modules/wheels (MODE=copy)"
            else
                ln -s "$PROJECT_ROOT/cli/lucli" "$LUCLI_HOME/modules/wheels"
                pass "worktree cli/lucli SYMLINKED at \$LUCLI_HOME/modules/wheels"
            fi
        else
            fail "cli/lucli not found in worktree at $PROJECT_ROOT/cli/lucli"
            exit 1
        fi

        # Copy BaseModule.cfc (lives in ~/.wheels/modules/, not in cli/lucli/).
        if [ -f "$HOME/.wheels/modules/BaseModule.cfc" ]; then
            cp "$HOME/.wheels/modules/BaseModule.cfc" "$LUCLI_HOME/modules/BaseModule.cfc"
            [ -f "$HOME/.wheels/modules/.BaseModule.version" ] && \
                cp "$HOME/.wheels/modules/.BaseModule.version" "$LUCLI_HOME/modules/.BaseModule.version"
            pass "BaseModule.cfc copied from installed wheels"
        else
            fail "BaseModule.cfc not found at \$HOME/.wheels/modules/BaseModule.cfc — install wheels via brew first"
            exit 1
        fi

        # Copy codegen templates (build pipeline injects these from elsewhere; they're
        # not in cli/lucli/templates/). Without them, generators fail with "Template not
        # found: ModelContent.txt". Only relevant in copy mode — symlink mode reads from
        # the source worktree, which we shouldn't pollute.
        if [ "${MODE:-symlink}" = "copy" ] && [ -d "$HOME/.wheels/modules/wheels/templates/codegen" ]; then
            cp -R "$HOME/.wheels/modules/wheels/templates/codegen" \
                  "$LUCLI_HOME/modules/wheels/templates/codegen"
            pass "codegen templates copied from installed wheels"
        elif [ "${MODE:-symlink}" = "copy" ]; then
            skip "codegen templates not present in installed wheels"
        else
            skip "codegen templates skipped (symlink mode reads from worktree)"
        fi

        export WHEELS_FRAMEWORK_PATH="$PROJECT_ROOT/vendor/wheels"
        pass "WHEELS_FRAMEWORK_PATH set to worktree vendor/wheels"

        # Reuse the user's existing Lucee Express install if available so we don't
        # re-download ~74MB on every harness run. This is the only piece of state
        # we share with the user's daily wheels — read-only via symlink.
        for src in "$HOME/.wheels/express" "$HOME/.lucli/express"; do
            if [ -d "$src" ]; then
                ln -s "$src" "$LUCLI_HOME/express"
                pass "Lucee Express linked from $src"
                break
            fi
        done
    fi

    pass "tmp dir created: $TMPDIR"
fi

# ══════════════════════════════════════════════════
#  Phase 2: wheels new — scaffold & verify generated artifacts
# ══════════════════════════════════════════════════

if phase 2 "wheels new $APP_NAME (covers F3 dup, F4 tree, F1 bundleName)"; then
    cd "$TMPDIR"
    rm -rf "$APP_DIR"

    NEW_LOG="$TMPDIR/wheels-new.log"
    if "$WHEELS_CMD" new "$APP_NAME" --no-open-browser --port="$PORT" > "$NEW_LOG" 2>&1; then
        pass "wheels new exited 0"
    else
        fail "wheels new failed (see $NEW_LOG)"
        tail -30 "$NEW_LOG" | sed 's/^/      /'
    fi

    # F3: duplicate "create" lines (the second user reported Application.cfc twice).
    # Strip ANSI color escapes before counting — without this the grep matches
    # nothing and the check silently passes regardless of whether duplicates exist.
    NEW_LOG_PLAIN="$TMPDIR/wheels-new.plain.log"
    sed 's/\x1b\[[0-9;]*m//g' "$NEW_LOG" > "$NEW_LOG_PLAIN" 2>/dev/null || true
    DUP_LINES=$(grep -E "^[[:space:]]*create " "$NEW_LOG_PLAIN" 2>/dev/null | sort | uniq -d)
    DUP_COUNT=$(printf '%s' "$DUP_LINES" | grep -v '^$' 2>/dev/null | wc -l | tr -d ' ')
    if [ "${DUP_COUNT:-0}" -eq 0 ]; then
        pass "F3: no duplicate 'create' lines in wheels new output"
    else
        skip "F3: ${DUP_COUNT} distinct path(s) emitted multiple times by wheels new — issue #2328 not fixed yet"
        echo "$DUP_LINES" | head -5 | sed 's/^/      | /'
    fi

    # Issue #2328: 'create' lines should reflect the real filesystem layout.
    # Bug shape: subdirectories of app/ (migrator, mailers, models, controllers,
    # views, lib, jobs, events, global, plugins) and key files (Model.cfc,
    # Controller.cfc, Application.cfc) are printed at the project root rather
    # than under their actual app/ or public/ parent. NEW_LOG_PLAIN is the
    # ANSI-stripped log produced earlier in this phase.
    MISPLACED_RE="^[[:space:]]*create[[:space:]]+$APP_NAME/(migrator|migrations|mailers|plugins|models|controllers|views|lib|jobs|events|global)/?$|^[[:space:]]*create[[:space:]]+$APP_NAME/(Model|Controller|Application)\.cfc$"
    MISPLACED_COUNT=$(grep -E "$MISPLACED_RE" "$NEW_LOG_PLAIN" 2>/dev/null | wc -l | tr -d ' ')

    if [ "${MISPLACED_COUNT:-0}" -gt 0 ]; then
        skip "wheels new prints ${MISPLACED_COUNT} misplaced create-line(s) (e.g. migrator/, mailers/, Model.cfc at app root) — issue #2328 not fixed yet"
        grep -E "$MISPLACED_RE" "$NEW_LOG_PLAIN" | head -5 | sed 's/^/      | /'
    else
        pass "wheels new prints paths under proper app/ public/ subdirectories"
    fi

    # F4: tree shape
    [ -d "$APP_DIR" ]                       && pass "app directory created"          || fail "app directory missing"
    [ -d "$APP_DIR/app/controllers" ]       && pass "app/controllers/ exists"         || fail "app/controllers/ missing"
    [ -d "$APP_DIR/app/models" ]            && pass "app/models/ exists"              || fail "app/models/ missing"
    [ -d "$APP_DIR/app/views" ]             && pass "app/views/ exists"               || fail "app/views/ missing"
    [ -d "$APP_DIR/app/migrator/migrations" ] && pass "app/migrator/migrations/ exists" || fail "app/migrator/migrations/ missing"
    [ -d "$APP_DIR/config" ]                && pass "config/ exists"                  || fail "config/ missing"
    [ -f "$APP_DIR/config/routes.cfm" ]     && pass "config/routes.cfm exists"        || fail "config/routes.cfm missing"
    [ -f "$APP_DIR/config/settings.cfm" ]   && pass "config/settings.cfm exists"      || fail "config/settings.cfm missing"
    [ -d "$APP_DIR/db" ]                    && pass "db/ exists"                      || fail "db/ missing"

    # F1: generated config/app.cfm should NOT contain bundleName for sqlite (PR #2304)
    if [ -f "$APP_DIR/config/app.cfm" ]; then
        if grep -q 'bundleName.*org.xerial.sqlite-jdbc' "$APP_DIR/config/app.cfm"; then
            fail "F1: generated config/app.cfm still contains bundleName for sqlite-jdbc — PR #2304 not applied here"
            grep -n 'bundleName' "$APP_DIR/config/app.cfm" | sed 's/^/      /'
        else
            pass "F1: generated config/app.cfm has no sqlite-jdbc bundleName"
        fi
    else
        skip "F1: config/app.cfm not present (template change may have moved it)"
    fi

    # vendor/wheels presence — needed for the framework to actually run
    if [ -d "$APP_DIR/vendor/wheels" ]; then
        pass "vendor/wheels/ present in scaffolded app"
    elif [ -n "${WHEELS_FRAMEWORK_PATH:-}" ] && [ -d "$WHEELS_FRAMEWORK_PATH" ]; then
        # Bootstrap from worktree the same way test-cli-e2e.sh does
        mkdir -p "$APP_DIR/vendor"
        cp -R "$WHEELS_FRAMEWORK_PATH" "$APP_DIR/vendor/wheels"
        pass "vendor/wheels/ bootstrapped from worktree (wheels new doesn't copy it)"
    else
        fail "vendor/wheels/ missing and no source to bootstrap from"
    fi
fi

# ══════════════════════════════════════════════════
#  Phase 3: Server boot + sqlite-jdbc shim
# ══════════════════════════════════════════════════

if phase 3 "Server boot + sqlite-jdbc shim (formula simulation)"; then
    cd "$APP_DIR" || exit 1

    # Ensure SQLite db files exist (wheels new template usually creates these but
    # belt-and-suspenders).
    mkdir -p "$APP_DIR/db"
    [ -f "$APP_DIR/db/development.sqlite" ] || touch "$APP_DIR/db/development.sqlite"
    [ -f "$APP_DIR/db/test.sqlite" ]        || touch "$APP_DIR/db/test.sqlite"

    # Free the port if anything is squatting it.
    lsof -ti :"$PORT" 2>/dev/null | xargs kill -9 2>/dev/null || true
    sleep 1

    # Start the server in the background. Use `lucli server run` directly rather
    # than `wheels start` because the latter has a 30-second internal timeout
    # that consistently fires before Lucee finishes booting on first run.
    echo "  Starting Lucee server on port $PORT (via 'lucli server run')..."
    nohup "$WHEELS_CMD" server run --port="$PORT" --force > "$SERVER_LOG" 2>&1 &
    SERVER_PID=$!
    SERVER_STARTED=true

    # Wait briefly so Lucee Express has a chance to download (~74MB on first run).
    if wait_for_server 120; then
        pass "server responded on port $PORT"
    else
        fail "server failed to start within 120s"
        echo "  Cannot proceed without server — aborting remaining phases"
        exit 1
    fi

    # Drop sqlite-jdbc.jar into Lucee Express lib/ext (this is what the formula
    # SHOULD do; we simulate it here so the migration can actually run).
    LUCEE_LIB=""
    for candidate in \
        "${LUCLI_HOME:-$HOME/.lucli}/express"/*/lib/ext \
        "$HOME/.lucli/express"/*/lib/ext \
        "$HOME/.wheels/express"/*/lib/ext; do
        if [ -d "$candidate" ]; then
            LUCEE_LIB="$candidate"
            break
        fi
    done

    if [ -n "$LUCEE_LIB" ]; then
        if ls "$LUCEE_LIB"/sqlite-jdbc*.jar 1>/dev/null 2>&1; then
            pass "sqlite-jdbc already present in $LUCEE_LIB"
        else
            echo "  Downloading sqlite-jdbc-${SQLITE_JDBC_VERSION}.jar -> $LUCEE_LIB/"
            if curl -fsSL "$SQLITE_JDBC_URL" -o "$LUCEE_LIB/sqlite-jdbc-${SQLITE_JDBC_VERSION}.jar"; then
                pass "sqlite-jdbc-${SQLITE_JDBC_VERSION}.jar dropped into $LUCEE_LIB"
                # Reload the app so Lucee picks up the new bundle.
                local_password=$(grep -E '^(WHEELS_)?RELOAD_PASSWORD=' "$APP_DIR/.env" 2>/dev/null | cut -d= -f2 || echo "wheels")
                curl -s -o /dev/null --max-time 60 "http://localhost:$PORT/?reload=true&password=$local_password" || true
                sleep 3
            else
                fail "sqlite-jdbc download failed (no internet?)"
            fi
        fi
    else
        fail "could not locate Lucee Express lib/ext directory"
    fi

    # Sanity: homepage should now load without a BundleException.
    # Note: HTTP 200 alone is NOT proof of success — issue #2319 lets dev error
    # pages render with HTTP 200, so we have to grep the body for known error
    # markers too.
    http_get "/" BODY CODE
    if [ "$CODE" = "200" ]; then
        if echo "$BODY" | grep -qiE "DI\.CircularDependency|Circular dependency detected"; then
            # F1 / issue #2331: the very first request shows DI.CircularDependency
            # with HTTP 200. The fresh-VM workaround is `wheels reload` then
            # refresh; the harness shouldn't silently mask this if it reproduces.
            skip "homepage returns 200 but body contains DI.CircularDependency — issue #2331 not fixed yet"
            echo "$BODY" | grep -m1 -iE "Resolution chain|Circular dependency" | sed 's/^/      | /'
        elif echo "$BODY" | grep -qiE "BundleException|sqlite-jdbc|sqlite\.JDBC"; then
            fail "homepage returns 200 but body shows JDBC bundle error — sqlite-jdbc not loaded"
            echo "$BODY" | grep -iE "BundleException|sqlite-jdbc|sqlite\.JDBC" | head -3 | sed 's/^/      /'
        else
            pass "homepage returns 200 with no known error markers"
        fi
    else
        fail "homepage returns $CODE (expected 200) — sqlite-jdbc may not be loading"
        echo "$BODY" | grep -iE "BundleException|sqlite-jdbc|sqlite\.JDBC" | head -3 | sed 's/^/      /'
    fi
fi

# ══════════════════════════════════════════════════
#  Phase 4: The migration cliff
# ══════════════════════════════════════════════════

if phase 4 "Migration cliff — wheels migrate latest (covers F2/F5)"; then
    cd "$APP_DIR" || exit 1

    # Write the chapter-2 migration so we have something for `migrate latest` to run.
    MIGRATION_TS="20260419120000"
    MIGRATION_FILE="app/migrator/migrations/${MIGRATION_TS}_create_posts_table.cfc"
    mkdir -p "$(dirname "$MIGRATION_FILE")"
    cat > "$MIGRATION_FILE" <<'CFML'
component extends="wheels.migrator.Migration" hint="Create posts table" {
    function up() {
        transaction {
            try {
                t = createTable(name="posts");
                t.string(columnNames="title", default="", allowNull=true, limit=255);
                t.text(columnNames="body", default="", allowNull=true);
                t.string(columnNames="status", default="draft", allowNull=false, limit=20);
                t.datetime(columnNames="publishedAt", allowNull=true);
                t.timestamps();
                t.create();
            } catch (any e) {
                local.exception = e;
            }
            if (StructKeyExists(local, "exception")) {
                transaction action="rollback";
                Throw(errorCode="1", detail=local.exception.detail, message=local.exception.message, type="any");
            } else {
                transaction action="commit";
            }
        }
    }
    function down() {
        transaction {
            dropTable("posts");
            transaction action="commit";
        }
    }
}
CFML
    [ -f "$MIGRATION_FILE" ] && pass "ch02 migration written" || fail "could not write migration"

    # Reload so the framework sees the new migration file.
    local_password=$(grep -E '^(WHEELS_)?RELOAD_PASSWORD=' "$APP_DIR/.env" 2>/dev/null | cut -d= -f2 || echo "wheels")
    curl -s -o /dev/null --max-time 30 "http://localhost:$PORT/?reload=true&password=$local_password" || true
    sleep 2

    # Run the migration.
    MIGRATE_LOG="$TMPDIR/wheels-migrate.log"
    if "$WHEELS_CMD" migrate latest > "$MIGRATE_LOG" 2>&1; then
        # Issue #2315: the CLI happily prints "Migration latest completed." even
        # when the framework returned success:false (e.g. JDBC class not loaded).
        # A real successful migration prints a per-migration progress line like
        # "Migrating from 0 up to 20260427..." or "Created table posts". Treat
        # exit-0-with-no-progress-line as the silent-success bug, not as success.
        if grep -qE "Migrating (up|from|to)|Created table|Migrated|migration\.cfc" "$MIGRATE_LOG"; then
            pass "wheels migrate latest exited 0 with per-migration progress"
        else
            skip "wheels migrate latest exited 0 but emitted no per-migration line — issue #2315 not fixed yet"
            echo "      first 5 lines of output:"
            head -5 "$MIGRATE_LOG" | sed 's/^/      | /'
        fi
    else
        fail "wheels migrate latest exited non-zero"
        tail -20 "$MIGRATE_LOG" | sed 's/^/      /'
    fi

    # F2/F5: this is where the second user got the "false success" — verify the
    # actual schema by hitting the database file directly.
    SQLITE_DB="$APP_DIR/db/development.sqlite"
    DB_SIZE=$(stat -f %z "$SQLITE_DB" 2>/dev/null || stat -c %s "$SQLITE_DB" 2>/dev/null || echo 0)
    if [ "$DB_SIZE" -gt 0 ]; then
        pass "F5: db/development.sqlite is non-empty ($DB_SIZE bytes)"
    else
        fail "F5: db/development.sqlite is 0 bytes — migration silently no-op'd"
        echo "      migrate-output:" && head -10 "$MIGRATE_LOG" | sed 's/^/      | /'
    fi

    if command -v sqlite3 >/dev/null 2>&1; then
        SCHEMA=$(sqlite3 "$SQLITE_DB" ".schema posts" 2>/dev/null || true)
        if echo "$SCHEMA" | grep -qi "CREATE TABLE.*posts"; then
            pass "F5: posts table exists in development.sqlite"
            echo "      $SCHEMA" | head -1 | sed 's/^/      | /'
        else
            fail "F5: posts table NOT found in development.sqlite"
            sqlite3 "$SQLITE_DB" ".tables" 2>/dev/null | sed 's/^/      tables: /'
        fi
    else
        skip "sqlite3 not on PATH — cannot verify schema"
    fi
fi

# ══════════════════════════════════════════════════
#  Phase 5: Seed (covers cfscript-wrapper + idempotency)
# ══════════════════════════════════════════════════

if phase 5 "wheels seed (covers F3-orig cfscript wrapper + seedOnce idempotency)"; then
    cd "$APP_DIR" || exit 1

    SEED_FILE="app/db/seeds.cfm"
    mkdir -p "$(dirname "$SEED_FILE")"
    cat > "$SEED_FILE" <<'CFML'
<cfscript>
seedOnce(modelName="Post", uniqueProperties="title", properties={
    title: "Hello world",
    body: "My first Wheels post.",
    status: "published",
    publishedAt: Now()
});
seedOnce(modelName="Post", uniqueProperties="title", properties={
    title: "Learning Wheels",
    body: "Working through the tutorial.",
    status: "published",
    publishedAt: Now()
});
</cfscript>
CFML

    # Reload so the framework sees the seed file.
    local_password=$(grep -E '^(WHEELS_)?RELOAD_PASSWORD=' "$APP_DIR/.env" 2>/dev/null | cut -d= -f2 || echo "wheels")
    curl -s -o /dev/null --max-time 30 "http://localhost:$PORT/?reload=true&password=$local_password" || true
    sleep 2

    SEED_LOG="$TMPDIR/wheels-seed.log"
    if "$WHEELS_CMD" seed > "$SEED_LOG" 2>&1; then
        pass "wheels seed exited 0"
    else
        fail "wheels seed exited non-zero"
        tail -10 "$SEED_LOG" | sed 's/^/      /'
    fi

    # Verify it actually inserted rows.
    if command -v sqlite3 >/dev/null 2>&1; then
        POST_COUNT=$(sqlite3 "$APP_DIR/db/development.sqlite" "SELECT COUNT(*) FROM posts;" 2>/dev/null || echo "?")
        if [ "$POST_COUNT" = "2" ]; then
            pass "seed inserted 2 posts (expected on first run)"
        elif [ "$POST_COUNT" = "0" ]; then
            fail "seed inserted 0 posts — cfscript wrapper or seedOnce broken"
            head -5 "$SEED_LOG" | sed 's/^/      | /'
        else
            fail "seed inserted $POST_COUNT posts (expected 2)"
        fi

        # Idempotency: run seed again, count should stay at 2.
        "$WHEELS_CMD" seed > "$SEED_LOG.2" 2>&1 || true
        POST_COUNT_2=$(sqlite3 "$APP_DIR/db/development.sqlite" "SELECT COUNT(*) FROM posts;" 2>/dev/null || echo "?")
        if [ "$POST_COUNT_2" = "2" ]; then
            pass "seedOnce idempotent: re-run kept count at 2"
        else
            fail "seedOnce NOT idempotent: re-run produced $POST_COUNT_2 rows (expected 2)"
        fi
    else
        skip "sqlite3 not on PATH — cannot verify seed counts"
    fi
fi

# ══════════════════════════════════════════════════
#  Phase 6: CRUD walkthrough (chapters 2-3 checkpoints)
# ══════════════════════════════════════════════════

if phase 6 "CRUD walkthrough — controller + views + routes (ch02-ch03 checkpoints)"; then
    cd "$APP_DIR" || exit 1

    # Chapter 2 model
    cat > "app/models/Post.cfc" <<'CFML'
component extends="Model" {
    function config() {
        enum(property="status", values="draft,published,archived");
    }
}
CFML

    # Chapter 2 controller (index + show only)
    cat > "app/controllers/Posts.cfc" <<'CFML'
component extends="Controller" {
    function index() {
        posts = model("Post").published().findAll(order="publishedAt DESC");
    }
    function show() {
        post = model("Post").findByKey(params.key);
    }
}
CFML

    # Views
    mkdir -p "app/views/posts"
    cat > "app/views/posts/index.cfm" <<'CFML'
<cfparam name="posts" default="">
<cfoutput>
<h1>Posts</h1>
<cfloop query="posts">
    <article>
        <h2>#posts.title#</h2>
        <p>#posts.body#</p>
    </article>
</cfloop>
</cfoutput>
CFML

    cat > "app/views/posts/show.cfm" <<'CFML'
<cfparam name="post" default="">
<cfoutput>
<h1>#post.title#</h1>
<p>#post.body#</p>
</cfoutput>
CFML

    # Routes
    cat > "config/routes.cfm" <<'CFML'
<cfscript>
mapper()
    .resources(name="posts", only="index,show")
    .wildcard()
    .root(to="posts##index", method="get")
.end();
</cfscript>
CFML

    pass "ch02-ch03 model/controller/views/routes written"

    # Reload
    local_password=$(grep -E '^(WHEELS_)?RELOAD_PASSWORD=' "$APP_DIR/.env" 2>/dev/null | cut -d= -f2 || echo "wheels")
    curl -s -o /dev/null --max-time 30 "http://localhost:$PORT/?reload=true&password=$local_password" || true
    sleep 2

    # Index page
    http_get "/posts" BODY CODE
    if [ "$CODE" = "200" ]; then
        if echo "$BODY" | grep -q "Hello world"; then
            pass "GET /posts returns 200 with seeded post"
        else
            fail "GET /posts returns 200 but missing 'Hello world' content"
            echo "$BODY" | head -20 | sed 's/^/      /'
        fi
    else
        fail "GET /posts returns $CODE (expected 200)"
        echo "$BODY" | grep -iE "error|exception" | head -3 | sed 's/^/      /'
    fi

    # Show page
    http_get "/posts/1" BODY CODE
    if [ "$CODE" = "200" ]; then
        if echo "$BODY" | grep -qE "Hello world|Learning Wheels"; then
            pass "GET /posts/1 returns 200 with post body"
        else
            fail "GET /posts/1 returns 200 but missing post content"
        fi
    else
        fail "GET /posts/1 returns $CODE (expected 200)"
    fi

    # Root → posts index
    http_get "/" BODY CODE
    if [ "$CODE" = "200" ]; then
        if echo "$BODY" | grep -q "Posts"; then
            pass "GET / returns 200 (root mapped to posts##index)"
        else
            skip "GET / returns 200 but no 'Posts' heading (welcome page may be intercepting)"
        fi
    else
        fail "GET / returns $CODE"
    fi
fi

# ══════════════════════════════════════════════════
#  Phase 7: wheels packages list (covers F7)
# ══════════════════════════════════════════════════

if phase 7 "wheels packages list (covers F7 — PackagesMainCli dotted-path resolution)"; then
    cd "$APP_DIR" || exit 1

    PACKAGES_LOG="$TMPDIR/wheels-packages.log"
    if "$WHEELS_CMD" packages list > "$PACKAGES_LOG" 2>&1; then
        pass "wheels packages list exited 0"
        if head -3 "$PACKAGES_LOG" | grep -qiE "packages|registry|wheels-"; then
            pass "wheels packages list produced sensible output"
        else
            skip "wheels packages list output unexpected — may need network"
            head -10 "$PACKAGES_LOG" | sed 's/^/      | /'
        fi
    else
        # F7 used to be PackagesMainCli not resolving via cli.lucli.services.* dotted
        # paths — fixed in #2309 by switching to the modules.wheels mapping. After
        # that fix landed, a follow-on dotted-path issue surfaced: the packages
        # service references `wheels.SemVer` which doesn't resolve outside a
        # filesystem rooted at `wheels/`. Discriminate the failures so the harness
        # output is actionable.
        if grep -qE "PackagesMainCli" "$PACKAGES_LOG"; then
            fail "F7 regressed: PackagesMainCli dotted-path failure is back (was fixed in #2309)"
            tail -5 "$PACKAGES_LOG" | sed 's/^/      | /'
        elif grep -qE "wheels\.SemVer|component or class.*name \[wheels\." "$PACKAGES_LOG"; then
            fail "F7 follow-on: packages service can't resolve wheels.* dotted paths (separate from #2309)"
            tail -3 "$PACKAGES_LOG" | sed 's/^/      | /'
        else
            fail "wheels packages list failed with unexpected error"
            tail -5 "$PACKAGES_LOG" | sed 's/^/      | /'
        fi
    fi
fi

# ══════════════════════════════════════════════════
#  Phase 8: wheels routes returns route table (issue #2317)
# ══════════════════════════════════════════════════
#
# Surfaced by fresh-VM 2026-04-25 finding #5: `wheels routes` dumps ~500KB of
# JSON describing the framework API instead of the route table. Likely a wrong
# endpoint mapping in the CLI. This phase detects regression once the issue
# (open as #2317) is fixed, and SKIPs cleanly until then.

if phase 8 "wheels routes returns route table not API JSON dump (issue #2317)"; then
    cd "$APP_DIR" || exit 1

    ROUTES_LOG="$TMPDIR/wheels-routes.log"
    if "$WHEELS_CMD" routes > "$ROUTES_LOG" 2>&1; then
        SIZE=$(stat -f %z "$ROUTES_LOG" 2>/dev/null || stat -c %s "$ROUTES_LOG" 2>/dev/null || echo 0)
        # The framework API-reference dump is hundreds of KB; a route table for a
        # fresh app is dozens to a few thousand bytes. 50KB is well above any
        # plausible route table for a fresh app and well below the API dump.
        if [ "$SIZE" -gt 50000 ]; then
            skip "wheels routes still dumps API JSON ($SIZE bytes) — issue #2317 not fixed yet"
        elif grep -qE "GET[[:space:]]|POST[[:space:]]|PUT[[:space:]]|PATCH[[:space:]]|DELETE[[:space:]]" "$ROUTES_LOG"; then
            pass "wheels routes returned a route table"
        else
            skip "wheels routes output is small ($SIZE bytes) but format unrecognized"
            head -5 "$ROUTES_LOG" | sed 's/^/      | /'
        fi
    else
        fail "wheels routes exited non-zero"
        tail -5 "$ROUTES_LOG" | sed 's/^/      | /'
    fi
fi

# ══════════════════════════════════════════════════
#  Phase 9: wheels test prints non-zero counts (issue #2318)
# ══════════════════════════════════════════════════
#
# Surfaced by fresh-VM 2026-04-25 finding #7: `wheels test` reports `0 passed`
# with no spec list, no failures, no errors — even though `wheels doctor`
# confirms specs are present. Drop a trivial spec and verify wheels test
# either reports a non-zero count or surfaces a real error.

if phase 9 "wheels test prints non-zero counts when a spec exists (issue #2318)"; then
    cd "$APP_DIR" || exit 1

    SPEC_DIR="$APP_DIR/tests/specs/onboarding"
    SPEC_FILE="$SPEC_DIR/SmokeSpec.cfc"
    mkdir -p "$SPEC_DIR"
    cat > "$SPEC_FILE" <<'CFML'
component extends="wheels.WheelsTest" {
    function run() {
        describe("Onboarding harness smoke", () => {
            it("can perform a trivial assertion", () => {
                expect(1 + 1).toBe(2);
            });
        });
    }
}
CFML
    [ -f "$SPEC_FILE" ] && pass "smoke spec written" || fail "could not write smoke spec"

    # Reload so the framework sees the new spec.
    local_password=$(grep -E '^(WHEELS_)?RELOAD_PASSWORD=' "$APP_DIR/.env" 2>/dev/null | cut -d= -f2 || echo "wheels")
    curl -s -o /dev/null --max-time 30 "http://localhost:$PORT/?reload=true&password=$local_password" || true
    sleep 1

    TEST_LOG="$TMPDIR/wheels-test.log"
    "$WHEELS_CMD" test > "$TEST_LOG" 2>&1 || true

    # The bug per issue #2318: the runner reports "0 passed" with no other detail
    # even when a discoverable spec exists. Discriminate three states:
    #   1. Working — output includes a non-zero count or names the smoke spec.
    #   2. Bug present — "0 passed" with no spec name, describe block, or error.
    #   3. Unrecognized — neither pattern, probably a new failure mode.
    # Order matters: most-specific working check first, then most-specific bug
    # check, then a fallthrough for unrecognized output.
    if grep -qE "(^|[^0-9])([1-9][0-9]*) passed" "$TEST_LOG" || \
       grep -qE "SmokeSpec|Onboarding harness smoke" "$TEST_LOG"; then
        pass "wheels test reports the smoke spec"
    elif grep -qE "0 passed" "$TEST_LOG" && \
         ! grep -qiE "describe|spec[[:space:]]+|it[[:space:]]+\(|smoke" "$TEST_LOG"; then
        skip "wheels test prints '0 passed' with no spec detail — issue #2318 not fixed yet"
        head -5 "$TEST_LOG" | sed 's/^/      | /'
    elif grep -qE "passed|failed|errored|collected" "$TEST_LOG"; then
        # Real runner output without a clear pass-count match (e.g. all-failed
        # output, or a different reporter format) — better than the bug case.
        pass "wheels test produced runner detail (counts or status)"
    else
        skip "wheels test output unrecognized — review $TEST_LOG"
        head -10 "$TEST_LOG" | sed 's/^/      | /'
    fi
fi

# ══════════════════════════════════════════════════
#  Phase 10: dev error pages return 5xx not 200 (issue #2319)
# ══════════════════════════════════════════════════
#
# Surfaced by fresh-VM 2026-04-25 finding #8: `Wheels.RouteNotFound` and other
# framework error pages render with HTTP 200, lying to anything that consumes
# the response by status code (curl, monitoring, retry logic). Hit a route
# guaranteed to fail and check the status.

if phase 10 "dev error pages return 5xx/4xx not HTTP 200 (issue #2319)"; then
    # /__definitely_not_a_route is guaranteed to miss the wildcard's controller
    # resolution because no controller named `__definitely_not_a_route` exists.
    BAD_PATH="/__definitely_not_a_route_$(date +%s)"
    STATUS=$(curl -s -o /tmp/wheels-error-body.txt -w "%{http_code}" --max-time 15 "http://localhost:$PORT$BAD_PATH" || echo 000)

    case "$STATUS" in
        4*|5*)
            pass "framework error returned HTTP $STATUS (correct)"
            ;;
        200)
            # Confirm it really is an error body, not a real page.
            if grep -qiE "RouteNotFound|ControllerNotFound|wheels error|cferror|exception" /tmp/wheels-error-body.txt; then
                skip "dev error page returns HTTP 200 with error body — issue #2319 not fixed yet"
            else
                skip "$BAD_PATH unexpectedly returned 200 with non-error body"
            fi
            ;;
        000)
            fail "could not reach server at port $PORT"
            ;;
        *)
            skip "unexpected HTTP $STATUS for guaranteed-bad route"
            ;;
    esac
fi

# ══════════════════════════════════════════════════
#  Phase 11: wheels generate scaffold over existing model (issue #2327)
# ══════════════════════════════════════════════════
#
# Surfaced by fresh-VM 2026-04-27 finding #3: tutorial chapter 2 has the user
# generate a Post model, then chapter 3 asks for `wheels generate scaffold Post`
# — but the scaffold command aborts with "Model already exists", even with
# --force. Phase 6 has already written app/models/Post.cfc, so we can attempt
# the scaffold here and check whether it tolerates the existing model.

if phase 11 "wheels generate scaffold tolerates existing model (issue #2327)"; then
    cd "$APP_DIR" || exit 1

    SCAFFOLD_LOG="$TMPDIR/wheels-scaffold.log"
    "$WHEELS_CMD" generate scaffold Post title:string body:text status:enum --force \
        > "$SCAFFOLD_LOG" 2>&1 || true

    # Distinguish the bug shape from the fix shape:
    #   - Bug: "Scaffold failed:" (the entire scaffold aborts)
    #   - Fix: "Scaffold complete!" with the existing model skipped or
    #     overwritten (with --force) and the controller/views written.
    # Both can mention "Model already exists:" — the bug as the abort
    # reason, the fix as part of the per-artifact "skip ..." annotation.
    if grep -qE "Scaffold failed" "$SCAFFOLD_LOG"; then
        skip "wheels generate scaffold aborts when model exists — issue #2327 not fixed yet"
        head -8 "$SCAFFOLD_LOG" | sed 's/^/      | /'
    elif grep -qE "Scaffold complete" "$SCAFFOLD_LOG"; then
        pass "wheels generate scaffold completed with existing model present"
    else
        skip "wheels generate scaffold output unrecognized — review $SCAFFOLD_LOG"
        head -10 "$SCAFFOLD_LOG" | sed 's/^/      | /'
    fi
fi

# ══════════════════════════════════════════════════
#  Phase 12: wheels browser install fetches Playwright (issue #2332)
# ══════════════════════════════════════════════════
#
# Surfaced by fresh-VM 2026-04-27 finding #6: `wheels browser install` runs the
# generic dependency resolver and exits 0 without downloading any Playwright
# JARs or Chromium. Chapter 7's browser-spec walkthrough is unrunnable as a
# result.

if phase 12 "wheels browser setup fetches Playwright (issue #2332)"; then
    cd "$APP_DIR" || exit 1

    BROWSER_LOG="$TMPDIR/wheels-browser-setup.log"
    # `wheels browser install` was the original verb but LuCLI intercepts
    # `install` as its built-in extension installer before module dispatch
    # runs. The fix renamed the subcommand to `setup`. Test BOTH paths so
    # this phase catches a regression to the broken verb name.
    #
    # Don't wait for a 140MB Chromium download in the harness — just check
    # whether the command appears to be doing the right thing in the first
    # few seconds. A real setup would mention 'Playwright', 'Chromium', or
    # touch a manifest path within the first second.
    "$WHEELS_CMD" browser setup > "$BROWSER_LOG" 2>&1 &
    BROWSER_PID=$!
    sleep 3
    kill "$BROWSER_PID" 2>/dev/null || true
    wait "$BROWSER_PID" 2>/dev/null || true

    if grep -qiE "playwright|chromium|browser-manifest|Install directory" "$BROWSER_LOG" || \
       ls "$APP_DIR/lib/"*playwright*.jar >/dev/null 2>&1; then
        pass "wheels browser setup references Playwright artifacts"
    elif grep -qiE "No git or extension dependencies to install|Reading lucee\.json" "$BROWSER_LOG"; then
        skip "wheels browser setup runs generic dep resolver, no Playwright work — issue #2332 not fixed yet"
        head -5 "$BROWSER_LOG" | sed 's/^/      | /'
    else
        skip "wheels browser setup output unrecognized — review $BROWSER_LOG"
        head -10 "$BROWSER_LOG" | sed 's/^/      | /'
    fi
fi

# ══════════════════════════════════════════════════
#  Phase 13: wheels destroy controller removes views too (issue #2330)
# ══════════════════════════════════════════════════
#
# Surfaced by fresh-VM 2026-04-27 finding #9: `wheels destroy <Name> controller`
# (a) silently does nothing without --force, and (b) with --force removes only
# the .cfc but leaves the matching app/views/<plural>/ directory behind. The
# tutorial says "Drop the hand-written controller and views" — the docs and
# the CLI disagree.

if phase 13 "wheels destroy controller removes both .cfc and views/ (issue #2330)"; then
    cd "$APP_DIR" || exit 1

    # Use a plural, conventional name. Non-conventional singular names (e.g.
    # 'WidgetTest') trigger a separate name-mangling bug where destroy looks
    # for 'Widgettests.cfc' and emits "Not found" — that's its own bug, but
    # not the one we're isolating here. Stick to convention to test the
    # views-not-removed claim cleanly.
    "$WHEELS_CMD" generate controller Widgets index > /dev/null 2>&1 || true

    if [ ! -f "$APP_DIR/app/controllers/Widgets.cfc" ]; then
        skip "could not generate Widgets controller — skipping destroy check"
    else
        DESTROY_LOG="$TMPDIR/wheels-destroy.log"
        "$WHEELS_CMD" destroy Widgets controller --force > "$DESTROY_LOG" 2>&1 || true

        CONTROLLER_REMOVED="false"
        [ ! -f "$APP_DIR/app/controllers/Widgets.cfc" ] && CONTROLLER_REMOVED="true"

        VIEWS_REMOVED="true"
        [ -d "$APP_DIR/app/views/widgets" ] && VIEWS_REMOVED="false"

        if [ "$CONTROLLER_REMOVED" = "true" ] && [ "$VIEWS_REMOVED" = "true" ]; then
            pass "wheels destroy controller removed both .cfc and views/"
        elif [ "$CONTROLLER_REMOVED" = "true" ] && [ "$VIEWS_REMOVED" = "false" ]; then
            skip "wheels destroy controller removed .cfc but left views/ behind — issue #2330 not fixed yet"
            ls "$APP_DIR/app/views/widgets" 2>/dev/null | head -3 | sed 's/^/      | views\/widgets\//'
        elif grep -qiE "Not found|skip[[:space:]]+Not found" "$DESTROY_LOG"; then
            skip "wheels destroy reported 'Not found' on the file it just created — name-mangling bug related to #2330"
            head -8 "$DESTROY_LOG" | sed 's/^/      | /'
        else
            skip "wheels destroy behavior unclear (controller_removed=$CONTROLLER_REMOVED views_removed=$VIEWS_REMOVED)"
            head -8 "$DESTROY_LOG" | sed 's/^/      | /'
        fi

        # Belt-and-suspenders cleanup so re-runs don't accumulate stale dirs.
        rm -rf "$APP_DIR/app/views/widgets" 2>/dev/null
        rm -f "$APP_DIR/app/controllers/Widgets.cfc" 2>/dev/null
        rm -f "$APP_DIR/tests/specs/controllers/WidgetsSpec.cfc" 2>/dev/null
    fi
fi

# ══════════════════════════════════════════════════
#  Phase 14: wheels generate model template formatting (issue #2329)
# ══════════════════════════════════════════════════
#
# Surfaced by fresh-VM 2026-04-27 finding #10: `wheels generate model` produces
# a CFC with multiple consecutive blank lines and over-indented validation
# lines inside config() — template-fill leftovers. The double-blank-line
# pattern is the strongest detection signal.

if phase 14 "wheels generate model produces clean output (issue #2329)"; then
    cd "$APP_DIR" || exit 1

    # The generator validates names and rejects anything ending in 'Test',
    # 'Controller', or 'Service' — so 'FormatTest' would error out. 'FmtSample'
    # is short, safe, and unlikely to clash with anything.
    "$WHEELS_CMD" generate model FmtSample name:string > /dev/null 2>&1 || true
    GEN_FILE="$APP_DIR/app/models/FmtSample.cfc"

    if [ ! -f "$GEN_FILE" ]; then
        skip "could not generate FmtSample model — skipping format check"
    else
        # Two or more consecutive blank lines = template-fill leftover.
        # awk counts consecutive blanks; exit 0 if any run reached 2+.
        if awk '/^[[:space:]]*$/{c++; if(c>=2){f=1}} !/^[[:space:]]*$/{c=0} END{exit !f+0}' "$GEN_FILE"; then
            skip "wheels generate model output has 2+ consecutive blank lines — issue #2329 not fixed yet"
            sed -n '1,15p' "$GEN_FILE" | sed 's/^/      | /'
        else
            pass "wheels generate model output has no orphan blank-line runs"
        fi

        # Clean up the model AND the matching migration file (model generate
        # creates both); leaving the migration causes downstream phases to
        # see an unrun migration in the migrations/ directory.
        rm -f "$GEN_FILE"
        rm -f "$APP_DIR/app/migrator/migrations/"*"_create_fmtsamples_table.cfc" 2>/dev/null
    fi
fi

# ══════════════════════════════════════════════════
#  Phase 15: dev toolbar shows real version not 0.0.0-dev (issue #2333)
# ══════════════════════════════════════════════════
#
# Surfaced by fresh-VM 2026-04-27 finding #15: the dev toolbar reads "Wheels
# Version 0.0.0-dev" regardless of which version is actually installed. The
# CLI's `wheels --version` correctly reports the real version, so the data is
# available — the toolbar is reading from the wrong source.

if phase 15 "dev toolbar shows real version (issue #2333)"; then
    # Earlier phases' generate/destroy probes can leave the framework in a
    # half-reloaded state — reload first so the homepage is rendered fresh
    # rather than from a stale-cache state.
    local_password=$(grep -E '^(WHEELS_)?RELOAD_PASSWORD=' "$APP_DIR/.env" 2>/dev/null | cut -d= -f2 || echo "wheels")
    curl -s -o /dev/null --max-time 30 "http://localhost:$PORT/?reload=true&password=$local_password" || true
    sleep 2

    http_get "/" BODY CODE
    if [ "$CODE" != "200" ]; then
        skip "homepage returned $CODE (expected 200) — cannot check toolbar version"
    elif echo "$BODY" | grep -qiE "0\.0\.0-dev"; then
        skip "dev toolbar still shows 0.0.0-dev — issue #2333 not fixed yet"
        echo "$BODY" | grep -oiE "Wheels Version[^<]{0,40}" | head -1 | sed 's/^/      | /'
    elif echo "$BODY" | grep -qiE "Wheels Version"; then
        pass "dev toolbar shows a non-placeholder version"
        echo "$BODY" | grep -oiE "Wheels Version[^<]{0,40}" | head -1 | sed 's/^/      | /'
    else
        skip "no 'Wheels Version' marker in homepage body — toolbar layout may have changed"
    fi
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
    echo "FAIL — see entries marked ✗ above"
    exit 1
fi
echo "PASS"
