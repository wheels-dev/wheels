#!/usr/bin/env bash
# tools/lucee-extensions/sqlite/install.sh — install the SQLite extension into a Lucee server.
#
# Two paths:
#   1. .lex into lucee-server/deploy/ — the canonical Lucee path. Works for
#      installs done before the server first boots; requires the deploy
#      auto-install flow to recognize the .lex (Lucee 7 has been observed
#      to silently move it to failed-to-deploy/ on some configurations).
#   2. Patched JAR straight into lucee-server/bundles/ — the workaround
#      Wheels users have been doing by hand. This is the path this script
#      uses by default because it's deterministic on Lucee 7.
#
# Usage:
#   install.sh <server-dir>            # e.g. ~/.wheels/servers/blog
#   install.sh --with-lex <server-dir> # also copy .lex to deploy/
#
# Run AFTER the server has been created (so lucee-server/bundles/ exists)
# and BEFORE it next starts (or restart it after this script).

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
DIST="$HERE/dist"

WITH_LEX=false
if [ "${1:-}" = "--with-lex" ]; then
    WITH_LEX=true
    shift
fi

SERVER_DIR="${1:-}"
if [ -z "$SERVER_DIR" ] || [ ! -d "$SERVER_DIR/lucee-server" ]; then
    echo "Usage: $0 [--with-lex] <server-dir>" >&2
    echo "  <server-dir> must contain lucee-server/ (e.g. ~/.wheels/servers/<name>)" >&2
    exit 1
fi

LEX="$(ls "$DIST"/*.lex 2>/dev/null | head -1)"
if [ -z "$LEX" ]; then
    echo "✗ no .lex found in $DIST/. Run build.sh first." >&2
    exit 1
fi

# Extract the bundle JAR from inside the .lex — that JAR is the patched one
# (Bundle-SymbolicName + Require-Capability fixed for OSGi on Java 11+).
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
unzip -q "$LEX" -d "$TMP"

JAR="$(ls "$TMP"/jars/*.jar 2>/dev/null | head -1)"
if [ -z "$JAR" ]; then
    echo "✗ no bundle JAR inside $LEX/jars/" >&2
    exit 1
fi
JAR_NAME="$(basename "$JAR")"

mkdir -p "$SERVER_DIR/lucee-server/bundles"
cp "$JAR" "$SERVER_DIR/lucee-server/bundles/$JAR_NAME"
echo "✓ installed bundle: $SERVER_DIR/lucee-server/bundles/$JAR_NAME"

if $WITH_LEX; then
    mkdir -p "$SERVER_DIR/lucee-server/deploy"
    cp "$LEX" "$SERVER_DIR/lucee-server/deploy/$(basename "$LEX")"
    echo "✓ staged .lex: $SERVER_DIR/lucee-server/deploy/$(basename "$LEX")"
fi

echo ""
echo "Next: start (or restart) the Lucee server for the bundle to be loaded."
