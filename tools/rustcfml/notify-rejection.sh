#!/usr/bin/env bash
# Notify once per rejected RustCFML candidate + failure fingerprint (#3687).
#
# check-version.sh rejects a candidate whose suite has new failures and exits 0,
# so a daily re-check of the same candidate no longer turns the workflow red.
# This script keeps the rejection visible without repeating it:
#
#   - no open issue for the candidate  -> open one with the named diff
#   - open issue, fingerprint already recorded (body or a comment) -> nothing
#   - open issue, fingerprint new (the failure set changed) -> add one comment
#
# The fingerprint (from run-suite.sh's verdict JSON) covers the candidate
# version plus its new-failure keys, and is recorded as a hidden HTML marker.
#
# Usage: notify-rejection.sh <verdict.json>
# Env:   GH_TOKEN (issues: write), GITHUB_REPOSITORY, RUN_URL (optional),
#        NOTIFY_DRY_RUN=1 to print the decision without calling `gh issue
#        create/comment` (lookups still run).
set -euo pipefail

VERDICT="${1:?usage: notify-rejection.sh <verdict.json>}"
REPO="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY must be set}"

read -r VERSION FINGERPRINT < <(python3 -c '
import json, sys
d = json.load(open(sys.argv[1]))
print(d["engineVersion"], d["fingerprint"])
' "$VERDICT")
if ! [[ "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "::error::Refusing to notify for unexpected version '$VERSION'."
  exit 1
fi

TITLE="RustCFML ${VERSION} rejected by the Wheels core suite"
MARKER="<!-- rustcfml-candidate: ${VERSION} fingerprint: ${FINGERPRINT} -->"
BODY_FILE="$(mktemp)"
trap 'rm -f "$BODY_FILE"' EXIT

python3 - "$VERDICT" "$MARKER" "${RUN_URL:-}" > "$BODY_FILE" <<'PY'
import json, sys
d, marker, run_url = json.load(open(sys.argv[1])), sys.argv[2], sys.argv[3]
t, b = d["totals"], d.get("baselineTotals", {})
print(f"The daily RustCFML version check ran the Wheels core suite on **{d['engineVersion']}** "
      f"and **rejected** it: it has failures the pinned baseline (**{d['baselineVersion']}**) does not. "
      "The pin is unchanged and no bump PR was opened.\n")
print(f"| | pass | fail | error |\n|---|---:|---:|---:|\n"
      f"| candidate {d['engineVersion']} | {t.get('totalPass')} | {t.get('totalFail')} | {t.get('totalError')} |\n"
      f"| baseline {d['baselineVersion']} | {b.get('totalPass', '?')} | {b.get('totalFail', '?')} | {b.get('totalError', '?')} |\n")
if d.get("new"):
    print(f"**New failures ({len(d['new'])}):**\n")
    for n in d["new"]:
        msg = (n.get("message") or "").strip()[:300]
        print(f"- `{n['key']}` — [{n.get('status')}] {msg}")
    print()
if d.get("totalsWorse"):
    print("**Totals above baseline:** " + "; ".join(d["totalsWorse"]) + "\n")
if d.get("walkMismatch"):
    print("**Walk/totals mismatch (named list may be incomplete):** " + "; ".join(d["walkMismatch"]) + "\n")
print("Each failure is either an engine regression to report upstream or a Wheels assumption to fix; "
      "classify before bumping. Re-runs of this candidate with the same failures stay silent.\n")
if run_url:
    print(f"Run: {run_url}\n")
print(marker)
PY

EXISTING="$(gh issue list --repo "$REPO" --state open --search "\"${TITLE}\" in:title" \
  --json number,title --jq ".[] | select(.title == \"${TITLE}\") | .number" | head -1)"

if [ -z "$EXISTING" ]; then
  echo "No open issue for ${VERSION}: opening one."
  if [ "${NOTIFY_DRY_RUN:-}" = "1" ]; then
    echo "[dry-run] gh issue create --title \"${TITLE}\" (body below)"; cat "$BODY_FILE"
  else
    gh issue create --repo "$REPO" --title "$TITLE" --body-file "$BODY_FILE"
  fi
  exit 0
fi

SEEN="$(gh issue view "$EXISTING" --repo "$REPO" --json body,comments \
  --jq "[.body, (.comments[].body)] | map(select(contains(\"fingerprint: ${FINGERPRINT}\"))) | length")"
if [ "${SEEN:-0}" -gt 0 ]; then
  echo "Issue #${EXISTING} already records ${VERSION} with fingerprint ${FINGERPRINT}: not notifying again."
  exit 0
fi

echo "Issue #${EXISTING} exists but the failure set changed (fingerprint ${FINGERPRINT}): commenting."
if [ "${NOTIFY_DRY_RUN:-}" = "1" ]; then
  echo "[dry-run] gh issue comment ${EXISTING} (body below)"; cat "$BODY_FILE"
else
  gh issue comment "$EXISTING" --repo "$REPO" --body-file "$BODY_FILE"
fi
