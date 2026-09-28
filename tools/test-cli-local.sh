#!/usr/bin/env bash
# Run CLI-layer tests (cli/lucli/tests/specs/**) locally via LuCLI + SQLite.
#
# Companion to tools/test-local.sh. Where that script runs core framework
# tests at /wheels/core/tests, this one runs the CLI module's own spec
# suite at /cli/lucli/tests/runner.cfm.
#
# Prerequisites:
#   - Wheels CLI installed (brew install wheels, choco, or a GitHub release).
#     Wheels is built on the LuCLI runtime and ships it under the `wheels`
#     brand, so a normal install has no separate `lucli` binary. A raw
#     `lucli` (0.3.3+) also works — CI installs one — and is preferred when
#     both are on PATH.
#   - Java 21+
#
# Usage:
#   bash tools/test-cli-local.sh              # run all CLI specs
#   PORT=9090 bash tools/test-cli-local.sh    # custom port
#   LUCLI_BIN=/path/to/lucli bash tools/test-cli-local.sh   # pick the runtime
#   WHEELS_CLI_FALLBACK_SENTINEL=1 PORT=8190 bash tools/test-cli-local.sh
#       # guard the CLI's common fallback ports (8080, 60000, 3000, 8500) with
#       # tools/ci/fallback_port_sentinel.py and fail the run if anything in
#       # it contacts them. Run the suite's own server on a port outside that
#       # list, or the sentinel cannot guard the port the server holds.
#
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PORT="${PORT:-8080}"
# Must match set(reloadPassword=...) in config/settings.cfm — a mismatch never
# reloads and, since #3062, counts against the per-IP reload rate limit.
PASSWORD="wheels-dev"
# Per-checkout results file (same scheme as tools/test-local.sh, #3352): a
# fixed /tmp path let concurrent checkouts overwrite each other's results.
# CI sets WHEELS_CLI_TEST_RESULT_FILE and uploads it as an artifact (#3694).
# shasum is not on every system; fall back rather than die under `set -e`.
CHECKOUT_KEY="$(echo "$PROJECT_ROOT" | { shasum 2>/dev/null || sha1sum 2>/dev/null || cksum; } | cut -c1-12 | tr -d ' ')"
RESULT_FILE="${WHEELS_CLI_TEST_RESULT_FILE:-/tmp/wheels-cli-test-results-${CHECKOUT_KEY}.json}"

cd "$PROJECT_ROOT"

# ── Runtime binary ──────────────────────────────────
# Resolve once and use everywhere: $LUCLI_BIN if set, else a raw `lucli` on
# PATH (what CI installs), else the `wheels` binary a normal install ships —
# it IS the LuCLI runtime and takes the same `server run/stop` flags.
if [ -n "${LUCLI_BIN:-}" ]; then
  if [ ! -x "$LUCLI_BIN" ] && ! command -v "$LUCLI_BIN" >/dev/null 2>&1; then
    echo "::error::LUCLI_BIN=${LUCLI_BIN} is not an executable." >&2
    exit 2
  fi
  CLI_BIN="$LUCLI_BIN"
elif command -v lucli >/dev/null 2>&1; then
  CLI_BIN="lucli"
elif command -v wheels >/dev/null 2>&1; then
  CLI_BIN="wheels"
else
  echo "::error::Neither 'lucli' nor 'wheels' is on PATH. Install the Wheels CLI or set LUCLI_BIN." >&2
  exit 2
fi
# Where the runtime may extract Lucee Express — only a fallback: the running
# JVM's -Dcatalina.home (below) is authoritative. The binary's name does not
# tell us the home: the brew `wheels` wrapper sets LUCLI_HOME=~/.wheels and
# execs a raw binary that is also named `wheels`.
EXPRESS_HOMES=("$HOME/.wheels/express" "$HOME/.lucli/express")
if [ -n "${LUCLI_HOME:-}" ]; then
  EXPRESS_HOMES=("$LUCLI_HOME/express" "${EXPRESS_HOMES[@]}")
fi
echo "Using runtime: ${CLI_BIN} ($(command -v "$CLI_BIN" 2>/dev/null || echo "$CLI_BIN"))"

# Ensure JAVA_HOME is set (`server run` needs it explicitly on some macOS setups).
if [ -z "${JAVA_HOME:-}" ]; then
  if command -v /usr/libexec/java_home >/dev/null 2>&1; then
    export JAVA_HOME="$(/usr/libexec/java_home -v 21 2>/dev/null || /usr/libexec/java_home 2>/dev/null || true)"
  fi
fi

# ── Server ownership helpers ────────────────────────
#
# The CLI records which project a server belongs to in
# ~/.wheels/servers/<name>/.project-path, and its JVM as "<pid>:<port>" in
# server.pid. Both are authoritative; probing the port is not, because any
# HTTP responder there will answer — including a completely different app.
project_server_dir() {
  local d real
  for d in "$HOME"/.wheels/servers/*/; do
    [ -f "${d}.project-path" ] || continue
    real="$(cd "$(cat "${d}.project-path")" 2>/dev/null && pwd -P)" || continue
    if [ "$real" = "$(cd "$PROJECT_ROOT" && pwd -P)" ]; then
      printf '%s\n' "${d%/}"
      return 0
    fi
  done
  return 1
}

listener_pid() {
  lsof -ti :"$1" -sTCP:LISTEN 2>/dev/null | head -1
}

# ── Lifecycle ───────────────────────────────────────
cleanup() {
  if [ -n "${SENTINEL_PID:-}" ]; then
    kill "$SENTINEL_PID" 2>/dev/null || true
    wait "$SENTINEL_PID" 2>/dev/null || true
    SENTINEL_PID=""
  fi
  # Put lucee.json back first, on EVERY exit path — success, a red suite, or
  # Ctrl-C — so an overridden PORT never leaves the repo dirty. Guarded: the
  # restore helper is defined further down, and an early exit (e.g. the
  # ownership refusal above it) reaches this trap before it exists.
  if declare -F restore_lucee_json >/dev/null 2>&1; then
    restore_lucee_json
  fi
  if [ "${STARTED_SERVER:-false}" = "true" ]; then
    echo "Stopping test server..."
    ( cd "$PROJECT_ROOT" && "$CLI_BIN" server stop >/dev/null 2>&1 ) || true
    # `kill $SERVER_PID` only kills the launcher: the JVM survives it and keeps
    # holding the port, so whichever project wants that port next silently gets
    # THIS app's responses. Kill the JVM the registry recorded, then wait for
    # the port to actually come free.
    local jvm
    jvm="$(cut -d: -f1 "$PROJECT_ROOT/.wheels-test-server.pid" 2>/dev/null || true)"
    if [ -n "$jvm" ]; then
      kill "$jvm" 2>/dev/null || true
      for _ in $(seq 1 20); do
        kill -0 "$jvm" 2>/dev/null || break
        sleep 0.5
      done
      kill -9 "$jvm" 2>/dev/null || true
    fi
    rm -f "$PROJECT_ROOT/.wheels-test-server.pid"
  fi
}
trap cleanup EXIT

# ── Start server if not already running ─────────────
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
  echo "Starting ${CLI_BIN} server on port ${PORT}..."

  # lucee.json pins BOTH ports (8080 + shutdown 8081). `--port` moves only the
  # HTTP port, so `PORT=8180` still tried to bind shutdown 8081 and died with
  # LuCLI's "port conflicts detected:" (empty list) whenever any other Wheels
  # app — e.g. a live blogdemo — held it. Mirror what `wheels start` does:
  # pick a free shutdown port next to the HTTP port and pin both for this run,
  # then put the file back exactly as it was so the repo is never left dirty.
  LUCEE_JSON="$PROJECT_ROOT/lucee.json"
  LUCEE_JSON_BACKUP=""
  next_free_port() {
    local p="$1"
    while lsof -nP -iTCP:"$p" -sTCP:LISTEN >/dev/null 2>&1; do p=$((p + 1)); done
    echo "$p"
  }
  restore_lucee_json() {
    if [ -n "$LUCEE_JSON_BACKUP" ] && [ -f "$LUCEE_JSON_BACKUP" ]; then
      mv "$LUCEE_JSON_BACKUP" "$LUCEE_JSON"
      LUCEE_JSON_BACKUP=""
    fi
  }
  if [ "$PORT" != "8080" ] && [ -f "$LUCEE_JSON" ]; then
    SHUTDOWN_PORT="$(next_free_port $((PORT + 1)))"
    LUCEE_JSON_BACKUP="$(mktemp /tmp/lucee.json.XXXXXX)"
    cp "$LUCEE_JSON" "$LUCEE_JSON_BACKUP"
    sed -i.tmp -E \
      -e "s/(\"port\"[[:space:]]*:[[:space:]]*)[0-9]+/\1${PORT}/" \
      -e "s/(\"shutdownPort\"[[:space:]]*:[[:space:]]*)[0-9]+/\1${SHUTDOWN_PORT}/" \
      "$LUCEE_JSON" && rm -f "${LUCEE_JSON}.tmp"
    echo "Pinned lucee.json to port ${PORT}, shutdown ${SHUTDOWN_PORT} for this run"
  fi

  start_lucli() {
    nohup "$CLI_BIN" server run --port="$PORT" --force > /tmp/wheels-cli-test-server.log 2>&1 &
    SERVER_PID=$!
    STARTED_SERVER=true
  }

  wait_for_server() {
    for i in $(seq 1 120); do
      if curl -s -o /dev/null --connect-timeout 2 --max-time 3 "http://localhost:${PORT}/" 2>/dev/null; then
        echo "Server ready (attempt $i)"
        return 0
      fi
      if ! kill -0 "$SERVER_PID" 2>/dev/null; then
        echo "Server process died. Check /tmp/wheels-cli-test-server.log"
        cat /tmp/wheels-cli-test-server.log 2>/dev/null | tail -20
        exit 1
      fi
      sleep 2
    done
    echo "Server failed to become ready within 240s"
    cat /tmp/wheels-cli-test-server.log 2>/dev/null | tail -20
    exit 1
  }

  start_lucli
  echo "Waiting for server..."
  wait_for_server

  # Ensure SQLite JDBC is installed in the runtime's lib/ext/ — the CLI test
  # suite includes specs (e.g. TestRunnerSpec) that bring up ephemeral
  # Lucee servers against SQLite and need the driver in lib/ext/.
  #
  # lib/ext/ only exists after the runtime fully extracts Lucee, which is
  # complete by the time the server is ready above. The JVM holding the port
  # names the exact Lucee Express it runs from (-Dcatalina.home); fall back to
  # the first lib/ext under the candidate homes when lsof/ps can't tell us.
  # If the JAR is missing, install it AND restart so the classloader sees it.
  SERVER_JVM="$(listener_pid "$PORT" || true)"
  LUCEE_LIB=""
  if [ -n "$SERVER_JVM" ]; then
    CATALINA_HOME_DIR="$(ps -ww -p "$SERVER_JVM" -o command= 2>/dev/null | tr ' ' '\n' \
      | sed -n 's/^-Dcatalina\.home=//p' | head -1 || true)"
    if [ -n "$CATALINA_HOME_DIR" ] && [ -d "$CATALINA_HOME_DIR/lib/ext" ]; then
      LUCEE_LIB="$CATALINA_HOME_DIR/lib/ext"
    fi
  fi
  if [ -z "$LUCEE_LIB" ]; then
    for express_home in "${EXPRESS_HOMES[@]}"; do
      [ -d "$express_home" ] || continue
      LUCEE_LIB="$(find "$express_home" -path "*/lib/ext" -type d 2>/dev/null | head -1 || true)"
      [ -n "$LUCEE_LIB" ] && break
    done
  fi
  if [ -n "$LUCEE_LIB" ] && ! ls "$LUCEE_LIB"/sqlite-jdbc*.jar 1>/dev/null 2>&1; then
    echo "Downloading SQLite JDBC driver to $LUCEE_LIB..."
    curl -sL "https://repo1.maven.org/maven2/org/xerial/sqlite-jdbc/3.49.1.0/sqlite-jdbc-3.49.1.0.jar" \
      -o "$LUCEE_LIB/sqlite-jdbc-3.49.1.0.jar"
    echo "Restarting ${CLI_BIN} server to pick up new JAR..."
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
    "$CLI_BIN" server stop 2>/dev/null || true
    # The JVM can outlive both the launcher and `server stop`; while it still
    # answers, wait_for_server below would "succeed" against the old process
    # and the new one would be left running unrecorded after cleanup.
    if [ -n "$SERVER_JVM" ]; then
      kill "$SERVER_JVM" 2>/dev/null || true
    fi
    # Floor the wait at the old fixed delay: without lsof, listener_pid is
    # always empty and the poll below would not wait at all.
    sleep 3
    for _ in $(seq 1 30); do
      [ -z "$(listener_pid "$PORT" || true)" ] && break
      sleep 1
    done
    start_lucli
    echo "Waiting for server after JDBC install..."
    wait_for_server
  fi

  # Record the JVM (not the launcher) so cleanup can stop what actually holds
  # the port. Prefer the live listener — the port was free when we started, so
  # it is ours — over the registry's "<pid>:<port>", which can still name the
  # pre-restart JVM right after a restart.
  SERVER_JVM="$(listener_pid "$PORT" || true)"
  if [ -n "$SERVER_JVM" ]; then
    printf '%s:%s\n' "$SERVER_JVM" "$PORT" > "$PROJECT_ROOT/.wheels-test-server.pid"
  else
    OWN_DIR="$(project_server_dir || true)"
    if [ -n "$OWN_DIR" ] && [ -f "$OWN_DIR/server.pid" ]; then
      cp "$OWN_DIR/server.pid" "$PROJECT_ROOT/.wheels-test-server.pid"
    fi
  fi
fi

# ── Warm up Wheels ──────────────────────────────────
echo "Warming up..."
curl -s -o /dev/null --max-time 120 "http://localhost:${PORT}/?reload=true&password=${PASSWORD}" || true
sleep 2

# ── Fallback-port sentinel (opt-in; CI turns it on) ─
#
# No spec may reach a server it did not start, and no command that changes
# state, runs code or carries the reload password may fall back to a common
# port. The sentinel listens on those ports for the whole run and records
# every contact; the run fails below if there were any.
SENTINEL_PID=""
SENTINEL_LOG=""
if [ "${WHEELS_CLI_FALLBACK_SENTINEL:-0}" = "1" ]; then
  SENTINEL_PORTS=""
  for p in 8080 60000 3000 8500; do
    if [ "$p" = "$PORT" ]; then
      echo "::warning::The test server holds fallback port ${PORT}; the sentinel cannot guard it. Use PORT=8190." >&2
      continue
    fi
    SENTINEL_PORTS="${SENTINEL_PORTS:+${SENTINEL_PORTS},}${p}"
  done
  SENTINEL_LOG="${RESULT_FILE%.json}.sentinel.log"
  SENTINEL_READY="${RESULT_FILE%.json}.sentinel.ready"
  rm -f "$SENTINEL_LOG" "$SENTINEL_READY"
  python3 "$PROJECT_ROOT/tools/ci/fallback_port_sentinel.py" serve \
    --log "$SENTINEL_LOG" --ports "$SENTINEL_PORTS" --ready-file "$SENTINEL_READY" &
  SENTINEL_PID=$!
  for _ in $(seq 1 50); do
    [ -f "$SENTINEL_READY" ] && break
    kill -0 "$SENTINEL_PID" 2>/dev/null || break
    sleep 0.2
  done
  if [ ! -f "$SENTINEL_READY" ]; then
    echo "::error::The fallback-port sentinel did not start (see the message above)." >&2
    exit 1
  fi
fi

# ── Run tests ───────────────────────────────────────
TEST_URL="http://localhost:${PORT}/wheels/cli/tests?format=json"
echo "Running CLI tests: ${TEST_URL}"

HTTP_CODE=$(curl -s -o "$RESULT_FILE" \
  --max-time 600 \
  --write-out "%{http_code}" \
  "$TEST_URL" || echo "000")

# ── Parse and display results ───────────────────────
#
# tools/ci/testbox_results.py walks the WHOLE TestBox tree (nested suiteStats,
# bundle-level globalException) and refuses a result whose counts don't match
# totalFail/totalError (#3694: the old inline walker read one suite level, so
# a nested failure or a bundle that threw could exit 0 even with STRICT=1).
#
# Gating policy: failures in cli.lucli.tests.specs.deploy.* always gate;
# WHEELS_CLI_TEST_STRICT=1 makes every failure gate. Counts that don't
# reconcile, and unrecognised statuses, always fail.
echo "Raw result: ${RESULT_FILE}"
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "417" ]; then
  STRICT_FLAG=""
  if [ "${WHEELS_CLI_TEST_STRICT:-0}" = "1" ]; then
    STRICT_FLAG="--strict"
  fi
  SUITE_RC=0
  python3 "$PROJECT_ROOT/tools/ci/testbox_results.py" "$RESULT_FILE" $STRICT_FLAG || SUITE_RC=$?
  if [ -n "$SENTINEL_PID" ]; then
    kill "$SENTINEL_PID" 2>/dev/null || true
    wait "$SENTINEL_PID" 2>/dev/null || true
    SENTINEL_PID=""
    SENTINEL_RC=0
    # This run = this script (and everything it spawned) plus the test
    # server JVM, which may be re-parented. A contact attributed to any
    # other process is listed as "not this run" and does not fail it.
    RUN_PIDS=(--run-pid "$$")
    SERVER_JVM_PID="$(listener_pid "$PORT" || true)"
    if [ -n "$SERVER_JVM_PID" ]; then
      RUN_PIDS+=(--run-pid "$SERVER_JVM_PID")
    fi
    python3 "$PROJECT_ROOT/tools/ci/fallback_port_sentinel.py" check --log "$SENTINEL_LOG" "${RUN_PIDS[@]}" || SENTINEL_RC=$?
    if [ "$SENTINEL_RC" != "0" ] && [ "$SUITE_RC" = "0" ]; then
      SUITE_RC=$SENTINEL_RC
    fi
  fi
  exit $SUITE_RC
else
  echo "Test runner returned HTTP ${HTTP_CODE}"
  cat "$RESULT_FILE" | head -30
  exit 1
fi
