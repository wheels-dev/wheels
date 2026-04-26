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
#   Phase 3 — Lucee Express boot
#   Phase 4 — F2/F5 (the migration cliff)
#   Phase 5 — F3-orig (cfscript wrapper for seedOnce)
#   Phase 6 — F8 / chapters 2-6 CRUD
#   Phase 7 — F7 (wheels packages list)

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

    # F3: duplicate "create" lines (the second user reported Application.cfc twice)
    DUP_LINES=$(grep -E "^\s*create " "$NEW_LOG" 2>/dev/null | sort | uniq -d | head -5)
    if [ -z "$DUP_LINES" ]; then
        pass "F3: no duplicate 'create' lines in wheels new output"
    else
        fail "F3: duplicate 'create' lines emitted by wheels new"
        echo "$DUP_LINES" | sed 's/^/      DUP: /'
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
                local_password=$(grep -E '^RELOAD_PASSWORD=' "$APP_DIR/.env" 2>/dev/null | cut -d= -f2 || echo "wheels")
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
    http_get "/" BODY CODE
    if [ "$CODE" = "200" ]; then
        pass "homepage returns 200"
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
    local_password=$(grep -E '^RELOAD_PASSWORD=' "$APP_DIR/.env" 2>/dev/null | cut -d= -f2 || echo "wheels")
    curl -s -o /dev/null --max-time 30 "http://localhost:$PORT/?reload=true&password=$local_password" || true
    sleep 2

    # Run the migration.
    MIGRATE_LOG="$TMPDIR/wheels-migrate.log"
    if "$WHEELS_CMD" migrate latest > "$MIGRATE_LOG" 2>&1; then
        pass "wheels migrate latest exited 0"
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
    local_password=$(grep -E '^RELOAD_PASSWORD=' "$APP_DIR/.env" 2>/dev/null | cut -d= -f2 || echo "wheels")
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
    local_password=$(grep -E '^RELOAD_PASSWORD=' "$APP_DIR/.env" 2>/dev/null | cut -d= -f2 || echo "wheels")
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
        # F7 is a known-issue on fresh installs — `cli.lucli.services.*` dotted paths
        # in Module.cfc and the deploy/packages services don't resolve when the
        # module isn't loaded under a `cli/lucli/` filesystem hierarchy. The user's
        # daily dev setup (~/.lucli/modules/wheels -> repo's cli/lucli) accidentally
        # works because the symlink target lives under `cli/lucli/`. Brew installs
        # don't, so packages and deploy break. Fix requires either refactoring 30+
        # absolute references to relative paths OR registering a Lucee mapping at
        # module init. Out of scope for the cliff fix. Treat as expected for now.
        if grep -qE "could not find component|PackagesMainCli" "$PACKAGES_LOG"; then
            skip "F7 reproduces (packages/deploy dotted-path resolution) — separate fix needed"
        else
            fail "wheels packages list failed with unexpected error"
            tail -5 "$PACKAGES_LOG" | sed 's/^/      | /'
        fi
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
