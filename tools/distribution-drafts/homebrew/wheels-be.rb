# Wheels Bleeding-Edge Channel — Homebrew Formula
#
# Companion to wheels.rb (stable). This formula tracks pre-release snapshots
# published from the develop branch on every merge.
#
# Conflicts with `wheels` (both ship `bin/wheels`); brew refuses to link both at
# once, so a user is on exactly one channel at a time. Switch with:
#
#   brew uninstall wheels && brew install wheels-be   # stable -> BE
#   brew uninstall wheels-be && brew install wheels   # BE -> stable
#
# Already-scaffolded apps are unaffected: vendor/wheels/ is committed at
# scaffold time, so switching channels only affects what NEXT `wheels new`
# produces.
#
# Auto-bump: a workflow in this tap (wheels-be-bump.yml) listens for
# `repository_dispatch` events of type `snapshot-published` from
# wheels-dev/wheels (the publish-snapshot.yml workflow fires them). On dispatch,
# it computes the new sha256s, opens a PR bumping the URL/version/sha256 fields
# in this file. Tap CI validates and a maintainer rubberstamps.

class WheelsBe < Formula
  desc "Wheels CFML MVC framework — bleeding-edge channel (develop snapshots)"
  homepage "https://wheels.dev"
  license "Apache-2.0"

  # AUTO-BUMP TARGETS — these three lines are rewritten by wheels-be-bump.yml.
  # Format MUST match what the bump workflow's `sed` expects. Don't reorder.
  version "4.0.1-snapshot.1700"
  url "https://github.com/wheels-dev/wheels-snapshots/releases/download/v4.0.1-snapshot.1700/wheels-cli-4.0.1-snapshot.1700.zip"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"

  # Framework artifact — bundled separately so the wrapper script can stage it
  # under ~/.wheels/modules/wheels/vendor/wheels/. URL pattern parallels the CLI
  # zip and is bumped by the same auto-bump workflow.
  resource "wheels-core" do
    url "https://github.com/wheels-dev/wheels-snapshots/releases/download/v4.0.1-snapshot.1700/wheels-core-4.0.1-snapshot.1700.zip"
    sha256 "0000000000000000000000000000000000000000000000000000000000000000"
  end

  # LuCLI binary — pinned independently because it's an upstream artifact
  # (cybersonic/LuCLI). The brew formula stages it as libexec/wheels.
  # LuCLI ships single binaries per OS (no arch split) — the macOS asset is a
  # universal binary that works on both arm64 and x86_64. Source-of-truth:
  # `gh release view v0.3.7 --repo cybersonic/LuCLI --json assets`.
  resource "lucli" do
    on_macos do
      url "https://github.com/cybersonic/LuCLI/releases/download/v0.3.7/lucli-0.3.7-macos"
      sha256 "0000000000000000000000000000000000000000000000000000000000000000"
    end
    on_linux do
      url "https://github.com/cybersonic/LuCLI/releases/download/v0.3.7/lucli-0.3.7-linux"
      sha256 "0000000000000000000000000000000000000000000000000000000000000000"
    end
  end

  # SQLite JDBC — staged into Lucee Express's lib/ext/ on first run by the
  # wrapper script. Avoids the fresh-VM "wheels migrate" cliff (issue #2202).
  resource "sqlite-jdbc" do
    url "https://repo1.maven.org/maven2/org/xerial/sqlite-jdbc/3.49.1.0/sqlite-jdbc-3.49.1.0.jar"
    sha256 "0000000000000000000000000000000000000000000000000000000000000000"
  end

  conflicts_with "wheels", because: "wheels-be installs the same `wheels` binary as the stable channel"

  depends_on "openjdk@21"

  def install
    # Stage the LuCLI binary as libexec/wheels (renamed at install time so the
    # wrapper invocation, ASCII banner, and ~/.wheels home dir all activate).
    libexec.install resource("lucli") => "wheels"
    chmod 0755, libexec/"wheels"

    # Module + framework — brew formula doesn't unzip into ~/.wheels here;
    # it just stages the zips into libexec/. The wrapper does the actual
    # unzip+sync at first run, comparing .module-version against the cached
    # copy under ~/.wheels/modules/wheels/. See ARCHITECTURE.md in cli/lucli/.
    libexec.install Dir["#{buildpath}/wheels-cli-*.zip"].first => "wheels-module.zip"
    resource("wheels-core").stage do
      cp Dir["wheels-core-*.zip"].first, libexec/"wheels-core.zip"
    end
    resource("sqlite-jdbc").stage do
      libexec.install "sqlite-jdbc-3.49.1.0.jar" => "sqlite-jdbc.jar"
    end

    # Wrapper script that handles JAVA_HOME, module sync, --version short-circuit,
    # SQLite JDBC staging into Lucee Express. Generated inline so brew bottling
    # works without an external resource fetch.
    (bin/"wheels").write <<~EOS
      #!/bin/bash
      set -euo pipefail

      export JAVA_HOME="#{Formula["openjdk@21"].opt_prefix}"
      export LUCLI_HOME="${HOME}/.wheels"
      export PATH="${JAVA_HOME}/bin:${PATH}"

      # Channel-aware short-circuits for --version and --help so the user
      # sees Wheels branding before LuCLI's picocli absorbs the flags. Match
      # behavior with the stable formula.
      case "${1:-}" in
        --version|-v)
          echo "wheels #{version} (bleeding-edge)"
          echo "  homepage: https://wheels.dev"
          echo "  channel:  bleeding-edge — published from develop on every merge"
          exit 0
          ;;
      esac

      # `wheels deploy …` arg rewrite (issue #2674). picocli absorbs --version
      # as a root-level flag even when it appears after a subcommand, so the
      # documented `wheels deploy --version=v1.2.3` form blows up before
      # Module.cfc's deploy parser ever runs. Rewrite to --release here so
      # picocli sees something it doesn't claim. Module.cfc accepts both forms.
      if [ "${1:-}" = "deploy" ]; then
        __wheels_rewritten=()
        for __wheels_arg in "$@"; do
          case "${__wheels_arg}" in
            --version=*)   __wheels_rewritten+=("--release=${__wheels_arg##--version=}") ;;
            --version)     __wheels_rewritten+=("--release") ;;
            *)             __wheels_rewritten+=("${__wheels_arg}") ;;
          esac
        done
        set -- "${__wheels_rewritten[@]}"
        unset __wheels_rewritten __wheels_arg
      fi

      # Module + framework + sqlite-jdbc sync. Fast-path skips when versions match.
      MODULE_DIR="${LUCLI_HOME}/modules/wheels"
      MODULE_VERSION_FILE="${MODULE_DIR}/.module-version"
      INSTALLED_VERSION="$(cat "${MODULE_VERSION_FILE}" 2>/dev/null || echo none)"
      EXPECTED_VERSION="#{version}"

      if [ "${INSTALLED_VERSION}" != "${EXPECTED_VERSION}" ]; then
        echo "Syncing wheels-be ${EXPECTED_VERSION}..." >&2
        rm -rf "${MODULE_DIR}"
        mkdir -p "${MODULE_DIR}/vendor/wheels"
        unzip -q -o "#{libexec}/wheels-module.zip" -d "${MODULE_DIR}"
        unzip -q -o "#{libexec}/wheels-core.zip" -d "${MODULE_DIR}/vendor/wheels"
        echo "${EXPECTED_VERSION}" > "${MODULE_VERSION_FILE}"
      fi

      # Stage SQLite JDBC into Lucee Express on first run. The path varies by
      # Lucee version so we do a glob + first-match rather than hardcoding.
      LUCEE_EXT_DIR="$(find "${LUCLI_HOME}/express" -path "*/lib/ext" -type d 2>/dev/null | head -1 || true)"
      if [ -n "${LUCEE_EXT_DIR}" ] && ! ls "${LUCEE_EXT_DIR}"/sqlite-jdbc*.jar >/dev/null 2>&1; then
        cp "#{libexec}/sqlite-jdbc.jar" "${LUCEE_EXT_DIR}/sqlite-jdbc.jar"
      fi

      exec "#{libexec}/wheels" "$@"
    EOS
    chmod 0755, bin/"wheels"
  end

  test do
    assert_match "wheels #{version}", shell_output("#{bin}/wheels --version")
    assert_match "bleeding-edge", shell_output("#{bin}/wheels --version")
  end
end
