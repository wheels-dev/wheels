#!/usr/bin/env bash
# Download the SQLite JDBC driver that CI installs into Lucee Express, and fail
# loudly unless the file is exactly the pinned jar.
#
# A plain `curl -sL` exits 0 on an HTTP error page or a truncated transfer, and
# the damaged jar only surfaced later as Tomcat's "zip END header not found"
# and `org.sqlite.JDBC` missing at test time. Each attempt here must pass
# `curl --fail` and the SHA-256 check; a mismatch is downloaded again, up to
# three attempts.
#
# Usage: bash tools/ci/fetch-sqlite-jdbc.sh [output-path [version sha256]]
#   output-path defaults to /tmp/sqlite-jdbc.jar. Without a version, it fetches the
#   3.50.3.0 jar CI installs. A different version must come with its SHA-256.
set -euo pipefail

OUT="${1:-/tmp/sqlite-jdbc.jar}"
if [ "$#" -ge 2 ]; then
  if [ "$#" -ne 3 ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "::error::Usage: $0 [output-path [version sha256]]" >&2
    exit 2
  fi
  VERSION="$2"
  SHA256="$3"
else
  VERSION="3.50.3.0"
  # Maven Central's published sqlite-jdbc-3.50.3.0.jar.sha256.
  SHA256="a3f53a2aa15ae9425a9e793bbe9c8e5288febeb4b65ef5c1a4e80d4c2045cf08"
fi
URL="https://repo1.maven.org/maven2/org/xerial/sqlite-jdbc/${VERSION}/sqlite-jdbc-${VERSION}.jar"

sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | cut -d' ' -f1
  else
    shasum -a 256 "$1" | cut -d' ' -f1
  fi
}

tmp="${OUT}.download"
for attempt in 1 2 3; do
  rm -f "$tmp"
  if ! curl -fsSL --retry 3 --retry-delay 2 --retry-all-errors -o "$tmp" "$URL"; then
    echo "Attempt ${attempt}: could not download ${URL}" >&2
  else
    actual="$(sha256_of "$tmp")"
    if [ "$actual" = "$SHA256" ]; then
      mv "$tmp" "$OUT"
      echo "sqlite-jdbc ${VERSION} downloaded and verified (sha256 ${SHA256}): ${OUT}"
      exit 0
    fi
    echo "Attempt ${attempt}: sqlite-jdbc ${VERSION} has sha256 ${actual} ($(wc -c <"$tmp" | tr -d ' ') bytes), expected ${SHA256}" >&2
  fi
  [ "$attempt" -lt 3 ] && sleep 5
done

rm -f "$tmp"
echo "::error::Could not download a verified sqlite-jdbc ${VERSION} from ${URL}" >&2
exit 1
