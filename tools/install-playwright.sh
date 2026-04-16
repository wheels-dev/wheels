#!/usr/bin/env bash
# Temporary bootstrap for browser testing. Replaced by `wheels browser:install`
# once PR 2 lands. Reads vendor/wheels/browser-manifest.json for pinned versions.
#
# Playwright Java needs the full classpath — client, driver, driver-bundle, plus
# transitive runtime deps (gson, Java-WebSocket, slf4j) — to boot. Maven normally
# resolves these; since we bootstrap without Maven, the manifest pins every JAR
# with SHA256, and this script downloads + verifies each before invoking the CLI.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MANIFEST="$REPO_ROOT/vendor/wheels/browser-manifest.json"
INSTALL_DIR="${WHEELS_BROWSER_HOME:-$HOME/.wheels/browser}"
LIB_DIR="$INSTALL_DIR/lib"

if [[ ! -f "$MANIFEST" ]]; then
    echo "ERROR: $MANIFEST not found" >&2
    exit 1
fi

mkdir -p "$LIB_DIR"

# Read classpath entries as tab-separated rows: filename\turl\tsha256.
# Avoids bash-4 `mapfile` so the script works with macOS's default bash 3.2.
ENTRIES_FILE=$(mktemp)
trap 'rm -f "$ENTRIES_FILE"' EXIT
# Pass MANIFEST as argv[1] so paths with apostrophes don't break the
# Python single-quoted string. Paranoid for vendor/wheels/ but free.
python3 -c "
import json, sys
m = json.load(open(sys.argv[1]))
for e in m['classpath']:
    print(e['filename'] + '\t' + e['url'] + '\t' + e['sha256'])
" "$MANIFEST" > "$ENTRIES_FILE"

ENTRY_COUNT=$(wc -l < "$ENTRIES_FILE" | tr -d ' ')
if [[ "$ENTRY_COUNT" -eq 0 ]]; then
    echo "ERROR: manifest has no classpath entries" >&2
    exit 1
fi

CLASSPATH=""
while IFS=$'\t' read -r filename url sha; do
    target="$LIB_DIR/$filename"

    if [[ -f "$target" ]]; then
        actual=$(shasum -a 256 "$target" | awk '{print $1}')
        if [[ "$actual" == "$sha" ]]; then
            echo "✓ $filename already present (SHA verified)"
            CLASSPATH+="$target:"
            continue
        fi
        echo "! $filename exists but SHA mismatch; re-downloading"
        rm -f "$target"
    fi

    echo "Downloading $filename from Maven Central..."
    curl -sSL -o "$target" "$url"

    actual=$(shasum -a 256 "$target" | awk '{print $1}')
    if [[ "$actual" != "$sha" ]]; then
        echo "ERROR: SHA mismatch for $filename" >&2
        echo "  expected: $sha" >&2
        echo "  actual:   $actual" >&2
        rm -f "$target"
        exit 1
    fi
    echo "✓ $filename downloaded and SHA-verified"
    CLASSPATH+="$target:"
done < "$ENTRIES_FILE"

# Strip trailing colon
CLASSPATH="${CLASSPATH%:}"

echo ""
echo "Installing Chromium via Playwright CLI (full classpath: $ENTRY_COUNT JARs)..."
java -cp "$CLASSPATH" com.microsoft.playwright.CLI install chromium

echo ""
echo "Done."
echo "  JARs:        $LIB_DIR/  ($ENTRY_COUNT files)"
echo "  Browsers:    ~/.cache/ms-playwright/ (Playwright default cache dir)"
echo "  Install dir: $INSTALL_DIR"
