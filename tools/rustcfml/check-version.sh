#!/usr/bin/env bash
# Detect a newer RustCFML release than the pinned tools/rustcfml/ENGINE_VERSION.
#
# The candidate is the newest release, prereleases included (RustCFML marks most
# releases as prereleases; the suite is the quality gate, not the label). Run the full
# core suite against it (compare mode against the current baseline.json). If it is
# rejected or listed in KNOWN_BAD, and GitHub's latest stable release is newer than the
# pin, evaluate that stable the same way. Outcomes per candidate (#3687):
#
#   accepted  no new failures vs the pinned baseline: bump ENGINE_VERSION and
#             the ENGINE_SHA256 pins (bump-pin.sh), regenerate baseline.json,
#             and export RUSTCFML_LATEST/PINNED via GITHUB_ENV so the workflow
#             opens the bump PR.
#   rejected  the suite ran and has new failures: leave the pin unchanged,
#             emit a ::warning:: with the named diff, and export
#             RUSTCFML_REJECTED/RUSTCFML_FINGERPRINT/RUSTCFML_RESULT_JSON so the
#             workflow can notify once per candidate + failure fingerprint.
#             This is the check doing its job, not an operational failure.
#   error     the candidate could not be evaluated (release lookup, download,
#             boot, unparseable response): exit 1 so the run goes red.
#
#   skipped   the candidate is listed in tools/rustcfml/KNOWN_BAD (a release known
#             to break the suite, e.g. hang it): emit a ::notice:: with the listed
#             reason and link and don't run it.
#
# A rejected newest release is still reported (RUSTCFML_REJECTED) when the stable
# fallback is accepted, so the workflow both opens the bump PR and files the issue.
#
# Exits 0 when already at the newest release, on accepted, on rejected and on skipped.
# Exits 1 only when the candidate could not be evaluated.
#
# The required PR check (rustcfml-ci.yml) is unaffected: it calls run-suite.sh
# directly and fails on any non-zero exit.
#
# Requires: gh on PATH, GH_TOKEN set (for release metadata + binary download).
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PINNED="$(tr -d '[:space:]' < "$DIR/ENGINE_VERSION")"

# Which release to evaluate (pin policy, orch1 2026-10-09): RustCFML marks most of its
# releases as prereleases, so the newest release, prereleases included, is the
# candidate. The suite is the quality gate, not the label. If that candidate is
# rejected (or listed in KNOWN_BAD) and GitHub's latest *stable* release is newer than
# the pin and different, the stable is evaluated next and pinned if green.
#
# Keep the tag's `v` prefix: ENGINE_VERSION stores it verbatim (e.g. `v0.637.0`), and
# run-suite.sh passes the value straight to `gh release download`, which needs the
# real tag name. The tags come from another repository and end up in branch names,
# PR/issue titles and GITHUB_ENV, so only plain vX.Y.Z tags are considered.
TAG_RE='^v[0-9]+\.[0-9]+\.[0-9]+$'
RELEASES="$(gh api repos/RustCFML/RustCFML/releases --paginate --jq '.[] | select(.draft | not) | .tag_name')"
NEWEST="$(printf '%s\n' "$RELEASES" | grep -E "$TAG_RE" | sed 's/^v//' | sort -t. -k1,1n -k2,2n -k3,3n | tail -1 | sed 's/^/v/')"
[ "$NEWEST" != "v" ] && [ -n "$NEWEST" ] || { echo "::error::Could not resolve the newest RustCFML release."; exit 1; }
STABLE="$(gh api repos/RustCFML/RustCFML/releases/latest --jq .tag_name 2>/dev/null || true)"
[[ "$STABLE" =~ $TAG_RE ]] || STABLE=""

# 0 when $1 sorts strictly after $2 as a version (both vX.Y.Z).
newer_than() {
  [ "$1" != "$2" ] && [ "$(printf '%s\n%s\n' "${1#v}" "${2#v}" | sort -t. -k1,1n -k2,2n -k3,3n | tail -1)" = "${1#v}" ]
}

if [ "$NEWEST" = "$PINNED" ] || ! newer_than "$NEWEST" "$PINNED"; then
  echo "RustCFML already at the newest release ($PINNED). Nothing to do."
  exit 0
fi

# The listed reason for a release in KNOWN_BAD, or nothing.
known_bad() {
  grep -v '^[[:space:]]*#' "$DIR/KNOWN_BAD" 2>/dev/null | awk -v tag="$1" '$1 == tag { $1 = ""; sub(/^ /, ""); print; exit }' || true
}

# Run the full core suite against $1 in compare mode. Sets EVAL_RC (run-suite.sh's
# exit code) and EVAL_JSON (its verdict file).
evaluate() {
  EVAL_JSON="${RUNNER_TEMP:-${TMPDIR:-/tmp}}/rustcfml-candidate-$1.json"
  rm -f "$EVAL_JSON"
  echo "Running the full core suite against $1..."
  set +e
  RUSTCFML_VERSION="$1" RUSTCFML_RESULT_JSON="$EVAL_JSON" bash "$DIR/run-suite.sh"
  EVAL_RC=$?
  set -e
}

# Move the pin to $1 (green) and export it for the workflow's bump PR.
pin() {
  echo "Suite green against $1 — bumping the pin and regenerating the baseline."
  # Moves ENGINE_VERSION, the per-asset sha256 pins in ENGINE_SHA256 (from the
  # release's published digests), and the CLI's copies of both in RustCFMLEngine.cfc,
  # which can't read tools/ once installed (#3812). bump-pin.sh checks everything
  # BEFORE touching a file, so a failure leaves every pin as it was.
  bash "$DIR/bump-pin.sh" "$1"
  RUSTCFML_VERSION="$1" bash "$DIR/run-suite.sh" --write-baseline
  echo "Pinned version bumped to $1 and baseline.json regenerated."
  if [ -n "${GITHUB_ENV:-}" ]; then
    echo "RUSTCFML_LATEST=$1" >> "$GITHUB_ENV"
    echo "RUSTCFML_PINNED=$PINNED" >> "$GITHUB_ENV"
  fi
}

# Report a rejected candidate $1 (verdict in $2) for notify-rejection.sh.
reject() {
  local fingerprint
  fingerprint="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["fingerprint"])' "$2" 2>/dev/null || true)"
  if [ -z "$fingerprint" ]; then
    echo "::error::run-suite.sh rejected $1 but wrote no readable verdict at $2."
    exit 1
  fi
  echo "::warning::RustCFML $1 rejected: the suite has new failures versus the pinned baseline ($PINNED). Pin unchanged. See the job summary for the named diff."
  if [ -n "${GITHUB_ENV:-}" ]; then
    echo "RUSTCFML_REJECTED=$1" >> "$GITHUB_ENV"
    echo "RUSTCFML_PINNED=$PINNED" >> "$GITHUB_ENV"
    echo "RUSTCFML_FINGERPRINT=$fingerprint" >> "$GITHUB_ENV"
    echo "RUSTCFML_RESULT_JSON=$2" >> "$GITHUB_ENV"
  fi
}

# 1. The newest release. A release listed in KNOWN_BAD is never evaluated: running the
#    suite against it would only reproduce the listed breakage (a hang turns the run
#    red every day).
echo "Newest RustCFML release: $NEWEST (pinned $PINNED; latest stable ${STABLE:-unknown})."
fallback=false
reason="$(known_bad "$NEWEST")"
if [ -n "$reason" ]; then
  echo "::notice::RustCFML $NEWEST is listed in tools/rustcfml/KNOWN_BAD and is not evaluated; pin stays $PINNED. ${reason}"
  fallback=true
else
  evaluate "$NEWEST"
  case "$EVAL_RC" in
    0) pin "$NEWEST"; exit 0 ;;
    3) reject "$NEWEST" "$EVAL_JSON"; fallback=true ;;
    *) echo "::error::Could not evaluate RustCFML $NEWEST (run-suite.sh exit $EVAL_RC: download, boot or response failure). Pin unchanged."
       exit 1 ;;
  esac
fi

# 2. Fallback: a newer stable release than the pin, when the newest isn't usable.
if $fallback && [ -n "$STABLE" ] && [ "$STABLE" != "$NEWEST" ] && newer_than "$STABLE" "$PINNED"; then
  reason="$(known_bad "$STABLE")"
  if [ -n "$reason" ]; then
    echo "::notice::RustCFML $STABLE (latest stable) is listed in tools/rustcfml/KNOWN_BAD and is not evaluated either. ${reason}"
    exit 0
  fi
  echo "Falling back to the latest stable release, $STABLE."
  evaluate "$STABLE"
  case "$EVAL_RC" in
    0) pin "$STABLE" ;;
    3) echo "::warning::RustCFML $STABLE (latest stable) is rejected too. Pin unchanged." ;;
    *) echo "::error::Could not evaluate RustCFML $STABLE (run-suite.sh exit $EVAL_RC). Pin unchanged."
       exit 1 ;;
  esac
fi
exit 0
