#!/usr/bin/env bash
# tools/lucee-extensions/sqlite/build.sh — build the SQLite Lucee extension (.lex)
#
# Mirrors the layout produced by lucee/extension-jdbc-postgresql and
# lucee/extension-jdbc-duckdb but uses bash+zip instead of Ant.
#
# Output: dist/<bundle-symbolic-name>-<bundle-version>.lex
# That .lex can be dropped into any Lucee server's lucee-server/deploy/
# directory; Lucee picks it up on next boot, installs the OSGi bundle
# into lucee-server/bundles/, and registers SQLite in the admin UI.

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SRC="$HERE/src"
DIST="$HERE/dist"
TEMP="$HERE/temp"

# ── Inputs ────────────────────────────────────────────────────────────

JAR="$(ls "$SRC"/*.jar 2>/dev/null | head -1)"
if [ -z "$JAR" ] || [ ! -f "$JAR" ]; then
    echo "✗ no .jar found in $SRC/" >&2
    echo "  drop the xerial sqlite-jdbc JAR into src/ and re-run." >&2
    exit 1
fi
JAR_NAME="$(basename "$JAR")"

CFC="$(ls "$SRC"/*.cfc 2>/dev/null | head -1)"
if [ -z "$CFC" ] || [ ! -f "$CFC" ]; then
    echo "✗ no .cfc found in $SRC/" >&2
    exit 1
fi
CFC_NAME="$(basename "$CFC")"

if [ ! -f "$SRC/build.properties" ]; then
    echo "✗ src/build.properties is missing" >&2
    exit 1
fi

# ── Read extension metadata from build.properties ─────────────────────

# shellcheck disable=SC2002
prop() {
    local key="$1"
    cat "$SRC/build.properties" \
        | grep -E "^${key}=" \
        | head -1 \
        | sed -E "s/^${key}=//"
}
EXT_ID="$(prop id)"
EXT_LABEL="$(prop label)"
JDBC_ID="$(prop jdbcid)"
CONN_STR="$(prop connstr)"
EXT_DESC="$(prop description)"
LUCEE_CORE_VERSION="$(prop lucee-core-version)"

for v in EXT_ID EXT_LABEL JDBC_ID CONN_STR EXT_DESC LUCEE_CORE_VERSION; do
    if [ -z "${!v}" ]; then
        echo "✗ src/build.properties is missing key for $v" >&2
        exit 1
    fi
done

# ── Read OSGi bundle metadata from JAR's MANIFEST.MF ──────────────────

manifest_value() {
    # OSGi manifests wrap long lines with a leading space on the next line.
    # Unwrap first, then grep the header.
    unzip -p "$JAR" META-INF/MANIFEST.MF \
        | awk 'BEGIN{prev=""} /^ / {prev=prev substr($0,2); next} {if(prev!="")print prev; prev=$0} END{if(prev!="")print prev}' \
        | grep -E "^$1:" \
        | head -1 \
        | sed -E "s/^$1:[ ]*//" \
        | tr -d '\r'
}

SYMBOLIC_NAME_RAW="$(manifest_value Bundle-SymbolicName)"
# Strip OSGi directives like ";singleton:=true"
SYMBOLIC_NAME="${SYMBOLIC_NAME_RAW%%;*}"
BUNDLE_VERSION="$(manifest_value Bundle-Version)"

if [ -z "$SYMBOLIC_NAME" ] || [ -z "$BUNDLE_VERSION" ]; then
    echo "✗ $JAR_NAME does not declare Bundle-SymbolicName / Bundle-Version" >&2
    echo "  This script needs an OSGi-ready JAR. Wrap with bnd if necessary." >&2
    exit 1
fi

# ── Read JDBC driver class from the SPI file ──────────────────────────

DRIVER_CLASS="$(unzip -p "$JAR" META-INF/services/java.sql.Driver 2>/dev/null \
    | grep -v '^[[:space:]]*#' \
    | grep -v '^[[:space:]]*$' \
    | head -1 \
    | tr -d '[:space:]')"

if [ -z "$DRIVER_CLASS" ]; then
    echo "✗ $JAR_NAME does not declare a java.sql.Driver SPI" >&2
    exit 1
fi

echo "Extension metadata:"
echo "  id              = $EXT_ID"
echo "  label           = $EXT_LABEL"
echo "  jdbcId          = $JDBC_ID"
echo "  connStr         = $CONN_STR"
echo "  driver class    = $DRIVER_CLASS"
echo "  bundle name     = $SYMBOLIC_NAME"
echo "  bundle version  = $BUNDLE_VERSION"
echo "  lucee-core min  = $LUCEE_CORE_VERSION"

# ── Stage the .lex tree ───────────────────────────────────────────────

rm -rf "$TEMP" "$DIST"
STAGE="$TEMP/extension/$SYMBOLIC_NAME-$BUNDLE_VERSION"
mkdir -p "$STAGE/META-INF" "$STAGE/jars" "$STAGE/context/admin/dbdriver"

NOW="$(date '+%Y-%m-%d %H:%M:%S')"
JDBC_JSON="[{'label':'$EXT_LABEL','id':'$JDBC_ID','connectionString':'$CONN_STR','class':'$DRIVER_CLASS','bundleName':'$SYMBOLIC_NAME','bundleVersion':'$BUNDLE_VERSION'}]"

cat > "$STAGE/META-INF/MANIFEST.MF" <<EOF
Manifest-Version: 1.0
Built-Date: $NOW
version: "$BUNDLE_VERSION"
id: "$EXT_ID"
name: "$EXT_LABEL"
description: "$EXT_DESC"
category: "Datasource"
lucee-core-version: "$LUCEE_CORE_VERSION"
start-bundles: false
jdbc: "$JDBC_JSON"
EOF

# Copy + patch the JAR. Two manifest fixes are required for Lucee 7 / Felix on
# JDK 11+:
#   1. xerial declares Require-Capability with `version=1.8` (exact match) —
#      Felix on Java 21 reports osgi.ee=JavaSE versions 1.8/11/21 separately,
#      and exact-match against 1.8 fails resolution on some configurations.
#      Relax to `(|(osgi.ee=J2SE)(osgi.ee=JavaSE))(version>=1.8)` so the
#      bundle loads on any Java 8+ runtime — same filter PostgreSQL uses.
#   2. xerial uses `Bundle-SymbolicName: ...;singleton:=true`. The directive
#      is harmless but the bundle filename / lookup we declare in the .lex
#      manifest uses the bare symbolic name — strip the directive from the
#      JAR's manifest so they match exactly.
# Renaming the file to <symbolicName>-<bundleVersion>.jar matches how Lucee's
# bundle loader expects to find it.
PATCHED_DIR="$TEMP/patched-jar"
mkdir -p "$PATCHED_DIR"
unzip -q "$JAR" -d "$PATCHED_DIR"
python3 - "$PATCHED_DIR/META-INF/MANIFEST.MF" "$SYMBOLIC_NAME" <<'PYEOF'
import sys
mf_path, symbolic_name = sys.argv[1], sys.argv[2]
with open(mf_path, 'rb') as f:
    text = f.read().decode('utf-8')
def unfold(s):
    lines, cur = [], ''
    for line in s.split('\r\n'):
        if line.startswith(' '):
            cur += line[1:]
        else:
            if cur != '':
                lines.append(cur)
            cur = line
    if cur != '':
        lines.append(cur)
    return lines
def fold(lines):
    out = []
    for line in lines:
        if len(line) <= 70:
            out.append(line)
            continue
        out.append(line[:70])
        rest = line[70:]
        while rest:
            out.append(' ' + rest[:69])
            rest = rest[69:]
    return out
patched = []
for line in unfold(text):
    if line.startswith('Bundle-SymbolicName:'):
        patched.append(f'Bundle-SymbolicName: {symbolic_name}')
    elif line.startswith('Require-Capability:'):
        patched.append('Require-Capability: osgi.ee;filter:="(&(|(osgi.ee=J2SE)(osgi.ee=JavaSE))(version>=1.8))"')
    else:
        patched.append(line)
out = '\r\n'.join(fold(patched)) + '\r\n\r\n'
with open(mf_path, 'w', encoding='utf-8', newline='') as f:
    f.write(out)
PYEOF

PATCHED_JAR="$STAGE/jars/$SYMBOLIC_NAME-$BUNDLE_VERSION.jar"
(
    cd "$PATCHED_DIR"
    zip -qrX0 "$PATCHED_JAR" META-INF/MANIFEST.MF
    zip -qrX  "$PATCHED_JAR" . -x "META-INF/MANIFEST.MF"
)

# Copy the admin driver descriptor.
cp "$CFC" "$STAGE/context/admin/dbdriver/$CFC_NAME"

# Copy logo if present.
if [ -f "$SRC/logo.png" ]; then
    cp "$SRC/logo.png" "$STAGE/META-INF/logo.png"
fi

# ── Zip → .lex ────────────────────────────────────────────────────────

mkdir -p "$DIST"
LEX_NAME="$SYMBOLIC_NAME-$BUNDLE_VERSION.lex"
LEX_PATH="$DIST/$LEX_NAME"

(cd "$STAGE" && zip -qr "$LEX_PATH" .)

rm -rf "$TEMP"

echo ""
echo "✓ built $LEX_NAME"
echo "  $LEX_PATH ($(du -h "$LEX_PATH" | awk '{print $1}'))"
echo ""
echo "Install:"
echo "  cp \"$LEX_PATH\" ~/.wheels/servers/<name>/lucee-server/deploy/"
echo "  wheels stop && wheels server start --force"
