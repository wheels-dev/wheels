#!/usr/bin/env bash
# Release-readiness gate: fails unless every open issue and every open PR in the
# repository is resolved or explicitly labelled `deferred`.
#
# Policy (maintainer): address all issues and PRs before a release, so each
# release is better than the last. See .github/RELEASE_PLAYBOOK.md
# ("Release readiness (required)").
#
# Inputs (environment):
#   GH_REPO          owner/repo to inspect (required unless READINESS_INPUT is set)
#   EXCLUDE_NUMBER   issue/PR number to ignore (the release PR itself); optional
#   DEFERRED_LABEL   label that marks an item as explicitly deferred (default: deferred)
#   READINESS_INPUT  path to a saved JSON array of GitHub issue objects (the shape of
#                    GET /repos/{owner}/{repo}/issues) to use instead of calling the
#                    API. For local dry-runs and tools/test-release-readiness.sh.
#   GITHUB_STEP_SUMMARY  markdown summary target (defaults to stdout outside Actions)
#
# Counted: every open issue and every open PR, including drafts and bot PRs
# (dependabot/renovate), and including the `compat-matrix-failure` tracking issue —
# an open matrix failure must block a release.
#
# Exit status: 0 when nothing blocks, 1 when anything blocks, 2 on usage/API errors.
set -euo pipefail

DEFERRED_LABEL="${DEFERRED_LABEL:-deferred}"
EXCLUDE_NUMBER="${EXCLUDE_NUMBER:-}"
SUMMARY="${GITHUB_STEP_SUMMARY:-/dev/stdout}"

if [ -n "$EXCLUDE_NUMBER" ] && ! [[ "$EXCLUDE_NUMBER" =~ ^[0-9]+$ ]]; then
  echo "::error::EXCLUDE_NUMBER must be a number, got '${EXCLUDE_NUMBER}'" >&2
  exit 2
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

if [ -n "${READINESS_INPUT:-}" ]; then
  jq -c '.[]' "$READINESS_INPUT" > "$TMP/items.ndjson"
else
  : "${GH_REPO:?GH_REPO (owner/repo) is required}"
  # The issues endpoint returns issues AND pull requests (PRs carry a
  # `pull_request` key). --paginate walks every page; emit one object per line
  # so the concatenated pages form a single stream.
  gh api --paginate "repos/${GH_REPO}/issues?state=open&per_page=100" \
    --jq '.[]' > "$TMP/items.ndjson"
fi

# Normalize to: {number, kind, title, url, labels, author, deferred}
jq -s -c \
  --arg deferred "$DEFERRED_LABEL" \
  --arg exclude "$EXCLUDE_NUMBER" '
  map(select(($exclude == "") or (.number != ($exclude | tonumber))))
  | map({
      number,
      kind: (if has("pull_request") and .pull_request != null
             then (if .draft == true then "Draft PR" else "PR" end)
             else "Issue" end),
      title: (.title // ""),
      url: .html_url,
      labels: [(.labels // [])[] | (if type == "object" then .name else . end)],
      author: (.user.login // "")
    })
  | map(. + {deferred: (.labels | index($deferred) != null)})
  | sort_by(.number)
' "$TMP/items.ndjson" > "$TMP/items.json"

BLOCKING=$(jq '[.[] | select(.deferred | not)] | length' "$TMP/items.json")
DEFERRED=$(jq '[.[] | select(.deferred)] | length' "$TMP/items.json")

# Markdown table rows. Pipes and newlines in titles would break the table.
rows() {
  jq -r --argjson want "$1" '
    .[] | select(.deferred == $want)
    | "| [#\(.number)](\(.url)) | \(.kind) | \(.title | gsub("\\|"; "\\|") | gsub("[\r\n]+"; " ")) | \(if (.labels | length) == 0 then "—" else (.labels | map("`\(.)`") | join(" ")) end) | \(.author) |"
  ' "$TMP/items.json"
}

{
  echo "## Release readiness"
  echo ""
  if [ -n "$EXCLUDE_NUMBER" ]; then
    echo "Excluding #${EXCLUDE_NUMBER} (the release PR). Items labelled \`${DEFERRED_LABEL}\` do not block."
  else
    echo "Items labelled \`${DEFERRED_LABEL}\` do not block."
  fi
  echo ""
  if [ "$BLOCKING" -eq 0 ]; then
    echo "### :white_check_mark: Ready — no blocking issues or PRs"
  else
    echo "### :x: Not ready — ${BLOCKING} blocking item(s)"
    echo ""
    echo "Resolve each one (close, merge, or fix), or label it \`${DEFERRED_LABEL}\` with a comment"
    echo "explaining why it can wait, then re-run this check."
    echo ""
    echo "| # | Type | Title | Labels | Author |"
    echo "|---|------|-------|--------|--------|"
    rows false
  fi
  echo ""
  echo "### Deferred (${DEFERRED})"
  echo ""
  if [ "$DEFERRED" -eq 0 ]; then
    echo "_None._"
  else
    echo "Not blocking, listed so they stay visible. Each should carry a comment with the reason."
    echo ""
    echo "| # | Type | Title | Labels | Author |"
    echo "|---|------|-------|--------|--------|"
    rows true
  fi
} >> "$SUMMARY"

echo "Release readiness: ${BLOCKING} blocking, ${DEFERRED} deferred."
if [ "$BLOCKING" -gt 0 ]; then
  echo "::error::Release not ready: ${BLOCKING} open issue(s)/PR(s) are neither resolved nor labelled '${DEFERRED_LABEL}'. See the job summary."
  exit 1
fi
