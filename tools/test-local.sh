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
#   PORT=9090 bash tools/test-local.sh                # use custom port
#
# An area that is not a directory under vendor/wheels/tests/specs/ exits 2
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
    wheels.tests.specs.*) REL="${REL#wheels.tests.specs.}"; REL="${REL//./\/}"; [ -n "$REL" ] || REL="." ;;
    *) REL="${REL%/}" ;;
  esac
  # Plural aliases for the three areas that have always accepted them.
  case "$REL" in
    models|controllers|views) [ -d "$SPECS_DIR/$REL" ] || REL="${REL%s}" ;;
  esac
  if [ -z "$REL" ]; then
    FILTER=""
  elif [[ "$REL" =~ ^[A-Za-z0-9_]+(/[A-Za-z0-9_]+)*$ ]] && [ -d "$SPECS_DIR/$REL" ]; then
    FILTER="wheels.tests.specs.${REL//\//.}"
  else
    echo "ERROR: unknown test area '${1}'." >&2
    echo "  Valid areas (directories under $SPECS_DIR/): $(list_areas)" >&2
    echo "  Also accepted: a nested path (model/associations) or the dotted form (wheels.tests.specs.model)." >&2
    exit 2
  fi
fi

# ── Ensure SQLite test databases exist ──────────────
sqlite3 wheelstestdb.db "SELECT 1;" 2>/dev/null || true
sqlite3 wheelstestdb_tenant_b.db "SELECT 1;" 2>/dev/null || true

# ── Recover from an interrupted run ─────────────────
# A run killed before its EXIT trap (e.g. kill -9) leaves lucee.json with
# this run's pinned ports and the original in lucee.json.bak. Restore it
# before anything below copies lucee.json over that backup (#3771).
if [ -f lucee.json.bak ]; then
  echo "Restoring lucee.json from a previous run's lucee.json.bak..."
  mv lucee.json.bak lucee.json
fi

# ── Resolve {project} placeholder if the Wheels CLI doesn't support it yet ──
# Check if lucee.json has {project} and the runtime version is too old to
# resolve the placeholder.
if grep -q '{project}' lucee.json 2>/dev/null; then
  WHEELS_VER=$(wheels --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "0.0.0")
  # For safety, always create a resolved copy for the server
  cp lucee.json lucee.json.bak
  sed -i '' "s|{project}|${PROJECT_ROOT}|g" lucee.json
  RESTORED_LUCEE_JSON=true
fi

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

# SIGTERM the given PIDs, wait (bounded), then SIGKILL only those that are
# still the process we signalled. A PID that exited during the grace period
# may already belong to an unrelated process.
stop_pids() {
  local pid alive
  [ -n "$*" ] || return 0
  for pid in "$@"; do kill "$pid" 2>/dev/null || true; done
  for _ in $(seq 1 20); do
    alive=""
    for pid in "$@"; do kill -0 "$pid" 2>/dev/null && alive="$alive $pid"; done
    [ -n "$alive" ] || return 0
    sleep 0.5
  done
  for pid in $alive; do kill -9 "$pid" 2>/dev/null || true; done
}

# The JVM a previous run of this script recorded and did not get to stop
# (it was killed, or its cleanup failed). ".wheels-test-server.pid" is
# written only by this script, so a live PID in it is ours to stop.
stop_orphaned_test_server() {
  local marker="$PROJECT_ROOT/.wheels-test-server.pid" jvm port
  [ -f "$marker" ] || return 0
  jvm="$(cut -d: -f1 "$marker" 2>/dev/null || true)"
  port="$(cut -d: -f2 "$marker" 2>/dev/null || true)"
  # Only while it still listens on the port it recorded: a marker that
  # outlived a reboot may name a PID the OS has since given to another process.
  if [ -n "$jvm" ] && [ -n "$port" ] && [ "$(listener_pid "$port" || true)" = "$jvm" ]; then
    echo "Stopping a test server a previous run left behind (PID ${jvm})..."
    stop_pids "$jvm"
  fi
  rm -f "$marker"
}

cleanup() {
  # Stop the server BEFORE restoring lucee.json: `wheels server stop` reads
  # the ports from lucee.json, and restoring first pointed it at 8080/8081
  # instead of the ports this run pinned (#3771).
  if [ "${STARTED_SERVER:-false}" = "true" ]; then
    echo "Stopping test server..."
    ( cd "$PROJECT_ROOT" && wheels server stop >/dev/null 2>&1 ) || true
    # `kill $SERVER_PID` only kills the launcher: the JVM survives it and keeps
    # holding the port, so whichever project wants that port next silently gets
    # THIS app's responses. Stop the JVM the registry recorded, and whatever
    # listens on the port this run found free and started on.
    local jvm port_jvm pids=""
    jvm="$(cut -d: -f1 "$PROJECT_ROOT/.wheels-test-server.pid" 2>/dev/null || true)"
    port_jvm="$(listener_pid "$PORT" || true)"
    [ -n "$jvm" ] && pids="$jvm"
    [ -n "$port_jvm" ] && [ "$port_jvm" != "$jvm" ] && pids="$pids $port_jvm"
    [ -n "${SERVER_PID:-}" ] && pids="$pids $SERVER_PID"
    # shellcheck disable=SC2086
    stop_pids $pids
    rm -f "$PROJECT_ROOT/.wheels-test-server.pid"
  fi
  # Restore original lucee.json if we modified it
  if [ "${RESTORED_LUCEE_JSON:-false}" = "true" ] && [ -f lucee.json.bak ]; then
    mv lucee.json.bak lucee.json
  fi
}
trap cleanup EXIT

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
  # already restores lucee.json.bak — this is what actually creates it.
  if [ "$PORT" != "8080" ] && [ -f lucee.json ]; then
    SHUTDOWN_PORT=$((PORT + 1))
    while lsof -nP -iTCP:"$SHUTDOWN_PORT" -sTCP:LISTEN >/dev/null 2>&1; do
      SHUTDOWN_PORT=$((SHUTDOWN_PORT + 1))
    done
    cp lucee.json lucee.json.bak
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

  nohup wheels server run --port="$PORT" --force > /tmp/wheels-test-server.log 2>&1 &
  SERVER_PID=$!
  STARTED_SERVER=true

  echo "Waiting for server..."
  for i in $(seq 1 60); do
    if curl -s -o /dev/null --connect-timeout 2 --max-time 3 "http://localhost:${PORT}/" 2>/dev/null; then
      echo "Server ready (attempt $i)"
      break
    fi
    if ! kill -0 "$SERVER_PID" 2>/dev/null; then
      echo "Server process died. Check /tmp/wheels-test-server.log"
      cat /tmp/wheels-test-server.log 2>/dev/null | tail -20
      exit 1
    fi
    sleep 2
  done

  # Record the JVM (not the launcher) so cleanup can stop what actually holds
  # the port. The registry writes "<pid>:<port>" once the server is up.
  OWN_DIR="$(project_server_dir || true)"
  if [ -n "$OWN_DIR" ] && [ -f "$OWN_DIR/server.pid" ]; then
    cp "$OWN_DIR/server.pid" "$PROJECT_ROOT/.wheels-test-server.pid"
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
