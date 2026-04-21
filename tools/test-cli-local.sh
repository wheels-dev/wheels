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
PASSWORD="wheels"
RESULT_FILE="/tmp/wheels-cli-test-results.json"

cd "$PROJECT_ROOT"

# Ensure JAVA_HOME is set (lucli server run needs it explicitly on some macOS setups).
if [ -z "${JAVA_HOME:-}" ]; then
  if command -v /usr/libexec/java_home >/dev/null 2>&1; then
    export JAVA_HOME="$(/usr/libexec/java_home -v 21 2>/dev/null || /usr/libexec/java_home 2>/dev/null || true)"
  fi
fi

# ── Lifecycle ───────────────────────────────────────
cleanup() {
  if [ "${STARTED_SERVER:-false}" = "true" ]; then
    echo "Stopping test server..."
    kill "$SERVER_PID" 2>/dev/null || true
    lucli server stop 2>/dev/null || true
  fi
}
trap cleanup EXIT

# ── Start server if not already running ─────────────
STARTED_SERVER=false
if curl -s -o /dev/null --connect-timeout 2 --max-time 3 "http://localhost:${PORT}/" 2>/dev/null; then
  echo "Using existing server on port ${PORT}"
else
  echo "Starting LuCLI server on port ${PORT}..."

  # Ensure SQLite JDBC is installed in LuCLI's lib/ext/ — the CLI test
  # suite includes specs (e.g. TestRunnerSpec) that bring up ephemeral
  # Lucee servers against SQLite and need the driver in lib/ext/.
  #
  # The express dir only materializes after LuCLI has run at least once.
  # On a fresh CI runner it doesn't exist yet, so pre-warm by spinning
  # LuCLI up briefly to trigger the Lucee extraction, then tear down.
  if [ ! -d "$HOME/.lucli/express" ]; then
    echo "Pre-warming LuCLI to trigger express directory extraction..."
    nohup lucli server run --port="$PORT" --force > /tmp/wheels-cli-warmup.log 2>&1 &
    WARMUP_PID=$!
    for _ in $(seq 1 60); do
      [ -d "$HOME/.lucli/express" ] && break
      sleep 1
    done
    kill "$WARMUP_PID" 2>/dev/null || true
    wait "$WARMUP_PID" 2>/dev/null || true
    lucli server stop 2>/dev/null || true
    sleep 2  # give the port a moment to release
  fi

  # Belt-and-braces: guard the find so a missing express dir doesn't kill
  # the script under `pipefail`. Empty LUCEE_LIB just skips the install.
  LUCEE_LIB=""
  if [ -d "$HOME/.lucli/express" ]; then
    LUCEE_LIB="$(find "$HOME/.lucli/express" -path "*/lib/ext" -type d 2>/dev/null | head -1 || true)"
  fi
  if [ -n "$LUCEE_LIB" ] && ! ls "$LUCEE_LIB"/sqlite-jdbc*.jar 1>/dev/null 2>&1; then
    echo "Downloading SQLite JDBC driver to $LUCEE_LIB..."
    curl -sL "https://repo1.maven.org/maven2/org/xerial/sqlite-jdbc/3.49.1.0/sqlite-jdbc-3.49.1.0.jar" \
      -o "$LUCEE_LIB/sqlite-jdbc-3.49.1.0.jar"
  fi

  nohup lucli server run --port="$PORT" --force > /tmp/wheels-cli-test-server.log 2>&1 &
  SERVER_PID=$!
  STARTED_SERVER=true

  echo "Waiting for server..."
  for i in $(seq 1 60); do
    if curl -s -o /dev/null --connect-timeout 2 --max-time 3 "http://localhost:${PORT}/" 2>/dev/null; then
      echo "Server ready (attempt $i)"
      break
    fi
    if ! kill -0 "$SERVER_PID" 2>/dev/null; then
      echo "Server process died. Check /tmp/wheels-cli-test-server.log"
      cat /tmp/wheels-cli-test-server.log 2>/dev/null | tail -20
      exit 1
    fi
    sleep 2
  done
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
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "417" ]; then
  python3 -c "
import json, sys
try:
    d = json.load(open('$RESULT_FILE'))
except Exception as e:
    print(f'Failed to parse results: {e}')
    sys.exit(2)
# TestBox's totalError is unreliable in this repo (sometimes negative when
# skipped/pending specs exist). Trust totalFail + explicit Error statuses.
passes = d.get('totalPass', 0)
fails = d.get('totalFail', 0)
err = max(0, d.get('totalError', 0))
print(f\"{passes} pass, {fails} fail, {err} error\")
real_errors = 0
for b in d.get('bundleStats', []):
    for s in b.get('suiteStats', []):
        for sp in s.get('specStats', []):
            if sp.get('status') in ('Failed', 'Error'):
                real_errors += 1
                msg = (sp.get('failMessage') or '')[:180]
                print(f\"  {sp['status']}: {sp['name']}: {msg}\")
sys.exit(0 if (fails + real_errors) == 0 else 1)
"
else
  echo "Test runner returned HTTP ${HTTP_CODE}"
  cat "$RESULT_FILE" | head -30
  exit 1
fi
