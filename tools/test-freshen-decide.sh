#!/usr/bin/env bash
# Tests freshen-decide.sh: BEHIND -> update; DIRTY -> dispatch-resolver; else skip.
set -uo pipefail
SCRIPT="$(dirname "$0")/../.github/scripts/freshen-decide.sh"

fail=0
check() {
  local expected="$1" status="$2"
  local got; got="$(bash "$SCRIPT" "$status")"
  if [ "$got" = "$expected" ]; then echo "ok:   $status -> $expected"
  else echo "FAIL: $status -> $got (expected $expected)"; fail=1; fi
}

check update            BEHIND
check dispatch-resolver DIRTY
check skip              CLEAN
check skip              UNSTABLE
check skip              BLOCKED
check skip              UNKNOWN
check skip              ""

exit $fail
