#!/usr/bin/env bash
# Tests .github/scripts/release-readiness.sh against inline fixtures (no API calls).
set -uo pipefail
SCRIPT="$(dirname "$0")/../.github/scripts/release-readiness.sh"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/items.json" <<'JSON'
[
  {"number": 10, "title": "open bug | with pipe", "html_url": "https://x/issues/10",
   "labels": [{"name": "bug"}], "user": {"login": "a"}},
  {"number": 11, "title": "deferred issue", "html_url": "https://x/issues/11",
   "labels": [{"name": "deferred"}], "user": {"login": "a"}},
  {"number": 12, "title": "bot draft", "html_url": "https://x/pull/12", "labels": [],
   "user": {"login": "dependabot[bot]"}, "draft": true, "pull_request": {"url": "u"}},
  {"number": 13, "title": "Release 9.9.9", "html_url": "https://x/pull/13", "labels": [],
   "user": {"login": "m"}, "draft": false, "pull_request": {"url": "u"}},
  {"number": 14, "title": "Compatibility matrix failing on develop", "html_url": "https://x/issues/14",
   "labels": [{"name": "compat-matrix-failure"}], "user": {"login": "github-actions[bot]"}}
]
JSON
echo '[]' > "$TMP/empty.json"
jq '[.[] | select(.number == 11 or .number == 13)]' "$TMP/items.json" > "$TMP/clean.json"

fail=0
check() {
  local name="$1" expected_rc="$2" pattern="$3"; shift 3
  local out rc
  out="$(env GITHUB_STEP_SUMMARY=/dev/stdout "$@" bash "$SCRIPT" 2>&1)"; rc=$?
  if [ "$rc" = "$expected_rc" ] && grep -qF -- "$pattern" <<<"$out"; then echo "ok:   $name"
  else echo "FAIL: $name (rc=$rc, expected $expected_rc, wanted '$pattern')"; echo "$out"; fail=1; fi
}

check "blocks on open items"          1 "4 blocking, 1 deferred" READINESS_INPUT="$TMP/items.json"
check "excludes the release PR"       1 "3 blocking, 1 deferred" READINESS_INPUT="$TMP/items.json" EXCLUDE_NUMBER=13
check "matrix-failure issue blocks"   1 "[#14]"                  READINESS_INPUT="$TMP/items.json" EXCLUDE_NUMBER=13
check "draft bot PR blocks"           1 "| Draft PR |"           READINESS_INPUT="$TMP/items.json" EXCLUDE_NUMBER=13
check "escapes pipes in titles"       1 'open bug \| with pipe'  READINESS_INPUT="$TMP/items.json" EXCLUDE_NUMBER=13
check "deferred-only is ready"        0 "0 blocking, 1 deferred" READINESS_INPUT="$TMP/clean.json" EXCLUDE_NUMBER=13
check "deferred still listed"         0 "[#11]"                  READINESS_INPUT="$TMP/clean.json" EXCLUDE_NUMBER=13
check "empty repo is ready"           0 "0 blocking, 0 deferred" READINESS_INPUT="$TMP/empty.json"
check "rejects non-numeric exclude"   2 "must be a number"       READINESS_INPUT="$TMP/empty.json" EXCLUDE_NUMBER=abc

exit $fail
