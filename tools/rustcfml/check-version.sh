#!/usr/bin/env bash
# Detect a newer RustCFML release than the pinned tools/rustcfml/ENGINE_VERSION.
#
# When a newer release exists, run the full core suite against it (compare mode
# against the current baseline.json). Three outcomes (#3687):
#
#   accepted  no new failures vs the pinned baseline: bump ENGINE_VERSION,
#             regenerate baseline.json, and export RUSTCFML_LATEST/PINNED via
#             GITHUB_ENV so the workflow opens the bump PR.
#   rejected  the suite ran and has new failures: leave the pin unchanged,
#             emit a ::warning:: with the named diff, and export
#             RUSTCFML_REJECTED/RUSTCFML_FINGERPRINT/RUSTCFML_RESULT_JSON so the
#             workflow can notify once per candidate + failure fingerprint.
#             This is the check doing its job, not an operational failure.
#   error     the candidate could not be evaluated (release lookup, download,
#             boot, unparseable response): exit 1 so the run goes red.
#
# Exits 0 when already at the latest release, on accepted, and on rejected.
# Exits 1 only when the candidate could not be evaluated.
#
# The required PR check (rustcfml-ci.yml) is unaffected: it calls run-suite.sh
# directly and fails on any non-zero exit.
#
# Requires: gh on PATH, GH_TOKEN set (for release metadata + binary download).
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PINNED="$(tr -d '[:space:]' < "$DIR/ENGINE_VERSION")"

# Keep the tag's `v` prefix — ENGINE_VERSION stores it verbatim (e.g.
# `v0.637.0`), and run-suite.sh passes the value straight to
# `gh release download`, which needs the real tag name.
LATEST="$(gh api repos/RustCFML/RustCFML/releases/latest --jq .tag_name)"
[ -n "$LATEST" ] || { echo "::error::Could not resolve the latest RustCFML release."; exit 1; }
# The tag comes from another repository and ends up in branch names, PR/issue
# titles and GITHUB_ENV; accept only a plain release tag.
if ! [[ "$LATEST" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "::error::Unexpected RustCFML release tag format: '$LATEST' (expected vX.Y.Z)."
  exit 1
fi

if [ "$LATEST" = "$PINNED" ]; then
  echo "RustCFML already at latest ($PINNED). Nothing to do."
  exit 0
fi

echo "Newer RustCFML release available: $LATEST (pinned $PINNED)."
echo "Running the full core suite against $LATEST..."

RESULT_JSON="${RUNNER_TEMP:-${TMPDIR:-/tmp}}/rustcfml-candidate-${LATEST}.json"
rm -f "$RESULT_JSON"
set +e
RUSTCFML_VERSION="$LATEST" RUSTCFML_RESULT_JSON="$RESULT_JSON" bash "$DIR/run-suite.sh"
rc=$?
set -e

case "$rc" in
  0)
    echo "Suite green against $LATEST — bumping the pin and regenerating the baseline."
    # The installed CLI can't read ENGINE_VERSION (it doesn't ship tools/), so
    # it carries its own copy of the pin: move it in the same step (#3812).
    # Check it can be moved BEFORE touching ENGINE_VERSION, so a failure leaves
    # both pins as they were.
    CLI_ENGINE="$DIR/../../cli/lucli/services/rustcfml/RustCFMLEngine.cfc"
    PIN_LINE='^([[:space:]]*variables\.engineVersion = ")v[0-9]+\.[0-9]+\.[0-9]+(";)$'
    if [ "$(grep -Ec "$PIN_LINE" "$CLI_ENGINE")" != "1" ]; then
      echo "::error::Could not find exactly one engineVersion pin line in $CLI_ENGINE; update it to $LATEST by hand."
      exit 1
    fi
    echo "$LATEST" > "$DIR/ENGINE_VERSION"
    sed -E -i.bak "s/$PIN_LINE/\1$LATEST\2/" "$CLI_ENGINE" && rm -f "$CLI_ENGINE.bak"
    RUSTCFML_VERSION="$LATEST" bash "$DIR/run-suite.sh" --write-baseline
    echo "Pinned version bumped to $LATEST and baseline.json regenerated."
    if [ -n "${GITHUB_ENV:-}" ]; then
      echo "RUSTCFML_LATEST=$LATEST" >> "$GITHUB_ENV"
      echo "RUSTCFML_PINNED=$PINNED" >> "$GITHUB_ENV"
    fi
    exit 0
    ;;
  3)
    FINGERPRINT="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["fingerprint"])' "$RESULT_JSON" 2>/dev/null || true)"
    if [ -z "$FINGERPRINT" ]; then
      echo "::error::run-suite.sh rejected $LATEST but wrote no readable verdict at $RESULT_JSON."
      exit 1
    fi
    echo "::warning::RustCFML $LATEST rejected: the suite has new failures versus the pinned baseline ($PINNED). Pin unchanged. See the job summary for the named diff."
    if [ -n "${GITHUB_ENV:-}" ]; then
      echo "RUSTCFML_REJECTED=$LATEST" >> "$GITHUB_ENV"
      echo "RUSTCFML_PINNED=$PINNED" >> "$GITHUB_ENV"
      echo "RUSTCFML_FINGERPRINT=$FINGERPRINT" >> "$GITHUB_ENV"
      echo "RUSTCFML_RESULT_JSON=$RESULT_JSON" >> "$GITHUB_ENV"
    fi
    exit 0
    ;;
  *)
    echo "::error::Could not evaluate RustCFML $LATEST (run-suite.sh exit $rc: download, boot or response failure). Pin unchanged."
    exit 1
    ;;
esac
