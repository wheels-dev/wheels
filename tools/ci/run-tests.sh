#!/usr/bin/env bash
# Fast CI test runner: Lucee 7 + SQLite via LuCLI
# Used by pr.yml and snapshot.yml
set -euo pipefail

PORT="${PORT:-60007}"
MAX_WAIT="${MAX_WAIT:-60}"
BASE_URL="http://localhost:${PORT}"
TEST_URL="${BASE_URL}/wheels/core/tests?db=sqlite&format=json"
RESULT_FILE="${RESULT_DIR:-/tmp}/test-results.json"
JUNIT_FILE="${JUNIT_DIR:-/tmp}/junit-results.xml"

# --- Wait for server to be ready ---
echo "Waiting for Lucee on port ${PORT}..."
WAIT_COUNT=0
while [ "$WAIT_COUNT" -lt "$MAX_WAIT" ]; do
  WAIT_COUNT=$((WAIT_COUNT + 1))
  HTTP_CODE=$(curl -s -o /dev/null --connect-timeout 2 --max-time 5 -w "%{http_code}" "${BASE_URL}/" 2>/dev/null || echo "000")
  if echo "$HTTP_CODE" | grep -qE "^(200|302|404|500)$"; then
    echo "Lucee is responding (HTTP ${HTTP_CODE})"
    break
  fi
  if [ "$WAIT_COUNT" -lt "$MAX_WAIT" ]; then
    sleep 3
  fi
done

if [ "$WAIT_COUNT" -ge "$MAX_WAIT" ]; then
  echo "::error::Lucee not ready after ${MAX_WAIT} attempts"
  exit 1
fi

# --- Configure SQLite datasources ---
echo "Configuring SQLite datasources..."
# Copy setup script into webroot temporarily
cp tools/ci/setup-datasources.cfm public/_ci_setup_ds.cfm
DS_RESULT=$(curl -s --max-time 30 "${BASE_URL}/_ci_setup_ds.cfm" 2>/dev/null || echo "")
rm -f public/_ci_setup_ds.cfm
if echo "$DS_RESULT" | grep -q '"success":true'; then
  echo "Datasources configured successfully"
else
  echo "::warning::Datasource setup may have failed: ${DS_RESULT}"
fi

# --- Warm up Wheels application ---
echo "Warming up Wheels application..."
curl -s -o /dev/null --max-time 120 "${BASE_URL}/?reload=true&password=wheels_test_password" || true
sleep 2

# --- Run tests ---
echo "Running tests: Lucee 7 + SQLite"
HTTP_CODE=$(curl -s -o "$RESULT_FILE" \
  --max-time 600 \
  --write-out "%{http_code}" \
  "$TEST_URL" || echo "000")

echo "Test HTTP status: ${HTTP_CODE}"

# --- Parse results ---
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "417" ]; then
  PASS=$(python3 -c "import json; d=json.load(open('$RESULT_FILE')); print(int(d.get('totalPass',0)))" 2>/dev/null || echo "?")
  FAIL=$(python3 -c "import json; d=json.load(open('$RESULT_FILE')); print(int(d.get('totalFail',0)))" 2>/dev/null || echo "?")
  ERROR=$(python3 -c "import json; d=json.load(open('$RESULT_FILE')); print(int(d.get('totalError',0)))" 2>/dev/null || echo "?")

  echo "Results: ${PASS} passed, ${FAIL} failed, ${ERROR} errors"

  # Generate JUnit XML for GitHub annotations
  python3 -c "
import json, sys
from xml.etree.ElementTree import Element, SubElement, tostring

def safe_str(v):
    return str(v) if v else ''

d = json.load(open('$RESULT_FILE'))
root = Element('testsuites')
root.set('tests', str(int(d.get('totalPass',0)) + int(d.get('totalFail',0)) + int(d.get('totalError',0))))
root.set('failures', str(int(d.get('totalFail',0))))
root.set('errors', str(int(d.get('totalError',0))))

for b in d.get('bundleStats', []):
    for s in b.get('suiteStats', []):
        ts = SubElement(root, 'testsuite')
        ts.set('name', safe_str(s.get('name')))
        ts.set('tests', str(int(s.get('totalSpecs',0))))
        ts.set('failures', str(int(s.get('totalFail',0))))
        ts.set('errors', str(int(s.get('totalError',0))))
        ts.set('time', str(float(s.get('totalDuration',0))/1000))
        for sp in s.get('specStats', []):
            tc = SubElement(ts, 'testcase')
            tc.set('name', safe_str(sp.get('name')))
            tc.set('classname', safe_str(b.get('name','')))
            tc.set('time', str(float(sp.get('totalDuration',0))/1000))
            if sp.get('status') == 'Failed':
                f = SubElement(tc, 'failure', message=safe_str(sp.get('failMessage')))
                f.text = safe_str(sp.get('failDetail'))
            elif sp.get('status') == 'Error':
                e = SubElement(tc, 'error', message=safe_str(sp.get('failMessage')))
                e.text = safe_str(sp.get('failDetail'))

with open('$JUNIT_FILE', 'wb') as f:
    f.write(b'<?xml version=\"1.0\" encoding=\"UTF-8\"?>')
    f.write(tostring(root))
" 2>/dev/null || echo "Warning: Could not generate JUnit XML"

  # Write step summary
  if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    echo "### Lucee 7 + SQLite Test Results" >> "$GITHUB_STEP_SUMMARY"
    echo "" >> "$GITHUB_STEP_SUMMARY"
    echo "| Metric | Count |" >> "$GITHUB_STEP_SUMMARY"
    echo "|--------|-------|" >> "$GITHUB_STEP_SUMMARY"
    echo "| Passed | ${PASS} |" >> "$GITHUB_STEP_SUMMARY"
    echo "| Failed | ${FAIL} |" >> "$GITHUB_STEP_SUMMARY"
    echo "| Errors | ${ERROR} |" >> "$GITHUB_STEP_SUMMARY"
  fi

  TOTAL_FAILURES=$((FAIL + ERROR))
  if [ "$TOTAL_FAILURES" -gt 0 ]; then
    echo "::error::${TOTAL_FAILURES} test failures/errors"
    # Print failure details
    python3 -c "
import json
d = json.load(open('$RESULT_FILE'))
for b in d.get('bundleStats', []):
    for s in b.get('suiteStats', []):
        for sp in s.get('specStats', []):
            if sp.get('status') in ('Failed', 'Error'):
                print(f\"  {sp['status']}: {sp.get('name','?')}: {sp.get('failMessage','')[:200]}\")
" 2>/dev/null || true
    exit 1
  fi

  echo "All tests passed!"
else
  echo "::error::Tests returned HTTP ${HTTP_CODE}"
  # Show first 50 lines of response for debugging
  head -50 "$RESULT_FILE" 2>/dev/null || true
  exit 1
fi
