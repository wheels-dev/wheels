#!/usr/bin/env bash
# Wait until the CFML engine itself can use a test datasource (#3738).
#
# A database-side probe only proves the database answers its own client. The
# engine connects over JDBC with its own driver and connect descriptor, and on
# Oracle it has hit ORA-12514 after the database-side probe passed. This
# script asks the engine: it runs one small spec directory through the core
# test runner with ?db=<db>. The runner reads schema metadata and populates
# the test tables through the engine's datasource before any spec runs, so a
# JSON result with specs in it means the engine can connect and execute SQL.
#
# The main suite run then starts against a connection that has just worked.
# Spec failures in the probe don't matter here (HTTP 417 still proves the
# connection); the full run reports them.
#
# Usage: tools/ci/wait-engine-db.sh <port> <db> [max_attempts] [interval_seconds]
set -uo pipefail

PORT="${1:?port required}"
DB="${2:?db required}"
MAX="${3:-30}"
INTERVAL="${4:-10}"
PROBE_DIR="wheels.tests.specs.internal.model"
URL="http://localhost:${PORT}/wheels/core/tests?db=${DB}&directory=${PROBE_DIR}&format=json"
BODY="$(mktemp)"
trap 'rm -f "$BODY"' EXIT

echo "Checking that the engine on port ${PORT} can use the ${DB} datasource..."
for ((i = 1; i <= MAX; i++)); do
  CODE=$(curl -s -o "$BODY" --max-time 300 -w "%{http_code}" "$URL" 2>/dev/null || true)
  CODE="${CODE:-000}"
  if [ "$CODE" = "200" ] || [ "$CODE" = "417" ]; then
    SPECS=$(python3 -c "
import json, sys
try:
    print(int(json.load(open(sys.argv[1])).get('totalSpecs', 0)))
except Exception:
    print(-1)
" "$BODY")
    if [ "$SPECS" -gt 0 ]; then
      echo "Engine reached ${DB} (HTTP ${CODE}, ${SPECS} probe specs, attempt ${i}/${MAX})"
      exit 0
    fi
  fi
  # Keep the diagnostic short: the runner's error envelope carries the
  # driver message (e.g. ORA-12514) in its first few hundred bytes.
  SNIPPET=$(head -c 400 "$BODY" 2>/dev/null | tr -d '\r' | tr '\n' ' ')
  echo "  attempt ${i}/${MAX}: HTTP ${CODE} ${SNIPPET}"
  if [ "$i" -lt "$MAX" ]; then
    sleep "$INTERVAL"
  fi
done

echo "::error::The engine on port ${PORT} could not use the ${DB} datasource after ${MAX} attempts"
echo "=== Last response body (first 2000 bytes) ==="
head -c 2000 "$BODY" 2>/dev/null || true
echo
echo "=== /end response body ==="
exit 1
