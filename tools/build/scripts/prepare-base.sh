#!/bin/bash
set -e

# Prepare script for Wheels Base Template (ForgeBox publishing)
# This script prepares the directory structure without creating ZIP files
# Usage: ./prepare-base.sh <version> <branch> <build_number> <is_prerelease>
#
# SINGLE SOURCE OF TRUTH (Peter, 2026-06-12): the published ForgeBox base
# template is regenerated from cli/lucli/templates/app/ — the canonical
# `wheels new` output — NOT the repo-root demo app. This keeps CommandBox-born
# apps byte-for-byte aligned with CLI-born apps and auto-drops repo-only demo
# cruft (app/jobs/ProcessOrdersJob.cfc, public/ApplicationProxy.cfc,
# public/index.bxm, the dev /cli + /modules mappings in public/Application.cfc).
#
# CommandBox-only build artifacts (server.json, box.json, README.md, the base
# .gitignore, .mcp.json, .opencode.json) are layered on top from
# tools/build/base/ — these are the CommandBox equivalents of what `wheels new`
# users get via lucee.json/rewrite.config/_env.
#
# The LuCLI template ships unsubstituted placeholders ({{appName}},
# {{datasourceName}}, {{reloadPassword}}, {{luceeAdminPassword}}) that the
# `wheels new` installer fills in. `box install` has NO substitution step, so
# this script substitutes them to sane working defaults at BUILD TIME — the
# published artifact carries zero placeholders and `box server start` boots with
# no manual edits.

VERSION=$1
BRANCH=$2
BUILD_NUMBER=$3
IS_PRERELEASE=$4

echo "Preparing Wheels Base Template v${VERSION} for ForgeBox publishing"

# Locate the repo root from this script's location so the build is independent
# of the current working directory.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
TEMPLATE_DIR="${REPO_ROOT}/cli/lucli/templates/app"

# Build-time substitution defaults (the dev defaults `wheels new` would yield).
APP_NAME="Wheels"
CFML_ENGINE="lucee"
DATASOURCE_NAME="wheels"
RELOAD_PASSWORD=""
LUCEE_ADMIN_PASSWORD=""

# Setup directories
BUILD_DIR="build-wheels-base"

if [ ! -d "${TEMPLATE_DIR}" ]; then
    echo "ERROR: LuCLI app template not found at ${TEMPLATE_DIR}"
    exit 1
fi

# Cleanup and create directories
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"
echo "Current Working Directory"
pwd
echo "Template source: ${TEMPLATE_DIR}"

# Create build label file
BUILD_LABEL="wheels-base-template-${VERSION}-$(date +%Y%m%d%H%M%S)"
echo "Built on $(date)" > "${BUILD_DIR}/${BUILD_LABEL}"

# Copy the canonical app scaffold (app/config/db/public/tests/vendor) from the
# LuCLI template — the same tree `wheels new` produces.
echo "Copying app scaffold from LuCLI template..."
cp -r "${TEMPLATE_DIR}/app" "${BUILD_DIR}/"
cp -r "${TEMPLATE_DIR}/config" "${BUILD_DIR}/"
cp -r "${TEMPLATE_DIR}/db" "${BUILD_DIR}/"
cp -r "${TEMPLATE_DIR}/public" "${BUILD_DIR}/"
cp -r "${TEMPLATE_DIR}/tests" "${BUILD_DIR}/"
cp -r "${TEMPLATE_DIR}/vendor" "${BUILD_DIR}/"

# The deprecated plugins/ system is no longer part of a fresh Wheels app; the
# LuCLI template carries app/plugins/ for modern (vendor/) packages instead.
# Keep a webroot-level plugins/ marker only if the template ever ships one.

# Generate the default Main controller + index view. `wheels new` writes these
# post-copy (cli/lucli/Module.cfc) because they are app-specific starter content,
# NOT framework structure — so they don't live in the static template. The root
# route (config/routes.cfm) points to main##index, so without these GET / throws
# Wheels.ViewNotFound. Mirror the CLI exactly so a box-install app and a
# `wheels new` app render the same welcome page.
echo "Generating default Main controller and index view..."
mkdir -p "${BUILD_DIR}/app/views/main"
printf 'component extends="Controller" {\n\n\tfunction index() {\n\t\t// Default action\n\t}\n\n}\n' \
    > "${BUILD_DIR}/app/controllers/Main.cfc"
printf '<h1>Welcome to %s</h1>\n<p>Your Wheels application is running. Edit this file at app/views/main/index.cfm</p>\n' \
    "${APP_NAME}" > "${BUILD_DIR}/app/views/main/index.cfm"

# Materialize directory-keeper markers so empty scaffold dirs survive packaging.
# CommandBox `package publish` keeps .keep / .gitkeep files, so no rename is
# needed — but normalize .gitkeep -> .keep is intentionally NOT done; both ship.
echo "Ensuring db/ ships with a keeper marker..."
touch "${BUILD_DIR}/db/.keep"

# Translate the LuCLI underscore-prefixed dotfile templates into the CommandBox
# equivalents. _env becomes env.example (box.json's postInstall copies it to
# .env on first install). _gitignore is superseded by the CommandBox-specific
# tools/build/base/.gitignore copied below.
if [ -f "${TEMPLATE_DIR}/_env" ]; then
    cp "${TEMPLATE_DIR}/_env" "${BUILD_DIR}/env.example"
fi

mkdir -p "${BUILD_DIR}/vendor"
touch "${BUILD_DIR}/vendor/.keep"

# Copy AI documentation files from the repo root.
echo "Copying AI documentation..."
cp -r "${REPO_ROOT}/.ai" "${BUILD_DIR}/"
cp "${REPO_ROOT}/CLAUDE.md" "${BUILD_DIR}/"
cp -r "${REPO_ROOT}/.claude" "${BUILD_DIR}/"
cp -r "${REPO_ROOT}/.opencode" "${BUILD_DIR}/" 2>/dev/null || true

# Apache 2.0 §4(d) requires NOTICE to propagate to derivatives.
cp "${REPO_ROOT}/LICENSE" "${BUILD_DIR}/"
cp "${REPO_ROOT}/NOTICE" "${BUILD_DIR}/"

# Copy VS Code snippets
echo "Copying VS Code snippets..."
mkdir -p "${BUILD_DIR}/.vscode"
cp "${REPO_ROOT}/.vscode/wheels.code-snippets" "${BUILD_DIR}/.vscode/"
cp "${REPO_ROOT}/.vscode/wheels-test.code-snippets" "${BUILD_DIR}/.vscode/"

# Layer the CommandBox-specific build overrides on top. These are the CommandBox
# counterparts of the LuCLI server config (lucee.json/rewrite.config): a
# CommandBox server.json (webroot/cfengine/rewrites pointing at the template's
# public/urlrewrite.xml), the ForgeBox box.json (dependency + installPaths), the
# package README, the base .gitignore (must NOT exclude db/), and editor/MCP
# config.
echo "Applying CommandBox build overrides..."
cp "${REPO_ROOT}/tools/build/base/.gitignore" "${BUILD_DIR}/.gitignore"
cp "${REPO_ROOT}/tools/build/base/box.json" "${BUILD_DIR}/box.json"
cp "${REPO_ROOT}/tools/build/base/README.md" "${BUILD_DIR}/README.md"
cp "${REPO_ROOT}/tools/build/base/server.json" "${BUILD_DIR}/server.json"
cp "${REPO_ROOT}/tools/build/base/.mcp.json" "${BUILD_DIR}/.mcp.json"
cp "${REPO_ROOT}/tools/build/base/.opencode.json" "${BUILD_DIR}/.opencode.json"

# Substitute template placeholders to working defaults so the published artifact
# has NO |tokens| / {{tokens}}. `box install` has no substitution step, so this
# is what makes `box server start` boot with zero manual edits.
#
# The app-level tokens ({{appName}}, {{datasourceName}}, {{reloadPassword}},
# {{luceeAdminPassword}}) appear only in config/app.cfm, config/settings.cfm,
# app/views/layout.cfm and env.example — NOT in app/snippets/*.txt (those carry
# code-gen tokens like {{belongsToRelationships}} that must ship verbatim), so
# substituting these four specific tokens is safe across the whole tree.
#
# The legacy |token| forms come only from the CommandBox overrides (server.json,
# and any historical config copies); substitute them too.
echo "Substituting template placeholders to build defaults..."
substitute_placeholders() {
    local file="$1"
    sed -i.bak \
        -e "s/{{appName}}/${APP_NAME}/g" \
        -e "s/{{datasourceName}}/${DATASOURCE_NAME}/g" \
        -e "s/{{reloadPassword}}/${RELOAD_PASSWORD}/g" \
        -e "s/{{luceeAdminPassword}}/${LUCEE_ADMIN_PASSWORD}/g" \
        -e "s/|appName|/${APP_NAME}/g" \
        -e "s/|cfmlEngine|/${CFML_ENGINE}/g" \
        -e "s/|datasourceName|/${DATASOURCE_NAME}/g" \
        -e "s/|reloadPassword|/${RELOAD_PASSWORD}/g" \
        "$file" && rm "${file}.bak"
}
# Restrict substitution to config + server + env + the layout view; never touch
# app/snippets/*.txt code-gen templates.
for f in \
    "${BUILD_DIR}/config/app.cfm" \
    "${BUILD_DIR}/config/settings.cfm" \
    "${BUILD_DIR}/config/routes.cfm" \
    "${BUILD_DIR}/config/environment.cfm" \
    "${BUILD_DIR}/app/views/layout.cfm" \
    "${BUILD_DIR}/server.json" \
    "${BUILD_DIR}/env.example"; do
    if [ -f "$f" ]; then
        substitute_placeholders "$f"
    fi
done

# Replace version placeholders
echo "Replacing version placeholders..."
find "${BUILD_DIR}" -type f \( -name "*.json" -o -name "*.md" -o -name "*.cfm" -o -name "*.cfc" \) | while read file; do
    sed -i.bak "s/@build\.version@/${VERSION}/g" "$file" && rm "${file}.bak"
    sed -i.bak "s/\${VERSION_NUMBER}/${VERSION}/g" "$file" && rm "${file}.bak"
done

# Handle build number based on release type
if [ "${IS_PRERELEASE}" = "true" ]; then
    # PreRelease: use build number as-is
    find "${BUILD_DIR}" -type f \( -name "*.json" -o -name "*.md" -o -name "*.cfm" -o -name "*.cfc" \) | while read file; do
        sed -i.bak "s/@build\.number@/${BUILD_NUMBER}/g" "$file" && rm "${file}.bak"
    done
elif [ "${BRANCH}" = "develop" ]; then
    # Snapshot: replace +@build.number@ with -snapshot
    find "${BUILD_DIR}" -type f \( -name "*.json" -o -name "*.md" -o -name "*.cfm" -o -name "*.cfc" \) | while read file; do
        sed -i.bak "s/+@build\.number@/-snapshot/g" "$file" && rm "${file}.bak"
    done
else
    # Regular release: use build number as-is
    find "${BUILD_DIR}" -type f \( -name "*.json" -o -name "*.md" -o -name "*.cfm" -o -name "*.cfc" \) | while read file; do
        sed -i.bak "s/@build\.number@/${BUILD_NUMBER}/g" "$file" && rm "${file}.bak"
    done
fi

echo "Wheels Base Template prepared for ForgeBox publishing!"
echo "Directory: ${BUILD_DIR}/"
cd "${BUILD_DIR}/"
pwd
