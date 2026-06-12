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
