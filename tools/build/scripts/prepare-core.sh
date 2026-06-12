#!/bin/bash
set -e

# Prepare script for Wheels Core (ForgeBox publishing)
# This script prepares the directory structure without creating ZIP files
# Usage: ./prepare-core.sh <version> <branch> <build_number> <is_prerelease>

VERSION=$1
BRANCH=$2
BUILD_NUMBER=$3
IS_PRERELEASE=$4

echo "Preparing Wheels Core v${VERSION} for ForgeBox publishing"

# Setup directories
BUILD_DIR="build-wheels-core"

# Cleanup and create directories
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}/wheels"

# Create build label file
BUILD_LABEL="wheels-core-${VERSION}-$(date +%Y%m%d%H%M%S)"
echo "Built on $(date)" > "${BUILD_DIR}/wheels/${BUILD_LABEL}"

# Copy core files from vendor/wheels/
echo "Copying core files..."
cp -r vendor/wheels/* "${BUILD_DIR}/wheels/"

# Apache 2.0 §4(a) requires LICENSE in every distributed artifact and §4(d)
# requires NOTICE to propagate to derivatives.
cp LICENSE "${BUILD_DIR}/wheels/"
cp NOTICE "${BUILD_DIR}/wheels/"

# Copy docs
echo "Copying docs..."
rm -rf "${BUILD_DIR}/wheels/docs"
mkdir -p "${BUILD_DIR}/wheels/docs"
cp -r docs/* "${BUILD_DIR}/wheels/docs/"

# Copy template files. The package now ships TWO manifests:
#
#   wheels.json — the new Wheels-native manifest (slim schema, what the framework
#                 reads at runtime via FrameworkInstaller, Module.runUpgradeCheck,
#                 Global.$buildReleaseZip, etc.).
#   box.json    — CommandBox/ForgeBox-shaped manifest, retained because
#                 `forgebox publish` reads slug/version/type/etc. from box.json
#                 natively — we can't make CommandBox polyglot without forking
#                 it. Once ForgeBox publishing is fully retired (post-4.0
#                 cleanup), the box.json template can be deleted alongside
#                 publish-to-forgebox.sh.
cp tools/build/core/wheels.json "${BUILD_DIR}/wheels/wheels.json"
cp tools/build/core/box.json "${BUILD_DIR}/wheels/box.json"
cp tools/build/core/README.md "${BUILD_DIR}/wheels/README.md"

# Replace version placeholders
echo "Replacing version placeholders..."
find "${BUILD_DIR}/wheels" -type f \( -name "*.json" -o -name "*.md" -o -name "*.cfm" -o -name "*.cfc" \) | while read file; do
    sed -i.bak "s/@build\.version@/${VERSION}/g" "$file" && rm "${file}.bak"
done

# Handle build number based on release type
if [ "${IS_PRERELEASE}" = "true" ]; then
    # PreRelease: use build number as-is
    find "${BUILD_DIR}/wheels" -type f \( -name "*.json" -o -name "*.md" -o -name "*.cfm" -o -name "*.cfc" \) | while read file; do
        sed -i.bak "s/@build\.number@/${BUILD_NUMBER}/g" "$file" && rm "${file}.bak"
    done
elif [ "${BRANCH}" = "develop" ]; then
    # Snapshot: replace +@build.number@ with -snapshot
    find "${BUILD_DIR}/wheels" -type f \( -name "*.json" -o -name "*.md" -o -name "*.cfm" -o -name "*.cfc" \) | while read file; do
        sed -i.bak "s/+@build\.number@/-snapshot/g" "$file" && rm "${file}.bak"
    done
else
    # Regular release: use build number as-is
    find "${BUILD_DIR}/wheels" -type f \( -name "*.json" -o -name "*.md" -o -name "*.cfm" -o -name "*.cfc" \) | while read file; do
        sed -i.bak "s/@build\.number@/${BUILD_NUMBER}/g" "$file" && rm "${file}.bak"
    done
fi

# Replace BuildInfo metadata placeholders. BuildInfo.cfc reads these at app
# start to surface rich diagnostics (commit sha, run url, etc.) on the dev
# toolbar and `wheels info`. Values come from git in the source checkout —
# release.yml passes empty strings via env when not running on a tagged build,
# in which case BuildInfo.cfc blanks the field at runtime. Use | as the sed
# delimiter for fields that may contain / (URLs) or : (timestamps, refs).
COMMIT_SHA=$(git rev-parse HEAD 2>/dev/null || echo "")
COMMIT_SHORT=$(git rev-parse --short=7 HEAD 2>/dev/null || echo "")
COMMIT_SUBJECT=$(git log -1 --pretty=%s 2>/dev/null || echo "")
# Strip newlines defensively (commit subjects shouldn't have any).
COMMIT_SUBJECT=$(printf '%s' "${COMMIT_SUBJECT}" | tr -d '\r\n')
# Escape for CFML double-quoted string literal (BuildInfo.cfc embeds this
# value inside one). # is CFML's variable-interpolation delimiter and "
# closes the string — leaving either unescaped breaks compilation. The
# common case is a PR-suffixed subject like "feat(x): foo (#1234)".
# Note: \# in the pattern is required because bash treats a leading
# unescaped # as an anchor-to-start operator inside ${var//...}.
COMMIT_SUBJECT="${COMMIT_SUBJECT//\#/##}"
COMMIT_SUBJECT="${COMMIT_SUBJECT//\"/\"\"}"
# Escape for sed replacement (\, &) and strip the sed delimiter (|), which
# has no clean representation here. Apply after CFML escaping so the layers
# don't interfere.
COMMIT_SUBJECT="${COMMIT_SUBJECT//\\/\\\\}"
COMMIT_SUBJECT="${COMMIT_SUBJECT//&/\\&}"
COMMIT_SUBJECT="${COMMIT_SUBJECT//|/}"
BUILT_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)
# Run context comes from the GitHub Actions environment. Locally these are
# empty and the placeholders stay unsubstituted, which BuildInfo blanks out.
RUN_ID="${GITHUB_RUN_ID:-}"
REPOSITORY="${GITHUB_REPOSITORY:-}"
RUN_URL=""
if [ -n "${RUN_ID}" ] && [ -n "${REPOSITORY}" ]; then
    RUN_URL="https://github.com/${REPOSITORY}/actions/runs/${RUN_ID}"
fi

find "${BUILD_DIR}/wheels" -type f \( -name "*.json" -o -name "*.md" -o -name "*.cfm" -o -name "*.cfc" \) | while read file; do
    sed -i.bak \
        -e "s|@build\.number@|${BUILD_NUMBER}|g" \
        -e "s|@build\.branch@|${BRANCH}|g" \
        -e "s|@build\.commit@|${COMMIT_SHA}|g" \
        -e "s|@build\.commitShort@|${COMMIT_SHORT}|g" \
        -e "s|@build\.commitSubject@|${COMMIT_SUBJECT}|g" \
        -e "s|@build\.timestamp@|${BUILT_AT}|g" \
        -e "s|@build\.runId@|${RUN_ID}|g" \
        -e "s|@build\.runUrl@|${RUN_URL}|g" \
        -e "s|@build\.repository@|${REPOSITORY}|g" \
        "$file" && rm "${file}.bak"
done

# Sanity check: BuildInfo.cfc commitSubject must not contain unescaped #
# (CFML's variable-interpolation delimiter) or unescaped " (string close).
# Fail loud here so a build pipeline regression surfaces before the artifact
# ever reaches users — an unescaped # bricks every fresh app on first request.
BUILDINFO_CFC="${BUILD_DIR}/wheels/BuildInfo.cfc"
if [ -f "${BUILDINFO_CFC}" ]; then
    cs_line=$(grep -E '^[[:space:]]*commitSubject:' "${BUILDINFO_CFC}" | head -1 || true)
    # Strip the prefix and trailing "," to get the bare string literal contents.
    cs_literal=$(printf '%s' "${cs_line}" | sed -E 's/^[[:space:]]*commitSubject:[[:space:]]*"//; s/",[[:space:]]*$//')
    # Collapse properly-escaped pairs; any remaining # or " is a defect.
    cs_collapsed=$(printf '%s' "${cs_literal}" | sed -e 's/##//g' -e 's/""//g')
    if printf '%s' "${cs_collapsed}" | grep -qE '[#"]'; then
        echo "ERROR: BuildInfo.cfc commitSubject contains an unescaped # or \" — would break CFML compilation." >&2
        echo "       Literal:   ${cs_literal}" >&2
        echo "       Remaining: ${cs_collapsed}" >&2
        exit 1
    fi
fi

# Sanity check: PackageLoader.cfc must detect dev builds STRUCTURALLY (prefix
# `@build.` + suffix `@`), never via a literal `@build.version@` comparison.
# The global `sed s/@build.version@/<version>/g` above (line ~59) rewrites every
# literal version placeholder in this artifact. If such a literal sat in
# $normalizeWheelsVersion()'s guard it would now read `local.raw == "<version>"`,
# normalising the real runtime version to "0.0.0" and silently disabling
# wheelsVersion constraint enforcement for every package on every released build
# (issue #3178). After substitution the only place "${VERSION}" should appear in
# a `local.raw ==` comparison is nowhere — the guard is structural. Fail loud if
# the fragile literal has crept back in.
PACKAGELOADER_CFC="${BUILD_DIR}/wheels/PackageLoader.cfc"
if [ -f "${PACKAGELOADER_CFC}" ]; then
    if grep -qF "local.raw == \"${VERSION}\"" "${PACKAGELOADER_CFC}"; then
        echo "ERROR: PackageLoader.cfc contains a stamped self-version sentinel (local.raw == \"${VERSION}\")." >&2
        echo "       Release stamping clobbered the dev-build guard — wheelsVersion enforcement would be disabled on every released build (issue #3178)." >&2
        echo "       Use the structural Left/Right placeholder check that BuildInfo.cfc::isDev() uses instead of a literal comparison." >&2
        exit 1
    fi
fi

echo "Wheels Core prepared for ForgeBox publishing!"
echo "Directory: ${BUILD_DIR}/wheels/"