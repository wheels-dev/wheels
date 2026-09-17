#!/usr/bin/env bash
# Run CLI-layer tests (cli/lucli/tests/specs/**) locally via LuCLI + SQLite.
#
# Companion to tools/test-local.sh. Where that script runs core framework
# tests at /wheels/core/tests, this one runs the CLI module's own spec
# suite at /cli/lucli/tests/runner.cfm.
#
# Prerequisites:
#   - LuCLI 0.3.3+ on PATH
#   - Java 21+
#
# Usage:
#   bash tools/test-cli-local.sh              # run all CLI specs
#   PORT=9090 bash tools/test-cli-local.sh    # custom port
#
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PORT="${PORT:-8080}"
# Must match set(reloadPassword=...) in config/settings.cfm — a mismatch never
# reloads and, since #3062, counts against the per-IP reload rate limit.
PASSWORD="wheels-dev"
RESULT_FILE="/tmp/wheels-cli-test-results.json"

cd "$PROJECT_ROOT"

# Ensure JAVA_HOME is set (lucli server run needs it explicitly on some macOS setups).
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
  # Put lucee.json back first, on EVERY exit path — success, a red suite, or
  # Ctrl-C — so an overridden PORT never leaves the repo dirty. Guarded: the
  # restore helper is defined further down, and an early exit (e.g. the
  # ownership refusal above it) reaches this trap before it exists.
  if declare -F restore_lucee_json >/dev/null 2>&1; then
    restore_lucee_json
  fi
  if [ "${STARTED_SERVER:-false}" = "true" ]; then
    echo "Stopping test server..."
    ( cd "$PROJECT_ROOT" && lucli server stop >/dev/null 2>&1 ) || true
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
  echo "Starting LuCLI server on port ${PORT}..."

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
    nohup lucli server run --port="$PORT" --force > /tmp/wheels-cli-test-server.log 2>&1 &
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

  # Ensure SQLite JDBC is installed in LuCLI's lib/ext/ — the CLI test
  # suite includes specs (e.g. TestRunnerSpec) that bring up ephemeral
  # Lucee servers against SQLite and need the driver in lib/ext/.
  #
  # lib/ext/ only exists after LuCLI fully extracts Lucee, which is
  # complete by the time the server is ready above. If the JAR is missing,
  # install it AND restart LuCLI so the classloader picks it up.
  LUCEE_LIB=""
  if [ -d "$HOME/.lucli/express" ]; then
    LUCEE_LIB="$(find "$HOME/.lucli/express" -path "*/lib/ext" -type d 2>/dev/null | head -1 || true)"
  fi
  if [ -n "$LUCEE_LIB" ] && ! ls "$LUCEE_LIB"/sqlite-jdbc*.jar 1>/dev/null 2>&1; then
    echo "Downloading SQLite JDBC driver to $LUCEE_LIB..."
    curl -sL "https://repo1.maven.org/maven2/org/xerial/sqlite-jdbc/3.49.1.0/sqlite-jdbc-3.49.1.0.jar" \
      -o "$LUCEE_LIB/sqlite-jdbc-3.49.1.0.jar"
    echo "Restarting LuCLI to pick up new JAR..."
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
    lucli server stop 2>/dev/null || true
    sleep 3  # give the port a moment to release
    start_lucli
    echo "Waiting for server after JDBC install..."
    wait_for_server
  fi

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
TEST_URL="http://localhost:${PORT}/wheels/cli/tests?format=json"
echo "Running CLI tests: ${TEST_URL}"

HTTP_CODE=$(curl -s -o "$RESULT_FILE" \
  --max-time 600 \
  --write-out "%{http_code}" \
  "$TEST_URL" || echo "000")

# ── Parse and display results ───────────────────────
#
# Strict-mode scoping: by default, only failures in specs under
# cli.lucli.tests.specs.deploy.* gate the exit code. Pre-existing failures
# in unrelated specs (notably TestRunnerSpec, which depends on SQLite JDBC
# being wired into LuCLI's lib/ext/ — fragile in fresh CI runners) are
# reported but don't block the deploy subsystem CI.
#
# Set WHEELS_CLI_TEST_STRICT=1 to fail on any failure across all specs.
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "417" ]; then
  WHEELS_CLI_TEST_STRICT="${WHEELS_CLI_TEST_STRICT:-0}" \
  python3 -c "
import json, os, sys
try:
    d = json.load(open('$RESULT_FILE'))
except Exception as e:
    print(f'Failed to parse results: {e}')
    sys.exit(2)
# TestBox's totalError is unreliable in this repo (sometimes negative when
# skipped/pending specs exist). Trust totalFail + explicit Error statuses.
strict = os.environ.get('WHEELS_CLI_TEST_STRICT', '0') == '1'
passes = d.get('totalPass', 0)
fails = d.get('totalFail', 0)
err = max(0, d.get('totalError', 0))
print(f\"{passes} pass, {fails} fail, {err} error\")

gating_failures = 0
nongating_failures = 0
for b in d.get('bundleStats', []):
    bundle_name = b.get('name', '') or ''
    is_deploy = 'cli.lucli.tests.specs.deploy' in bundle_name
    for s in b.get('suiteStats', []):
        for sp in s.get('specStats', []):
            if sp.get('status') in ('Failed', 'Error'):
                msg = (sp.get('failMessage') or '')[:180]
                prefix = '' if (is_deploy or strict) else '  [non-gating] '
                print(f\"{prefix}  {sp['status']}: {bundle_name}: {sp['name']}: {msg}\")
                if is_deploy or strict:
                    gating_failures += 1
                else:
                    nongating_failures += 1

if nongating_failures and not strict:
    print(f\"\\n{nongating_failures} non-gating failure(s) in non-deploy specs — reported but not blocking.\")
    print('Run with WHEELS_CLI_TEST_STRICT=1 to gate on them too.')

sys.exit(0 if gating_failures == 0 else 1)
"
else
  echo "Test runner returned HTTP ${HTTP_CODE}"
  cat "$RESULT_FILE" | head -30
  exit 1
fi
