#!/usr/bin/env bash
# Tests classify-conflicts.sh: all-content -> resolve; any code -> escalate.
set -uo pipefail
SCRIPT="$(dirname "$0")/../.github/scripts/classify-conflicts.sh"

fail=0
check() {
  local expected="$1"; shift
  local got
  got="$(printf '%s\n' "$@" | bash "$SCRIPT")"
  if [ "$got" = "$expected" ]; then echo "ok:   $expected <- $*"
  else echo "FAIL: expected=$expected got=$got for: $*"; fail=1; fi
}

check resolve  "web/sites/guides/src/content/docs/v4-0-0/x.mdx"
check resolve  "CHANGELOG.md"
check resolve  "CHANGELOG"
check resolve  ".ai/wheels/foo.md"
check resolve  "docs/superpowers/specs/x.md"
check resolve  "vendor/wheels/migrator/CLAUDE.md"
check escalate "vendor/wheels/model/Finders.cfc"
check escalate "web/sites/blog/src/lib/feed.ts"
check escalate "web/sites/blog/src/content/config.ts"
check escalate "package-lock.json"
check escalate "config/routes.cfm"
check escalate "CHANGELOG.md" "vendor/wheels/model/Finders.cfc"

# Single path without trailing newline must still resolve (read-loop edge case)
got="$(printf '%s' 'CHANGELOG.md' | bash "$SCRIPT")"
if [ "$got" = "resolve" ]; then echo "ok:   resolve <- CHANGELOG.md (no trailing newline)"
else echo "FAIL: no-trailing-newline gave $got"; fail=1; fi

# Empty input must be safe (escalate), never resolve.
got="$(printf '' | bash "$SCRIPT")"
if [ "$got" = "escalate" ]; then echo "ok:   escalate <- (empty)"
else echo "FAIL: empty input gave $got"; fail=1; fi

exit $fail
