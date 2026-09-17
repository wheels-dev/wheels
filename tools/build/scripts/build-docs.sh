#!/bin/bash
set -e

# Build script for the Wheels local docs bundle.
#
# Produces wheels-docs-<framework-version>.zip — the prebuilt Astro/Starlight
# output for the guides and API sites, built to be served from /wheels/guides/
# and /wheels/api/ so the framework can serve them out of the user's cache with
# no internet connection.
#
# Mounted at <app webroot>/wheels-docs/ and served as /wheels-docs/guides/ and
# /wheels-docs/api/. NOT /wheels/...: the dev server's Lucee urlRewrite only
# routes extension-LESS paths to the front controller, so extension-bearing
# asset URLs under /wheels/ never reach Wheels and 404 from Tomcat. Under the
# app webroot Tomcat serves the assets directly and only the extension-less
# page paths go through the framework.
#
# The bundle deliberately carries ONE docs version (the newest slug), not every
# version the sites publish: the full API site is ~1.3 GB across nine versions
# because Starlight server-renders its whole sidebar into each of 2,739 pages.
# One version compresses to ~20 MB, which is the size the Homebrew formula can
# reasonably fetch on install. Links to other versions will not resolve offline;
# the version switcher is a known limitation of the current-only bundle.
#
# Usage: ./build-docs.sh <framework_version> [docs_version]

VERSION=$1
DOCS_VERSION=${2:-}

if [ -z "$VERSION" ]; then
	echo "Usage: $0 <framework_version> [docs_version]" >&2
	exit 1
fi

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
WEB_DIR="${REPO_ROOT}/web"
ARTIFACTS_DIR="${REPO_ROOT}/artifacts/wheels/${VERSION}"
STAGE_DIR="${ARTIFACTS_DIR}/docs-stage"

echo "Building Wheels docs bundle for framework v${VERSION}"

# ── Resolve the docs version ────────────────────────────────────────────────
# The newest slug in the shared version metadata is the current docs line. Kept
# in one place (web/packages/ui/src/data/versions.ts) so the bundle, the sites,
# and the version switcher cannot drift.
if [ -z "$DOCS_VERSION" ]; then
	DOCS_VERSION=$(node -e "
		const fs = require('fs');
		const src = fs.readFileSync('${WEB_DIR}/packages/ui/src/data/versions.ts', 'utf8');
		const block = src.match(/GUIDES_VERSIONS[\s\S]*?=\s*\[([\s\S]*?)\];/);
		const slugs = (block ? block[1].match(/slug:\s*'([^']+)'/g) : []) || [];
		const first = slugs[0] ? slugs[0].replace(/.*'([^']+)'.*/, '\$1') : '';
		process.stdout.write(first);
	")
fi

if [ -z "$DOCS_VERSION" ]; then
	echo "Could not resolve the docs version; pass it explicitly." >&2
	exit 1
fi
echo "  docs version: ${DOCS_VERSION}"

# ── Build both sites under their served sub-paths ───────────────────────────
if [ ! -d "${WEB_DIR}/node_modules" ]; then
	echo "  installing web workspace dependencies"
	(cd "${WEB_DIR}" && pnpm install --frozen-lockfile)
fi

echo "  building guides -> /wheels-docs/guides/"
rm -rf "${WEB_DIR}/sites/guides/dist" "${WEB_DIR}/sites/guides/.astro"
(cd "${WEB_DIR}" && WHEELS_DOCS_BASE=/wheels-docs/guides/ pnpm --filter @wheels-dev/site-guides build)

echo "  building api -> /wheels-docs/api/"
rm -rf "${WEB_DIR}/sites/api/dist" "${WEB_DIR}/sites/api/.astro"
(cd "${WEB_DIR}" && WHEELS_DOCS_BASE=/wheels-docs/api/ pnpm --filter @wheels-dev/site-api build)

# ── Repair absolute URLs in metadata ───────────────────────────────────────
# Astro builds canonical / og:url / the sitemap from `site`, but the local
# bundle also sets `base`, so they come out as
# https://guides.wheels.dev/wheels-docs/guides/v4-0-0/ — a URL that does not
# exist on the live site. Nothing fetches these, but they should still describe
# the real page, so strip the local mount prefix back off.
echo "  repairing canonical/sitemap URLs"
for pair in "guides:guides.wheels.dev" "api:api.wheels.dev"; do
	site="${pair%%:*}"
	domain="${pair##*:}"
	# HTML: canonical, og:url, and any other absolute link into the mount
	find "${WEB_DIR}/sites/${site}/dist" -name "*.html" -print0 \
		| xargs -0 sed -i.bak -e "s|https://${domain}/wheels-docs/${site}/|https://${domain}/|g"
	# Sitemaps
	find "${WEB_DIR}/sites/${site}/dist" -name "*.xml" -print0 \
		| xargs -0 sed -i.bak -e "s|https://${domain}/wheels-docs/${site}/|https://${domain}/|g"
	# sed -i.bak leaves backups behind; drop them
	find "${WEB_DIR}/sites/${site}/dist" -name "*.bak" -delete
done

# ── Stage ──────────────────────────────────────────────────────────────────
rm -rf "${STAGE_DIR}"
mkdir -p "${STAGE_DIR}/guides" "${STAGE_DIR}/api"

# Copy everything except the other version trees, then delete those.
rsync -a --exclude='v[0-9]*-[0-9]*-[0-9]*/' "${WEB_DIR}/sites/guides/dist/" "${STAGE_DIR}/guides/"
rsync -a --exclude='v[0-9]*-[0-9]*-[0-9]*/' "${WEB_DIR}/sites/api/dist/" "${STAGE_DIR}/api/"

cp -R "${WEB_DIR}/sites/guides/dist/${DOCS_VERSION}" "${STAGE_DIR}/guides/${DOCS_VERSION}"
cp -R "${WEB_DIR}/sites/api/dist/${DOCS_VERSION}" "${STAGE_DIR}/api/${DOCS_VERSION}"

# Manifest — the serving code reads this to fail loudly rather than serve a
# half-built bundle, and `wheels docs fetch` uses docsVersion to warn when the
# cache is for a different docs line than the installed framework.
node -e "
	const fs = require('fs');
	fs.writeFileSync('${STAGE_DIR}/manifest.json', JSON.stringify({
		frameworkVersion: '${VERSION}',
		docsVersion: '${DOCS_VERSION}',
		builtAt: new Date().toISOString(),
		sites: ['guides', 'api']
	}, null, 2) + '\n');
"

# ── Package ────────────────────────────────────────────────────────────────
mkdir -p "${ARTIFACTS_DIR}"
ZIP="${ARTIFACTS_DIR}/wheels-docs-${VERSION}.zip"
rm -f "${ZIP}"
(cd "${STAGE_DIR}" && zip -q -r -9 "${ZIP}" .)

echo "  wrote $(basename "${ZIP}") ($(du -h "${ZIP}" | cut -f1))"
echo "  docs version bundled: ${DOCS_VERSION}"
