#!/bin/bash
# Builds .deb and .rpm packages from a release artifact bundle using nfpm.
#
# Inputs (env vars):
#   WHEELS_VERSION   — full version including any -snapshot.N suffix
#   CHANNEL          — "stable" or "bleeding-edge" (default: stable)
#   ARTIFACTS_DIR    — directory holding wheels-module-<v>.tar.gz and wheels-core-<v>.zip
#                       (default: artifacts/wheels/${WHEELS_VERSION})
#   LUCLI_LINUX_URL  — URL for the Linux LuCLI binary (default: cybersonic upstream)
#   OUT_DIR          — where to write the .deb / .rpm (default: dist/)
#
# Outputs (in OUT_DIR) — architecture-independent (Java jar payload):
#   wheels_<v>_all.deb        (or wheels-be_<v>_all.deb for BE channel)
#   wheels-<v>.noarch.rpm
#
# This script is idempotent — it tears down and recreates the build/ staging dir.
# Run from the repo root.

set -euo pipefail

WHEELS_VERSION="${WHEELS_VERSION:?WHEELS_VERSION must be set}"
CHANNEL="${CHANNEL:-stable}"
ARTIFACTS_DIR="${ARTIFACTS_DIR:-artifacts/wheels/${WHEELS_VERSION}}"
LUCLI_VERSION="${LUCLI_VERSION:-0.3.17}"
# Portable JAR launcher (runs on any arch with Java 21) instead of the amd64-only
# native `lucli-linux` binary. This is what makes the .deb/.rpm architecture-
# independent (all/noarch) so they install on arm64 too — and it matches how the
# Scoop manifest already launches LuCLI. Routing to the bundled `wheels` module
# is done via -Dlucli.binary.name=wheels in the wrapper (the native binary did it
# via basename(argv[0])).
LUCLI_JAR_URL="${LUCLI_JAR_URL:-https://github.com/cybersonic/LuCLI/releases/download/v${LUCLI_VERSION}/lucli-${LUCLI_VERSION}.jar}"
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

# 1. Untar the lucli-native CLI module into build/module/.
#    Source-of-truth: release.yml builds wheels-module-${WHEELS_VERSION}.tar.gz
#    from cli/lucli/ — that artifact has Module.cfc at top and is what the
#    brew formula + Scoop manifest stage. The older wheels-cli-${WHEELS_VERSION}.zip
#    is the CommandBox-shaped ForgeBox artifact built from cli/src/; staging
#    it here ships the wrong module and makes `wheels start` fail with
#    `Unknown command: 'start'`. See issue #2700.
tar -xzf "${ARTIFACTS_DIR}/wheels-module-${WHEELS_VERSION}.tar.gz" -C "${BUILD_DIR}/build/module/"

# 2. Unzip the framework into build/framework/
unzip -q "${ARTIFACTS_DIR}/wheels-core-${WHEELS_VERSION}.zip" -d "${BUILD_DIR}/build/framework/"

# 3. Download the portable LuCLI JAR as build/lucli.jar. The wrapper launches it
#    with `java -Dlucli.binary.name=wheels -jar`, which both (a) routes to the
#    bundled wheels module (the flag replaces the old basename(argv[0]) trick the
#    native binary relied on) and (b) is architecture-independent, so the package
#    installs on amd64 AND arm64. See issue #2700 (routing) and the arch-independent
#    refactor.
curl -fsSL -o "${BUILD_DIR}/build/lucli.jar" "${LUCLI_JAR_URL}"

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
#   - execs /opt/wheels/wheels (LuCLI renamed at stage time) so basename(argv[0])
#     is `wheels` and LuCLI's module dispatcher routes via the bundled module

set -euo pipefail

# Honor user-set JAVA_HOME if present; otherwise probe for OpenJDK 21 across the
# Debian/Ubuntu AND RHEL/Fedora layouts, on amd64 and arm64.
if [ -z "${JAVA_HOME:-}" ]; then
  for candidate in \
    /usr/lib/jvm/java-21-openjdk-amd64 \
    /usr/lib/jvm/java-21-openjdk-arm64 \
    /usr/lib/jvm/java-21-openjdk \
    /usr/lib/jvm/jre-21-openjdk \
    /usr/lib/jvm/java-21 \
    /usr/lib/jvm/jre-21 \
    /usr/lib/jvm/temurin-21-jdk-amd64 \
    /usr/lib/jvm/temurin-21-jdk-arm64 \
    /usr/lib/jvm/zulu-21 \
    /usr/lib/jvm/default-java; do
    if [ -x "${candidate}/bin/java" ]; then
      export JAVA_HOME="${candidate}"
      break
    fi
  done
fi
# RHEL/Fedora install into a version-stamped dir (java-21-openjdk-21.0.x...elN.<arch>)
# that the fixed names above don't match, but the headless package registers
# /usr/bin/java via the alternatives system — resolve JAVA_HOME from it.
if [ -z "${JAVA_HOME:-}" ] && command -v java >/dev/null 2>&1; then
  _j="$(command -v java)"
  command -v readlink >/dev/null 2>&1 && _j="$(readlink -f "${_j}" 2>/dev/null || echo "${_j}")"
  _jh="${_j%/bin/java}"
  [ -x "${_jh}/bin/java" ] && export JAVA_HOME="${_jh}"
fi
# Last resort: glob the version-stamped RHEL/Fedora directories directly.
if [ -z "${JAVA_HOME:-}" ]; then
  for d in /usr/lib/jvm/java-21-openjdk-* /usr/lib/jvm/*jre-21* /usr/lib/jvm/*-21-*; do
    if [ -x "${d}/bin/java" ]; then export JAVA_HOME="${d}"; break; fi
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

# Launch via the portable LuCLI jar. -Dlucli.binary.name=wheels routes to the
# bundled wheels module (replacing the native binary's basename(argv[0]) trick),
# and `java -jar` is architecture-independent so this same package runs on
# amd64 and arm64. JAVA_HOME/bin is first on PATH (above), so `java` is the 21.
exec "${JAVA_HOME}/bin/java" -Dlucli.binary.name=wheels -jar /opt/wheels/lucli.jar "$@"
WRAPPER_EOF

# 6. Stamp the version + channel into build/ so nfpm can ship them at
#    /opt/wheels/.version and /opt/wheels/.channel. The wrapper script reads
#    both at runtime to render `wheels --version`. Without them shipping in
#    the package, `wheels --version` returns "unknown (stable)" — see #2700.
#    The corresponding nfpm `contents:` entries live in nfpm-wheels*.yaml.
echo "${WHEELS_VERSION}" > "${BUILD_DIR}/build/.version"
echo "${CHANNEL}" > "${BUILD_DIR}/build/.channel"

# ── Run nfpm ─────────────────────────────────────────────────────────────
# Resolve the output path BEFORE cd-ing into BUILD_DIR. OUT_DIR is documented
# as repo-root-relative (the workflow passes "artifacts/wheels/${WHEELS_VERSION}")
# but we have to `cd "${BUILD_DIR}"` for nfpm to find the staged content
# (the nfpm config references ./build/lucli, ./build/module/, etc.). If we
# resolved NFPM_OUT after the cd, it would land inside .linux-pkg-build/
# instead of the repo's artifacts/ tree — and the GitHub Release upload glob
# would silently match nothing. (Yes, this was a real bug. Run 25637518317.)
mkdir -p "${OUT_DIR}"
NFPM_OUT="$(cd "${OUT_DIR}" && pwd)"
cd "${BUILD_DIR}"

if ! command -v nfpm >/dev/null 2>&1; then
  echo "nfpm not found on PATH. Install from https://github.com/goreleaser/nfpm/releases" >&2
  exit 1
fi

# Translate WHEELS_VERSION (with -snapshot.N) into a SemVer-friendly form for
# .deb/.rpm. Both formats accept a tilde for pre-release ordering: `4.0.1~snapshot.1700`
# sorts BELOW 4.0.1 (which is correct — snapshot 1700 ships before GA 4.0.1).
#
# Sharp edge — disk filename vs upload filename diverge:
#   The output below is written to disk as `wheels_<v>~snapshot.<N>_amd64.deb`,
#   which is the correct on-server name (apt/dpkg use `~` for pre-release
#   ordering). HOWEVER, when this artifact is uploaded to a GitHub Release,
#   GitHub silently rewrites `~` to `.` in the asset filename — the download
#   URL ends up as `wheels_<v>.snapshot.<N>_amd64.deb`. Verified on snapshot
#   v4.0.0-snapshot.1787 (the assets list shows `.snapshot.`, not `~snapshot.`).
#
#   Consequence: any consumer that constructs a download URL (Phase 2 apt repo
#   metadata generator, install scripts, docs) MUST use the `.`-form, even
#   though the file written here has `~`. The metadata *inside* the .deb/.rpm
#   still contains `~`, so once installed, version ordering is correct.
#   See tools/distribution-drafts/linux-packages/README.md § "Tilde mangling"
#   and .github/RELEASE_PLAYBOOK.md § "Common failure modes".
DEB_RPM_VERSION="$(echo "${WHEELS_VERSION}" | sed 's/-snapshot/~snapshot/')"

# Architecture-independent packages: the payload is the LuCLI jar + CFML source
# + a shell wrapper (no native code), so a single package serves every arch.
# deb uses `all`, rpm uses `noarch` — PKG_ARCH is interpolated into the nfpm
# config's `arch:` field.
PKG_ARCH=all WHEELS_VERSION="${DEB_RPM_VERSION}" nfpm pkg \
  --config "../${NFPM_CONFIG}" \
  --packager deb \
  --target "${NFPM_OUT}/${PKG_NAME}_${DEB_RPM_VERSION}_all.deb"

PKG_ARCH=noarch WHEELS_VERSION="${DEB_RPM_VERSION}" nfpm pkg \
  --config "../${NFPM_CONFIG}" \
  --packager rpm \
  --target "${NFPM_OUT}/${PKG_NAME}-${DEB_RPM_VERSION}.noarch.rpm"

echo "── Done ──"
ls -la "${NFPM_OUT}/" | grep -E "${PKG_NAME}_|${PKG_NAME}-"
