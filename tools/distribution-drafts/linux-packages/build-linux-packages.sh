#!/bin/bash
# Builds .deb and .rpm packages from a release artifact bundle using nfpm.
#
# Inputs (env vars):
#   WHEELS_VERSION   — full version including any -snapshot.N suffix
#   CHANNEL          — "stable" or "bleeding-edge" (default: stable)
#   ARTIFACTS_DIR    — directory holding wheels-cli-<v>.zip and wheels-core-<v>.zip
#                       (default: artifacts/wheels/${WHEELS_VERSION})
#   LUCLI_LINUX_URL  — URL for the Linux LuCLI binary (default: cybersonic upstream)
#   OUT_DIR          — where to write the .deb / .rpm (default: dist/)
#
# Outputs (in OUT_DIR):
#   wheels_<v>_amd64.deb      (or wheels-be_<v>_amd64.deb for BE channel)
#   wheels-<v>.x86_64.rpm
#
# This script is idempotent — it tears down and recreates the build/ staging dir.
# Run from the repo root.

set -euo pipefail

WHEELS_VERSION="${WHEELS_VERSION:?WHEELS_VERSION must be set}"
CHANNEL="${CHANNEL:-stable}"
ARTIFACTS_DIR="${ARTIFACTS_DIR:-artifacts/wheels/${WHEELS_VERSION}}"
LUCLI_VERSION="${LUCLI_VERSION:-0.3.7}"
LUCLI_LINUX_URL="${LUCLI_LINUX_URL:-https://github.com/cybersonic/LuCLI/releases/download/v${LUCLI_VERSION}/lucli-${LUCLI_VERSION}-linux}"
SQLITE_JDBC_VERSION="3.49.1.0"
SQLITE_JDBC_URL="https://repo1.maven.org/maven2/org/xerial/sqlite-jdbc/${SQLITE_JDBC_VERSION}/sqlite-jdbc-${SQLITE_JDBC_VERSION}.jar"
OUT_DIR="${OUT_DIR:-dist}"
BUILD_DIR="$(pwd)/.linux-pkg-build"

# Pick which nfpm config to use.
if [ "${CHANNEL}" = "bleeding-edge" ]; then
  NFPM_CONFIG="tools/distribution-drafts/linux-packages/nfpm-wheels-be.yaml"
  PKG_NAME="wheels-be"
else
  NFPM_CONFIG="tools/distribution-drafts/linux-packages/nfpm-wheels.yaml"
  PKG_NAME="wheels"
fi

echo "── Building Linux packages ──"
echo "  Channel:  ${CHANNEL}"
echo "  Version:  ${WHEELS_VERSION}"
echo "  Source:   ${ARTIFACTS_DIR}"
echo "  Output:   ${OUT_DIR}"

# ── Stage everything nfpm needs into ./build/ ──────────────────────────
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}/build/module" "${BUILD_DIR}/build/framework"

# 1. Unzip the CLI module into build/module/
unzip -q "${ARTIFACTS_DIR}/wheels-cli-${WHEELS_VERSION}.zip" -d "${BUILD_DIR}/build/module/"

# 2. Unzip the framework into build/framework/
unzip -q "${ARTIFACTS_DIR}/wheels-core-${WHEELS_VERSION}.zip" -d "${BUILD_DIR}/build/framework/"

# 3. Download the LuCLI Linux binary as build/lucli
curl -fsSL -o "${BUILD_DIR}/build/lucli" "${LUCLI_LINUX_URL}"
chmod +x "${BUILD_DIR}/build/lucli"

# 4. Download SQLite JDBC
curl -fsSL -o "${BUILD_DIR}/build/sqlite-jdbc.jar" "${SQLITE_JDBC_URL}"

# 5. Generate the user-facing /usr/bin/wheels wrapper
cat > "${BUILD_DIR}/build/wrapper.sh" <<'WRAPPER_EOF'
#!/bin/bash
# /usr/bin/wheels — Wheels CLI wrapper for Linux .deb/.rpm install.
#
# Mirrors the macOS Homebrew wrapper's behavior:
#   - exports JAVA_HOME and LUCLI_HOME
#   - on first run (or version mismatch), syncs the module + framework from
#     /opt/wheels/module/ into ~/.wheels/modules/wheels/
#   - stages SQLite JDBC into Lucee Express's lib/ext/ (cliff fix)
#   - intercepts --version / -v before LuCLI's picocli absorbs it
#   - execs /opt/wheels/lucli with the original argv

set -euo pipefail

# Honor user-set JAVA_HOME if present; otherwise probe for OpenJDK 21.
if [ -z "${JAVA_HOME:-}" ]; then
  for candidate in \
    /usr/lib/jvm/java-21-openjdk-amd64 \
    /usr/lib/jvm/java-21-openjdk \
    /usr/lib/jvm/temurin-21-jdk-amd64 \
    /usr/lib/jvm/zulu-21 \
    /usr/lib/jvm/default-java; do
    if [ -d "${candidate}" ]; then
      export JAVA_HOME="${candidate}"
      break
    fi
  done
fi
if [ -z "${JAVA_HOME:-}" ] || [ ! -x "${JAVA_HOME}/bin/java" ]; then
  echo "wheels: cannot find a Java 21 runtime. Install openjdk-21-jre-headless (apt)" >&2
  echo "        or java-21-openjdk-headless (yum/dnf)." >&2
  exit 1
fi

export LUCLI_HOME="${HOME}/.wheels"
export PATH="${JAVA_HOME}/bin:${PATH}"

# --version / -v short-circuit so users see Wheels branding before LuCLI
# absorbs the flag.
INSTALLED_VERSION="$(cat /opt/wheels/.version 2>/dev/null || echo unknown)"
case "${1:-}" in
  --version|-v)
    CHANNEL="$(cat /opt/wheels/.channel 2>/dev/null || echo stable)"
    echo "wheels ${INSTALLED_VERSION} (${CHANNEL})"
    echo "  homepage: https://wheels.dev"
    exit 0
    ;;
esac

# Module + framework sync. Fast-path skips when versions match.
MODULE_DIR="${LUCLI_HOME}/modules/wheels"
MODULE_VERSION_FILE="${MODULE_DIR}/.module-version"
USER_INSTALLED="$(cat "${MODULE_VERSION_FILE}" 2>/dev/null || echo none)"
if [ "${USER_INSTALLED}" != "${INSTALLED_VERSION}" ]; then
  echo "Syncing wheels ${INSTALLED_VERSION}..." >&2
  rm -rf "${MODULE_DIR}"
  mkdir -p "${MODULE_DIR}"
  cp -r /opt/wheels/module/. "${MODULE_DIR}/"
  echo "${INSTALLED_VERSION}" > "${MODULE_VERSION_FILE}"
fi

# Stage SQLite JDBC into Lucee Express on first run.
LUCEE_EXT_DIR="$(find "${LUCLI_HOME}/express" -path "*/lib/ext" -type d 2>/dev/null | head -1 || true)"
if [ -n "${LUCEE_EXT_DIR}" ] && ! ls "${LUCEE_EXT_DIR}"/sqlite-jdbc*.jar >/dev/null 2>&1; then
  cp /opt/wheels/sqlite-jdbc.jar "${LUCEE_EXT_DIR}/sqlite-jdbc.jar"
fi

exec /opt/wheels/lucli "$@"
WRAPPER_EOF

# 6. Stamp the version + channel into /opt/wheels so the wrapper can read them
echo "${WHEELS_VERSION}" > "${BUILD_DIR}/build/.version"
echo "${CHANNEL}" > "${BUILD_DIR}/build/.channel"
# Add these to the nfpm contents list dynamically
cat >> "${NFPM_CONFIG}" <<NFPM_EXTRA_EOF || true
# Channel/version stamps — appended by build-linux-packages.sh
NFPM_EXTRA_EOF
# Note: we won't actually mutate the YAML here since nfpm reads contents
# directly from disk paths. Drop the .version and .channel files into the
# staging dir instead and add corresponding lines via sed if needed. For now,
# they live alongside lucli in /opt/wheels/.

# ── Run nfpm ─────────────────────────────────────────────────────────────
cd "${BUILD_DIR}"
mkdir -p "${OUT_DIR}"
NFPM_OUT="$(pwd)/${OUT_DIR}"

if ! command -v nfpm >/dev/null 2>&1; then
  echo "nfpm not found on PATH. Install from https://github.com/goreleaser/nfpm/releases" >&2
  exit 1
fi

# Translate WHEELS_VERSION (with -snapshot.N) into a SemVer-friendly form for
# .deb/.rpm. Both formats accept a tilde for pre-release ordering: `4.0.1~snapshot.1700`
# sorts BELOW 4.0.1 (which is correct — snapshot 1700 ships before GA 4.0.1).
DEB_RPM_VERSION="$(echo "${WHEELS_VERSION}" | sed 's/-snapshot/~snapshot/')"

WHEELS_VERSION="${DEB_RPM_VERSION}" nfpm pkg \
  --config "../${NFPM_CONFIG}" \
  --packager deb \
  --target "${NFPM_OUT}/${PKG_NAME}_${DEB_RPM_VERSION}_amd64.deb"

WHEELS_VERSION="${DEB_RPM_VERSION}" nfpm pkg \
  --config "../${NFPM_CONFIG}" \
  --packager rpm \
  --target "${NFPM_OUT}/${PKG_NAME}-${DEB_RPM_VERSION}.x86_64.rpm"

echo "── Done ──"
ls -la "${NFPM_OUT}/" | grep -E "${PKG_NAME}_|${PKG_NAME}-"
