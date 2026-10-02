#!/usr/bin/env bash
# Run Wheels core tests locally via Wheels CLI + SQLite (no Docker required)
#
# Prerequisites:
#   - Wheels CLI installed (brew install wheels or download from GitHub releases)
#     Wheels is built on the LuCLI runtime; we ship the runtime under the
#     `wheels` brand. There is no separate `lucli` binary on a normal install.
#   - Java 21+ installed
#   - SQLite JDBC driver in ~/.wheels/express/*/lib/ext/ (auto-installed by
#     recent Wheels CLI releases)
#
# Usage:
#   bash tools/test-local.sh                          # run all core tests
#   bash tools/test-local.sh model                    # one area: any directory under
#                                                     # vendor/wheels/tests/specs/ (models/
#                                                     # controllers/views also accepted)
#   bash tools/test-local.sh model/associations       # a nested directory
#   bash tools/test-local.sh wheels.tests.specs.model # the dotted TestBox form
#   bash tools/test-local.sh dispatch/TestScopeVisibilitySpec  # one spec file
#   PORT=9090 bash tools/test-local.sh                # use custom port
#
# An area that is neither a directory nor a spec file under
# vendor/wheels/tests/specs/ exits 2
# with the list of valid areas; it never falls back to the full suite.
#
# Browser-test behavior:
#   Browser specs (BrowserDialog/Login/Route) run against the local
#   Wheels CLI server via Playwright. Requires Playwright JARs installed in
#   ~/.wheels/browser/lib/ — run `wheels browser:install` once if not.
#   WHEELS_BROWSER_TEST_BASE_URL is auto-set to match the local PORT so
#   specs hit the right server; CI sets its own override before invoking
#   this script so the ${VAR:-default} preserves it.
#
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PORT="${PORT:-8080}"
FILTER="${1:-}"
DB="${DB:-sqlite}"
# Must match set(reloadPassword=...) in config/settings.cfm — a mismatch never
# reloads and, since #3062, counts against the per-IP reload rate limit.
PASSWORD="wheels-dev"
# Per-checkout results file. A single fixed /tmp path is shared by every checkout on
# the machine, so two working copies running the suite overwrite each other's results —
# and a develop-vs-branch comparison silently becomes two copies of the same run
# (issue #3352). Keyed on the project root so concurrent checkouts stay separate.
RESULT_FILE="${WHEELS_TEST_RESULT_FILE:-/tmp/wheels-local-test-results-$(echo "$PROJECT_ROOT" | shasum | cut -c1-12).json}"

# Browser specs call back into the local Wheels CLI server — point Playwright
# at the right port. CI sets this explicitly before invoking the script;
# the ${VAR:-default} preserves the CI override.
export WHEELS_BROWSER_TEST_BASE_URL="${WHEELS_BROWSER_TEST_BASE_URL:-http://localhost:${PORT}}"

# The constructor test-context gate (events/testcontext.cfm) honours
# WHEELS_ENV, the only environment signal readable before the app starts. The
# core suite runs in development (config/environment.cfm), so declare it here or
# the isolated `_wheelsTest` binding fails closed and specs run against the live
# application scope. ${VAR:-default} preserves any explicit override.
export WHEELS_ENV="${WHEELS_ENV:-development}"

# Playwright Java runs `node driver/cli.js install` (a full browser
# download/check) on first launch unless this is set; on a machine where that
# subprocess stalls, the launch blocks forever and wedges the entire test run
# behind the test-runner lock. Browsers are preinstalled by `wheels browser
# setup`, so the install step is always skippable — and the BrowserLauncher
# watchdog (BrowserLauncher.cfc) still bounds any launch that does stall.
export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD="${PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD:-1}"

cd "$PROJECT_ROOT"

# ── Resolve the area filter before anything starts ──
#
# Derived from the filesystem, not a hand list: the old list covered nine
# areas, and any other name (e.g. `database`) went to the server raw, was
# rejected by its directory allowlist, and ran the FULL suite before failing.
SPECS_DIR="vendor/wheels/tests/specs"
list_areas() {
  find "$SPECS_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort | tr '\n' ' '
}
if [ -n "$FILTER" ]; then
  REL="$FILTER"
  case "$REL" in
    wheels.tests.specs) REL="" ;;
    wheels.tests.specs.*) REL="${REL#wheels.tests.specs.}"; REL="$(printf '%s' "$REL" | tr . /)"; [ -n "$REL" ] || REL="." ;;
    *) REL="${REL%/}" ;;
  esac
  # Plural aliases for the three areas that have always accepted them.
  case "$REL" in
    models|controllers|views) [ -d "$SPECS_DIR/$REL" ] || REL="${REL%s}" ;;
  esac
  if [ -z "$REL" ]; then
    FILTER=""
  elif [[ "$REL" =~ ^[A-Za-z0-9_]+(/[A-Za-z0-9_]+)*$ ]] && { [ -d "$SPECS_DIR/$REL" ] || [ -f "$SPECS_DIR/$REL.cfc" ]; }; then
    # A folder, or one spec file: the runner runs a file as its one bundle (#3759).
    FILTER="wheels.tests.specs.${REL//\//.}"
  else
    echo "ERROR: unknown test area '${1}'." >&2
    echo "  Valid areas (directories under $SPECS_DIR/): $(list_areas)" >&2
    echo "  Also accepted: a nested path (model/associations), one spec file (dispatch/TestScopeVisibilitySpec), or the dotted form (wheels.tests.specs.model)." >&2
    exit 2
  fi
fi

# ── Ensure SQLite test databases exist ──────────────
sqlite3 wheelstestdb.db "SELECT 1;" 2>/dev/null || true
sqlite3 wheelstestdb_tenant_b.db "SELECT 1;" 2>/dev/null || true

# Everything this script leaves in the checkout while it runs. The backup
# name is script-specific so a user's own lucee.json.bak is never taken for
# ours; the lock records which run owns the other two (#3771).
LUCEE_BAK="lucee.json.test-local.bak"
RUN_LOCK="$PROJECT_ROOT/.wheels-test-local.lock"

# The server this script starts gets a name of its own, per checkout. The
# name LuCLI takes from lucee.json ("wheels" here) is shared by every
# checkout and worktree: a run was refused while another checkout's server
# ran, and --force deleted another checkout's stopped registration (#3810).
CHECKOUT_KEY="$(cd "$PROJECT_ROOT" && pwd -P | shasum | cut -c1-12)"
TEST_SERVER_NAME="wheels-test-${CHECKOUT_KEY}"
TEST_SERVER_DIR="$HOME/.wheels/servers/$TEST_SERVER_NAME"
SERVER_LOG="/tmp/wheels-test-server-${CHECKOUT_KEY}.log"

# ── Server ownership helpers ────────────────────────
#
# The CLI records which project a server belongs to in
# ~/.wheels/servers/<name>/.project-path, and its JVM as "<pid>:<port>" in
# server.pid. Both are authoritative; probing the port is not, because any
# HTTP responder there will answer — including a completely different app.
#
# More than one registration can point at the same project: the name LuCLI
# uses comes from lucee.json's "name", and a registration left under an
# earlier name keeps the same .project-path. Prefer the one named after
# lucee.json; a stale one sorted first made the next run refuse its own
# server (#3771).
lucee_server_name() {
  sed -n 's/^[[:space:]]*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$PROJECT_ROOT/lucee.json" 2>/dev/null | head -1
}

project_server_dir() {
  local d real name project_real fallback=""
  project_real="$(cd "$PROJECT_ROOT" && pwd -P)"
  name="$(lucee_server_name)"
  if [ -n "$name" ] && [ -f "$HOME/.wheels/servers/$name/.project-path" ]; then
    real="$(cd "$(cat "$HOME/.wheels/servers/$name/.project-path")" 2>/dev/null && pwd -P)" || real=""
    if [ "$real" = "$project_real" ]; then
      printf '%s\n' "$HOME/.wheels/servers/$name"
      return 0
    fi
  fi
  for d in "$HOME"/.wheels/servers/*/; do
    [ -f "${d}.project-path" ] || continue
    real="$(cd "$(cat "${d}.project-path")" 2>/dev/null && pwd -P)" || continue
    [ "$real" = "$project_real" ] || continue
    [ -n "$fallback" ] || fallback="${d%/}"
  done
  [ -n "$fallback" ] || return 1
  printf '%s\n' "$fallback"
}

listener_pid() {
  lsof -ti :"$1" -sTCP:LISTEN 2>/dev/null | head -1
}

# True when PID is still provably ours: the process listening on PORT (the
# caller only passes a PID it recorded for that port), or a child of this
# script (the launcher). A bare "is alive" check is not enough: once our
# process exits, the OS can give its PID, or another process the port, to
# something unrelated (#3771).
pid_is_ours() {
  local pid="$1" port="$2"
  [ -n "$pid" ] || return 1
  [ -n "$port" ] && [ "$(listener_pid "$port" || true)" = "$pid" ] && return 0
  [ "$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')" = "$$" ] && return 0
  return 1
}

# True when PID is ANCESTOR or one of its descendants.
# Usage: is_descendant_of <pid> <ancestor>
is_descendant_of() {
  local pid="$1" ancestor="$2"
  [ -n "$pid" ] && [ -n "$ancestor" ] || return 1
  for _ in $(seq 1 32); do
    [ "$pid" = "$ancestor" ] && return 0
    case "$pid" in ""|0|1) return 1 ;; esac
    pid="$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')"
  done
  return 1
}

# SIGTERM the given PIDs that are still ours on PORT, wait (bounded) for
# those, then SIGKILL only survivors that are still ours. A PID that is not
# ours is left alone, and not waited on.
# Usage: stop_pids <port> <pid>...
stop_pids() {
  local port="$1" pid alive signalled=""
  shift
  for pid in "$@"; do
    pid_is_ours "$pid" "$port" && kill "$pid" 2>/dev/null && signalled="$signalled $pid"
  done
  [ -n "$signalled" ] || return 0
  for _ in $(seq 1 20); do
    alive=""
    for pid in $signalled; do kill -0 "$pid" 2>/dev/null && alive="$alive $pid"; done
    [ -n "$alive" ] || return 0
    sleep 0.5
  done
  for pid in $alive; do pid_is_ours "$pid" "$port" && kill -9 "$pid" 2>/dev/null; done
  return 0
}

# The PID recorded in this checkout's lock. A run writes it just after its
# mkdir, so a lock with no PID yet may belong to a run that is starting right
# now: wait briefly for it before treating the lock as stale (#3796).
lock_owner_pid() {
  local owner
  for _ in $(seq 1 20); do
    owner="$(cat "$RUN_LOCK/pid" 2>/dev/null || true)"
    if [ -n "$owner" ]; then
      printf '%s\n' "$owner"
      return 0
    fi
    sleep 0.1
  done
  return 1
}

# The run that owns this checkout's lock, if it is still alive. PID alone is
# not proof (a dead run's PID can be reused), so the process must also still
# be this script.
live_lock_owner() {
  local owner
  owner="$(lock_owner_pid || true)"
  [ -n "$owner" ] && [ "$owner" != "$$" ] || return 1
  kill -0 "$owner" 2>/dev/null || return 1
  ps -o command= -p "$owner" 2>/dev/null | grep -q 'test-local\.sh' || return 1
  printf '%s\n' "$owner"
}

# Take this checkout's run lock. mkdir is atomic, so two runs starting at
# once cannot both win. A lock whose owner is gone is stale: that run was
# killed before its EXIT trap, and its server marker and lucee.json backup
# are now ours to recover. A live owner means a run is in progress, and
# touching its server or lucee.json would break it, so refuse.
acquire_run_lock() {
  local owner
  if ! mkdir "$RUN_LOCK" 2>/dev/null; then
    if owner="$(live_lock_owner)"; then
      echo "::error::Another tools/test-local.sh run (PID ${owner}) is using this checkout." >&2
      echo "  It owns the test server and lucee.json until it exits; running now would stop" >&2
      echo "  its server mid-suite. Wait for it, or run from a separate worktree." >&2
      exit 1
    fi
    # The lock is stale. Several runs can find the same stale lock at once,
    # and each replacing it lets a slow one delete the lock another just made,
    # so only the run that creates the takeover lock (mkdir is atomic) may
    # replace it, after checking again that nothing live owns it (#3796). A
    # takeover lock a killed run left behind is cleared after a minute.
    if [ -d "$RUN_LOCK.takeover" ] && [ -n "$(find "$RUN_LOCK.takeover" -prune -mmin +1 2>/dev/null)" ]; then
      rm -rf "$RUN_LOCK.takeover"
    fi
    if ! mkdir "$RUN_LOCK.takeover" 2>/dev/null; then
      echo "::error::Another tools/test-local.sh run is taking over this checkout's stale lock right now." >&2
      echo "  Run again once it has started, or run from a separate worktree." >&2
      exit 1
    fi
    if owner="$(live_lock_owner)"; then
      rmdir "$RUN_LOCK.takeover" 2>/dev/null || true
      echo "::error::Another tools/test-local.sh run (PID ${owner}) is using this checkout." >&2
      echo "  Wait for it, or run from a separate worktree." >&2
      exit 1
    fi
    rm -rf "$RUN_LOCK"
    if ! mkdir "$RUN_LOCK" 2>/dev/null; then
      rmdir "$RUN_LOCK.takeover" 2>/dev/null || true
      echo "::error::Another tools/test-local.sh run took this checkout's lock just now." >&2
      exit 1
    fi
    # Written whole, then renamed, so a reader never sees a partial PID.
    echo "$$" > "$RUN_LOCK/pid.$$" && mv "$RUN_LOCK/pid.$$" "$RUN_LOCK/pid"
    RUN_LOCK_HELD=true
    rmdir "$RUN_LOCK.takeover" 2>/dev/null || true
    return 0
  fi
  # Written whole, then renamed, so a reader never sees a partial PID.
  echo "$$" > "$RUN_LOCK/pid.$$" && mv "$RUN_LOCK/pid.$$" "$RUN_LOCK/pid"
  RUN_LOCK_HELD=true
}

# The JVM a previous run of this script recorded and did not get to stop
# (it was killed, or its cleanup failed). ".wheels-test-server.pid" is
# written only by this script, and this run holds the checkout's lock, so
# the run that wrote it is gone; a PID in it is ours to stop only while it
# still listens on the port it recorded.
stop_orphaned_test_server() {
  local record jvm port
  # The marker, and this checkout's own registration: a run killed during
  # startup never wrote the marker, but its JVM is recorded there. No other
  # run can own that registration while this run holds the lock (#3810).
  for record in "$PROJECT_ROOT/.wheels-test-server.pid" "$TEST_SERVER_DIR/server.pid"; do
    [ -f "$record" ] || continue
    jvm="$(cut -d: -f1 "$record" 2>/dev/null || true)"
    port="$(cut -d: -f2 "$record" 2>/dev/null || true)"
    # Only while it still listens on the port it recorded: a record that
    # outlived a reboot may name a PID the OS has since given to another process.
    if [ -n "$jvm" ] && [ -n "$port" ] && [ "$(listener_pid "$port" || true)" = "$jvm" ]; then
      echo "Stopping a test server a previous run left behind (PID ${jvm})..."
      stop_pids "$port" "$jvm"
    fi
  done
  rm -f "$PROJECT_ROOT/.wheels-test-server.pid"
}

cleanup() {
  # Stop the server BEFORE restoring lucee.json: `wheels server stop` reads
  # the ports from lucee.json, and restoring first pointed it at 8080/8081
  # instead of the ports this run pinned (#3771).
  if [ "${STARTED_SERVER:-false}" = "true" ]; then
    echo "Stopping test server..."
    ( cd "$PROJECT_ROOT" && wheels server stop --name="$TEST_SERVER_NAME" >/dev/null 2>&1 ) || true
    # `kill $SERVER_PID` only kills the launcher: the JVM survives it and keeps
    # holding the port, so whichever project wants that port next silently gets
    # THIS app's responses. Stop the JVMs this run recorded (the registry's, and
    # the one that answered on PORT when the server came up), but only while
    # they still hold PORT: never whatever happens to listen there now (#3771).
    local jvm pids=""
    jvm="$(cut -d: -f1 "$PROJECT_ROOT/.wheels-test-server.pid" 2>/dev/null || true)"
    [ -n "$jvm" ] && pids="$jvm"
    [ -n "${STARTED_PORT_PID:-}" ] && [ "$STARTED_PORT_PID" != "$jvm" ] && pids="$pids $STARTED_PORT_PID"
    [ -n "${SERVER_PID:-}" ] && pids="$pids $SERVER_PID"
    # shellcheck disable=SC2086
    stop_pids "$PORT" $pids
    rm -f "$PROJECT_ROOT/.wheels-test-server.pid"
    # The registration is this run's alone (its name is per checkout), so
    # remove it rather than leave a server directory behind per worktree.
    case "$TEST_SERVER_NAME" in
      wheels-test-?*) rm -rf "$TEST_SERVER_DIR" ;;
    esac
  fi
  # Restore original lucee.json if we modified it
  if [ "${RESTORED_LUCEE_JSON:-false}" = "true" ] && [ -f "$LUCEE_BAK" ]; then
    mv "$LUCEE_BAK" lucee.json
  fi
  # Release the lock last, once nothing of this run is left behind.
  if [ "${RUN_LOCK_HELD:-false}" = "true" ]; then
    rm -rf "$RUN_LOCK"
  fi
}

# Before the trap: a run refused here must not run cleanup(), which would
# stop the lock owner's server and restore lucee.json underneath it.
acquire_run_lock
trap cleanup EXIT

# ── Recover from an interrupted run ─────────────────
# A run killed before its EXIT trap (e.g. kill -9) leaves lucee.json with
# its pinned ports and the original in $LUCEE_BAK. This run holds the lock,
# so that run is gone: restore the original before anything below copies
# lucee.json over the backup (#3771).
if [ -f "$LUCEE_BAK" ]; then
  echo "Restoring lucee.json from an interrupted run's ${LUCEE_BAK}..."
  mv "$LUCEE_BAK" lucee.json
fi
# Before #3789 the backup was named lucee.json.bak, which a user may also use
# for their own copy, so it is never restored automatically. Say so when one
# differs from lucee.json: an interrupted older run leaves lucee.json pinned
# to its ports (#3796).
if [ -f lucee.json.bak ] && ! cmp -s lucee.json lucee.json.bak; then
  echo "::warning::Found lucee.json.bak, which differs from lucee.json. If an interrupted run of an" >&2
  echo "  older tools/test-local.sh left lucee.json pinned to its ports, restore it with:" >&2
  echo "  mv lucee.json.bak lucee.json" >&2
fi

# ── Resolve {project} placeholder if the Wheels CLI doesn't support it yet ──
# Check if lucee.json has {project} and the runtime version is too old to
# resolve the placeholder.
if grep -q '{project}' lucee.json 2>/dev/null; then
  WHEELS_VER=$(wheels --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "0.0.0")
  # For safety, always create a resolved copy for the server
  cp lucee.json "$LUCEE_BAK"
  sed -i '' "s|{project}|${PROJECT_ROOT}|g" lucee.json
  RESTORED_LUCEE_JSON=true
fi

# ── Start server if not already running ─────────────
stop_orphaned_test_server
STARTED_SERVER=false
EXISTING_PID="$(listener_pid "$PORT" || true)"
if [ -n "$EXISTING_PID" ]; then
  OWN_DIR="$(project_server_dir || true)"
  OWN_PID=""
  if [ -n "$OWN_DIR" ] && [ -f "$OWN_DIR/server.pid" ]; then
    OWN_PID="$(cut -d: -f1 "$OWN_DIR/server.pid" 2>/dev/null || true)"
  fi
  if [ -z "$OWN_PID" ] || [ "$OWN_PID" != "$EXISTING_PID" ]; then
    echo "::error::Port ${PORT} is held by PID ${EXISTING_PID}, which is not this project's server." >&2
    echo "  Refusing to run — testing a foreign server reports results for the wrong app." >&2
    if [ -n "$OWN_DIR" ]; then
      echo "  This project's registered server: $(basename "$OWN_DIR")" >&2
    else
      echo "  This project has no registered server." >&2
    fi
    echo "  Fix: stop PID ${EXISTING_PID}, or re-run with PORT=<free port>." >&2
    exit 1
  fi
  echo "Using existing server on port ${PORT} (PID ${EXISTING_PID}, this project)"
else
  echo "Starting Wheels CLI server on port ${PORT}..."

  # lucee.json pins BOTH ports (8080 + shutdown 8081). `--port` moves only the
  # HTTP port, so `PORT=9090` still tried to bind shutdown 8081 and died with
  # "port conflicts detected:" (empty list) whenever any other Wheels app held
  # it. Pin a free shutdown port next to the HTTP port for this run; cleanup()
  # already restores $LUCEE_BAK — this is what actually creates it.
  if [ "$PORT" != "8080" ] && [ -f lucee.json ]; then
    SHUTDOWN_PORT=$((PORT + 1))
    while lsof -nP -iTCP:"$SHUTDOWN_PORT" -sTCP:LISTEN >/dev/null 2>&1; do
      SHUTDOWN_PORT=$((SHUTDOWN_PORT + 1))
    done
    # A {project}-resolved copy above already backed up the original.
    [ -f "$LUCEE_BAK" ] || cp lucee.json "$LUCEE_BAK"
    RESTORED_LUCEE_JSON=true
    sed -i.tmp -E \
      -e "s/(\"port\"[[:space:]]*:[[:space:]]*)[0-9]+/\1${PORT}/" \
      -e "s/(\"shutdownPort\"[[:space:]]*:[[:space:]]*)[0-9]+/\1${SHUTDOWN_PORT}/" \
      lucee.json && rm -f lucee.json.tmp
    echo "Pinned lucee.json to port ${PORT}, shutdown ${SHUTDOWN_PORT} for this run"
  fi

  # Locate Lucee Express's lib/ext so we can drop the SQLite JDBC there.
  # `|| true` keeps `set -e` from killing the script when the directory is
  # missing — `find` exits non-zero on missing path args (stderr suppressed
  # via 2>/dev/null but the exit status survives pipefail).
  LUCEE_LIB=$(find ~/.wheels/express -path "*/lib/ext" -type d 2>/dev/null | head -1 || true)
  if [ -n "$LUCEE_LIB" ] && ! ls "$LUCEE_LIB"/sqlite-jdbc*.jar 1>/dev/null 2>&1; then
    echo "Downloading SQLite JDBC driver..."
    curl -sL "https://repo1.maven.org/maven2/org/xerial/sqlite-jdbc/3.49.1.0/sqlite-jdbc-3.49.1.0.jar" \
      -o "$LUCEE_LIB/sqlite-jdbc-3.49.1.0.jar"
  fi

  nohup wheels server run --port="$PORT" --name="$TEST_SERVER_NAME" --force > "$SERVER_LOG" 2>&1 &
  SERVER_PID=$!
  STARTED_SERVER=true

  echo "Waiting for server..."
  for i in $(seq 1 60); do
    if curl -s -o /dev/null --connect-timeout 2 --max-time 3 "http://localhost:${PORT}/" 2>/dev/null; then
      echo "Server ready (attempt $i)"
      # The port was free when this run started, so its listener now is ours.
      STARTED_PORT_PID="$(listener_pid "$PORT" || true)"
      break
    fi
    if ! kill -0 "$SERVER_PID" 2>/dev/null; then
      echo "Server process died. Check ${SERVER_LOG}"
      tail -20 "$SERVER_LOG" 2>/dev/null
      exit 1
    fi
    sleep 2
  done

  # Record the JVM (not the launcher) so cleanup can stop what actually holds
  # the port. The registry writes "<pid>:<port>" once the server is up.
  if [ -f "$TEST_SERVER_DIR/server.pid" ]; then
    cp "$TEST_SERVER_DIR/server.pid" "$PROJECT_ROOT/.wheels-test-server.pid"
  fi

  # The listener captured above is this run's server only if it is the
  # registry's JVM or a descendant of the launcher. Another process can bind
  # the port between the free-port check and our JVM's bind; it then answers
  # the test requests, and cleanup must not stop it (#3796).
  if [ -n "${STARTED_PORT_PID:-}" ]; then
    REGISTRY_JVM="$(cut -d: -f1 "$PROJECT_ROOT/.wheels-test-server.pid" 2>/dev/null || true)"
    if [ "$STARTED_PORT_PID" != "$REGISTRY_JVM" ] && ! is_descendant_of "$STARTED_PORT_PID" "$SERVER_PID"; then
      echo "::error::Port ${PORT} is answered by PID ${STARTED_PORT_PID}, which this run did not start." >&2
      echo "  Refusing to run — testing a foreign server reports results for the wrong app." >&2
      echo "  Fix: stop PID ${STARTED_PORT_PID}, or re-run with PORT=<free port>." >&2
      STARTED_PORT_PID=""
      exit 1
    fi
  fi
fi

# ── Warm up Wheels ──────────────────────────────────
echo "Warming up..."
curl -s -o /dev/null --max-time 120 "http://localhost:${PORT}/?reload=true&password=${PASSWORD}" || true
sleep 2

# ── Run tests ───────────────────────────────────────
TEST_URL="http://localhost:${PORT}/wheels/core/tests?db=${DB}&format=json"
if [ -n "$FILTER" ]; then
  # Already resolved and validated above.
  TEST_URL="${TEST_URL}&directory=${FILTER}"
fi

echo "Running tests: Lucee 7 + SQLite${FILTER:+ (filter: $FILTER)}"
# Clear it first. When the request fails outright — a server that is not up yet reports
# HTTP 000 — curl may write nothing, leaving the PREVIOUS run's results sitting there to
# be read as if they were this run's (issue #3352). A crashed run must leave no result.
rm -f "$RESULT_FILE"
HTTP_CODE=$(curl -s -o "$RESULT_FILE" \
  --max-time 600 \
  --write-out "%{http_code}" \
  "$TEST_URL" || echo "000")

# ── Parse and display results ───────────────────────
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "417" ]; then
  python3 -c "
import json, sys
d = json.load(open('$RESULT_FILE'))
p = int(d.get('totalPass', 0))
f = int(d.get('totalFail', 0))
e = int(d.get('totalError', 0))
dur = float(d.get('totalDuration', 0)) / 1000

# Scope-visibility guard (issue #3083): a rejected directory= (silently
# swapped for the full default suite) or a 0-bundle discovery must fail
# loudly instead of masquerading as a green run for the wrong scope.
scope_bad = False
for w in d.get('warnings', []):
    print(f'\033[33mWARNING: {w}\033[0m', file=sys.stderr)
if d.get('directoryRejected'):
    print('\033[31mERROR: the requested directory= was rejected; the full default suite ran instead\033[0m', file=sys.stderr)
    scope_bad = True
if int(d.get('bundlesDiscovered', -1)) == 0:
    print('\033[31mERROR: 0 test bundles discovered for the resolved scope — vacuously green run\033[0m', file=sys.stderr)
    scope_bad = True
if scope_bad:
    sys.exit(1)

if f == 0 and e == 0:
    print(f'\033[32m✓ {p} passed ({dur:.1f}s)\033[0m')
else:
    print(f'\033[31m✗ {p} passed, {f} failed, {e} errors ({dur:.1f}s)\033[0m')
    for b in d.get('bundleStats', []):
        for s in b.get('suiteStats', []):
            for sp in s.get('specStats', []):
                if sp.get('status') in ('Failed', 'Error'):
                    print(f'  {sp[\"status\"]}: {sp.get(\"name\",\"?\")}: {sp.get(\"failMessage\",\"\")[:150]}')
    sys.exit(1)
"
else
  echo "Tests returned HTTP ${HTTP_CODE}"
  head -20 "$RESULT_FILE" 2>/dev/null || true
  exit 1
fi
