#!/usr/bin/env bash
# Detect a newer RustCFML release than the pinned tools/rustcfml/ENGINE_VERSION.
#
# When a newer release exists, run the full core suite against it (compare mode
# against the current baseline.json). If the suite is GREEN (no new failures vs
# the pinned baseline), bump ENGINE_VERSION and regenerate baseline.json, and
# surface the old/new versions via GITHUB_ENV so a follow-up
# create-pull-request step can open the bump PR. If the suite has NEW failures,
# exit 1 and leave the pin unchanged — the daily run surfaces the regressions
# rather than silently absorbing them.
#
# Exits 0 when already at the latest release, or when a green bump was applied.
# Exits 1 when the candidate release is not usable (download/boot/new failures).
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

if [ "$LATEST" = "$PINNED" ]; then
  echo "RustCFML already at latest ($PINNED). Nothing to do."
  exit 0
fi

echo "Newer RustCFML release available: $LATEST (pinned $PINNED)."
echo "Running the full core suite against $LATEST..."

# Compare mode exits non-zero on NEW failures vs the pinned baseline.
if RUSTCFML_VERSION="$LATEST" bash "$DIR/run-suite.sh"; then
  echo "Suite green against $LATEST — bumping the pin and regenerating the baseline."
  echo "$LATEST" > "$DIR/ENGINE_VERSION"
  RUSTCFML_VERSION="$LATEST" bash "$DIR/run-suite.sh" --write-baseline
  echo "Pinned version bumped to $LATEST and baseline.json regenerated."
  if [ -n "${GITHUB_ENV:-}" ]; then
    echo "RUSTCFML_LATEST=$LATEST" >> "$GITHUB_ENV"
    echo "RUSTCFML_PINNED=$PINNED" >> "$GITHUB_ENV"
  fi
  exit 0
else
  echo "::error::Suite has NEW failures against $LATEST — leaving the pin at $PINNED."
  exit 1
fi
