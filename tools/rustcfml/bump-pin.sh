#!/usr/bin/env bash
# Move the RustCFML engine pin to <tag>: tools/rustcfml/ENGINE_VERSION and
# ENGINE_SHA256, plus the CLI's copies of both in RustCFMLEngine.cfc (the
# installed CLI doesn't ship tools/). check-version.sh calls this once a newer
# release passes the suite (#3812).
#
# The sha256 pins come from the release's published asset digests (GitHub
# API). Everything is checked BEFORE any file is touched: a missing digest or
# pin line leaves every pin as it was and exits 1.
#
# Usage: bash tools/rustcfml/bump-pin.sh vX.Y.Z
# Requires: gh on PATH, GH_TOKEN set.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TAG="${1:-}"
if ! [[ "$TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "::error::bump-pin.sh needs a release tag vX.Y.Z (got '$TAG')."
  exit 1
fi

CLI_ENGINE="$DIR/../../cli/lucli/services/rustcfml/RustCFMLEngine.cfc"
PIN_LINE='^([[:space:]]*variables\.engineVersion = ")v[0-9]+\.[0-9]+\.[0-9]+(";)$'
if [ "$(grep -Ec "$PIN_LINE" "$CLI_ENGINE")" != "1" ]; then
  echo "::error::Could not find exactly one engineVersion pin line in $CLI_ENGINE; update it to $TAG by hand."
  exit 1
fi

# The assets to pin are the ones pinned now (one "<sha256>  <asset>" per line).
ASSETS="$(awk 'NF { print $2 }' "$DIR/ENGINE_SHA256")"
if [ -z "$ASSETS" ]; then
  echo "::error::$DIR/ENGINE_SHA256 lists no assets."
  exit 1
fi
for asset in $ASSETS; do
  if ! [[ "$asset" =~ ^rustcfml-[a-z0-9_-]+$ ]]; then
    echo "::error::Unexpected asset name '$asset' in $DIR/ENGINE_SHA256."
    exit 1
  fi
  if [ "$(grep -Ec "^[[:space:]]*variables\.engineSha256\[\"$asset\"\] = \"[0-9a-f]{64}\";$" "$CLI_ENGINE")" != "1" ]; then
    echo "::error::Could not find exactly one engineSha256 pin line for $asset in $CLI_ENGINE; update it by hand."
    exit 1
  fi
done

if ! DIGESTS="$(gh api "repos/RustCFML/RustCFML/releases/tags/$TAG" --jq '.assets[] | "\(.name) \(.digest)"')"; then
  echo "::error::Could not read the $TAG release assets; pins unchanged."
  exit 1
fi
NEW_SHA256=""
for asset in $ASSETS; do
  sha="$(awk -v a="$asset" '$1 == a { print $2 }' <<<"$DIGESTS" | sed -nE 's/^sha256:([0-9a-f]{64})$/\1/p')"
  if ! [[ "$sha" =~ ^[0-9a-f]{64}$ ]]; then
    echo "::error::The $TAG release publishes no single sha256 digest for $asset; pins unchanged."
    exit 1
  fi
  NEW_SHA256+="$sha  $asset"$'\n'
done

# Every check passed: move all the pins.
echo "$TAG" > "$DIR/ENGINE_VERSION"
printf '%s' "$NEW_SHA256" > "$DIR/ENGINE_SHA256"
sed -E -i.bak "s/$PIN_LINE/\1$TAG\2/" "$CLI_ENGINE"
while read -r sha asset; do
  [ -n "$asset" ] || continue
  sed -E -i.bak "s/^([[:space:]]*variables\.engineSha256\[\"$asset\"\] = \")[0-9a-f]{64}(\";)$/\1$sha\2/" "$CLI_ENGINE"
done <<<"$NEW_SHA256"
rm -f "$CLI_ENGINE.bak"
echo "Engine pin moved to $TAG (ENGINE_VERSION, ENGINE_SHA256 and RustCFMLEngine.cfc)."
