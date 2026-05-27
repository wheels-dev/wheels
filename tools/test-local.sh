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
#   bash tools/test-local.sh              # run all core tests
#   bash tools/test-local.sh model        # run model tests only
#   bash tools/test-local.sh security     # run security tests only
#   PORT=9090 bash tools/test-local.sh    # use custom port
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
PASSWORD="wheels"
RESULT_FILE="/tmp/wheels-local-test-results.json"

# Browser specs call back into the local Wheels CLI server — point Playwright
# at the right port. CI sets this explicitly before invoking the script;
# the ${VAR:-default} preserves the CI override.
export WHEELS_BROWSER_TEST_BASE_URL="${WHEELS_BROWSER_TEST_BASE_URL:-http://localhost:${PORT}}"

cd "$PROJECT_ROOT"

# ── Ensure SQLite test databases exist ──────────────
sqlite3 wheelstestdb.db "SELECT 1;" 2>/dev/null || true
sqlite3 wheelstestdb_tenant_b.db "SELECT 1;" 2>/dev/null || true

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

cleanup() {
  # Restore original lucee.json if we modified it
  if [ "${RESTORED_LUCEE_JSON:-false}" = "true" ] && [ -f lucee.json.bak ]; then
    mv lucee.json.bak lucee.json
  fi
  # Kill server if we started it
  if [ "${STARTED_SERVER:-false}" = "true" ]; then
    echo "Stopping test server..."
    kill "$SERVER_PID" 2>/dev/null || true
    wheels server stop 2>/dev/null || true
  fi
}
trap cleanup EXIT

# ── Start server if not already running ─────────────
STARTED_SERVER=false
if curl -s -o /dev/null --connect-timeout 2 --max-time 3 "http://localhost:${PORT}/" 2>/dev/null; then
  echo "Using existing server on port ${PORT}"
else
  echo "Starting Wheels CLI server on port ${PORT}..."

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
fi

# ── Warm up Wheels ──────────────────────────────────
echo "Warming up..."
curl -s -o /dev/null --max-time 120 "http://localhost:${PORT}/?reload=true&password=${PASSWORD}" || true
sleep 2

# ── Run tests ───────────────────────────────────────
TEST_URL="http://localhost:${PORT}/wheels/core/tests?db=${DB}&format=json"
if [ -n "$FILTER" ]; then
  # Map short names to directories
  case "$FILTER" in
    model|models) FILTER="wheels.tests.specs.model" ;;
    controller|controllers) FILTER="wheels.tests.specs.controller" ;;
    view|views) FILTER="wheels.tests.specs.view" ;;
    security) FILTER="wheels.tests.specs.security" ;;
    middleware) FILTER="wheels.tests.specs.middleware" ;;
    dispatch) FILTER="wheels.tests.specs.dispatch" ;;
    migrator) FILTER="wheels.tests.specs.migrator" ;;
  esac
  TEST_URL="${TEST_URL}&directory=${FILTER}"
fi

echo "Running tests: Lucee 7 + SQLite${FILTER:+ (filter: $FILTER)}"
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
