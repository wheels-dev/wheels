#!/usr/bin/env bash
# Environment-mode smoke probes (issue #3023 regression net).
# Boots nothing itself: point it at an already-running app via BASE_URL.
# SMOKE_ENV is a log label only; all probes assume a non-development environment.
#
#   BASE_URL=http://localhost:60007 SMOKE_ENV=production bash tools/ci/smoke-env.sh
#
# Exit 0 = all probes pass. Non-zero = at least one probe failed; every
# failure prints PROBE/EXPECTED/GOT lines for the CI log.
set -u
BASE_URL="${BASE_URL:-http://localhost:60007}"
SMOKE_ENV="${SMOKE_ENV:-production}"
FAILURES=0

# Markers that must NEVER appear in any non-development response body:
# engine stack traces, raw CFML errors, debug output, the generic error
# template leaking on routes that should be plain 404s.
TRACE_MARKERS='coldfusion\.runtime|lucee\.runtime|Variable [A-Z][A-Z0-9_]* is undefined|Error Occurred While Processing Request|<!-- wheels-debug|id="wheels-debugbar"'

# Fail fast and unambiguously when the app is unreachable — without this,
# curl status 000 satisfies the NOT-302 and non-5xx assertions vacuously.
if ! curl -sS -o /dev/null --connect-timeout 5 --max-time 15 "$BASE_URL/"; then
  echo "FAIL probe=connectivity url=$BASE_URL/ (server unreachable; skipping probes)"
  exit 1
fi

probe() { # name url expected_status body_must_match body_must_not_match
  local name="$1" url="$2" expect="$3" must="$4" mustnot="$5"
  local body status
  body=$(mktemp)
  status=$(curl -sS -o "$body" -w '%{http_code}' --connect-timeout 5 --max-time 60 "$url")
  local ok=1
  [ "$status" = "$expect" ] || ok=0
  if [ -n "$must" ] && ! grep -qE "$must" "$body"; then ok=0; fi
  if [ -n "$mustnot" ] && grep -qE "$mustnot" "$body"; then ok=0; fi
  if [ "$ok" = "0" ]; then
    echo "FAIL probe=$name url=$url"
    echo "  expected: status=$expect must=~'$must' mustnot=~'$mustnot'"
    echo "  got:      status=$status body_head=$(head -c 200 "$body" | tr '\n' ' ')"
    FAILURES=$((FAILURES+1))
  else
    echo "PASS probe=$name ($status)"
  fi
  rm -f "$body"
}

# 1. Root route renders without server error and without debug/trace leakage.
#    (Any 2xx/3xx/404 is acceptable app behavior; 5xx is not.)
root_body=$(mktemp)
status=$(curl -sS -o "$root_body" -w '%{http_code}' --connect-timeout 5 --max-time 60 "$BASE_URL/")
case "$status" in
  5*) echo "FAIL probe=root-no-5xx url=$BASE_URL/ got status=$status"; FAILURES=$((FAILURES+1));;
  000) echo "FAIL probe=root-no-5xx url=$BASE_URL/ (status=000, request failed)"; FAILURES=$((FAILURES+1));;
  *)  if grep -qE "$TRACE_MARKERS" "$root_body"; then
        echo "FAIL probe=root-no-trace-markers url=$BASE_URL/ (status=$status)"; FAILURES=$((FAILURES+1))
      else
        echo "PASS probe=root ($status, clean)"
      fi;;
esac
rm -f "$root_body"

# 2. Public component is OFF outside development and aborts CLEANLY (issue #3029):
#    plain 404 + "Not Found", no error template, no stack trace, on every engine.
probe "wheels-info-clean-404" "$BASE_URL/wheels/info" "404" "Not Found" "$TRACE_MARKERS|Something went wrong"

# 3. Unknown route returns the application 404 path, not a 500/stack trace.
probe "unknown-route-404" "$BASE_URL/smoke-nonexistent-route-$$" "404" "" "$TRACE_MARKERS"

# 4. Reload without a password must be refused: the reload path responds 302
#    (applicationStop + redirect); a refusal renders normally. Assert NOT 302.
status=$(curl -sS -o /dev/null -w '%{http_code}' --connect-timeout 5 --max-time 60 "$BASE_URL/?reload=true")
case "$status" in
  302) echo "FAIL probe=reload-unauthenticated-refused url=$BASE_URL/?reload=true (got 302 = reload executed without password)"; FAILURES=$((FAILURES+1));;
  000) echo "FAIL probe=reload-unauthenticated-refused (status=000, request failed)"; FAILURES=$((FAILURES+1));;
  *)   echo "PASS probe=reload-unauthenticated-refused ($status)";;
esac

# 5. Wrong password must also be refused.
status=$(curl -sS -o /dev/null -w '%{http_code}' --connect-timeout 5 --max-time 60 "$BASE_URL/?reload=true&password=definitely-wrong-$$")
case "$status" in
  302) echo "FAIL probe=reload-wrong-password-refused url=$BASE_URL/?reload=true&password=... (got 302)"; FAILURES=$((FAILURES+1));;
  000) echo "FAIL probe=reload-wrong-password-refused (status=000, request failed)"; FAILURES=$((FAILURES+1));;
  *)   echo "PASS probe=reload-wrong-password-refused ($status)";;
esac

# 6. Authorized reload restarts cleanly (issue #3053): with the correct
#    password the reload gate must run applicationStop() and answer with the
#    302 restart redirect — not a 5xx (reserved-scope shadowing in
#    $buildRedirectUrl broke this on every Adobe CF engine) and not a 200
#    (gate silently skipped). Opt-in via SMOKE_RELOAD_PASSWORD because the
#    probe genuinely restarts the application — keep it LAST so the restart
#    cannot perturb the other probes.
if [ -n "${SMOKE_RELOAD_PASSWORD:-}" ]; then
  status=$(curl -sS -o /dev/null -w '%{http_code}' --connect-timeout 5 --max-time 60 "$BASE_URL/?reload=true&password=$SMOKE_RELOAD_PASSWORD")
  case "$status" in
    302) echo "PASS probe=reload-authorized-restarts (302)";;
    000) echo "FAIL probe=reload-authorized-restarts (status=000, request failed)"; FAILURES=$((FAILURES+1));;
    *)   echo "FAIL probe=reload-authorized-restarts url=$BASE_URL/?reload=true&password=*** (expected 302, got $status)"; FAILURES=$((FAILURES+1));;
  esac
else
  echo "SKIP probe=reload-authorized-restarts (SMOKE_RELOAD_PASSWORD unset)"
fi

echo "smoke-env: env=$SMOKE_ENV failures=$FAILURES"
exit $FAILURES
