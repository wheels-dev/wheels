#!/usr/bin/env bash
# Tests the Java selection in the /usr/bin/wheels wrapper that
# build-linux-packages.sh generates for the .deb and .rpm packages.
#
# LuCLI is compiled for Java 21. The wrapper must use a Java 21+ runtime even
# when JAVA_HOME points at an older JDK (GitHub's Ubuntu runners export
# JAVA_HOME=Java 17), and fail with a message naming Java 21 when there is none.
#
# Hermetic: extracts the wrapper's `java-select` block and runs it against fake
# Java homes (a `release` file and/or a bin/java that prints a version), with a
# PATH that holds only the tools the block needs, so the result never depends
# on the Java installed on the machine running the test.
#
# Usage:
#   bash tools/distribution-drafts/linux-packages/test-wrapper-java.sh
#   bash tools/distribution-drafts/linux-packages/test-wrapper-java.sh --real
#       Also run the block against THIS machine's JAVA_HOME and JDKs, and require
#       a Java 21+ result. On a GitHub Ubuntu runner JAVA_HOME is Java 17 with
#       Java 21 installed alongside, which is exactly the case that broke.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD="${DIR}/build-linux-packages.sh"
# Physical path, so it matches what `readlink -f` returns (macOS: /var -> /private/var).
T="$(cd "$(mktemp -d)" && pwd -P)"
trap 'rm -rf "${T}"' EXIT

# The wrapper is the quoted heredoc in build-linux-packages.sh; the block under
# test sits between its java-select markers.
sed -n "/^cat > \"\${BUILD_DIR}\/build\/wrapper.sh\" <<'WRAPPER_EOF'\$/,/^WRAPPER_EOF\$/p" "${BUILD}" | sed '1d;$d' > "${T}/wrapper.sh"
sed -n '/^# --- java-select:begin ---$/,/^# --- java-select:end ---$/p' "${T}/wrapper.sh" > "${T}/select.sh"
if ! grep -q 'java-select:end' "${T}/select.sh"; then
  echo "FAIL: could not extract the java-select block from ${BUILD}" >&2
  exit 1
fi

# Tools the block needs, and nothing else (in particular no real `java`).
mkdir -p "${T}/sysbin"
for tool in sed head readlink; do
  src="$(command -v "${tool}")" || { echo "FAIL: ${tool} not found" >&2; exit 1; }
  ln -s "${src}" "${T}/sysbin/${tool}"
done

# fake_jdk <dir> <java -version string or ""> <release JAVA_VERSION or "">
fake_jdk() {
  mkdir -p "$1/bin"
  printf '#!/bin/bash\n' > "$1/bin/java"
  if [ -n "$2" ]; then
    printf 'echo "openjdk version \\"%s\\" 2026-01-01" >&2\n' "$2" >> "$1/bin/java"
  fi
  chmod +x "$1/bin/java"
  if [ -n "$3" ]; then
    printf 'IMPLEMENTOR="Test"\nJAVA_VERSION="%s"\n' "$3" > "$1/release"
  fi
}

J="${T}/jdks"
fake_jdk "${J}/jdk21" "21.0.4" "21.0.4"
fake_jdk "${J}/jdk25" "25" "25"
fake_jdk "${J}/jdk17" "17.0.20" "17.0.20"
fake_jdk "${J}/jdk8" "1.8.0_402" "1.8.0_402"
fake_jdk "${J}/jdk17-norelease" "17.0.1" ""
fake_jdk "${J}/jdk21-norelease" "21.0.2" ""

# Layouts for WHEELS_JVM_DIR (stands in for /usr/lib/jvm).
mkdir -p "${T}/jvm-empty"
mkdir -p "${T}/jvm-deb21"; ln -s "${J}/jdk21" "${T}/jvm-deb21/java-21-openjdk-amd64"
mkdir -p "${T}/jvm-default17"; ln -s "${J}/jdk17" "${T}/jvm-default17/default-java"
mkdir -p "${T}/jvm-default21"; ln -s "${J}/jdk21-norelease" "${T}/jvm-default21/default-java"
mkdir -p "${T}/jvm-rhel21"; ln -s "${J}/jdk21" "${T}/jvm-rhel21/java-21-openjdk-21.0.4.0.7-1.el9.x86_64"

# `java` on PATH, as the alternatives system provides it.
mkdir -p "${T}/alt21" "${T}/alt17"
ln -s "${J}/jdk21/bin/java" "${T}/alt21/java"
ln -s "${J}/jdk17/bin/java" "${T}/alt17/java"

PASS=0
FAIL=0

# check <name> <expected exit> <expected JAVA_HOME or ""> <stderr must contain or ""> <JAVA_HOME or "-"> <jvm dir> <extra PATH or "">
check() {
  local name="$1" want_rc="$2" want_home="$3" want_err="$4" java_home="$5" jvm="$6" extra="$7"
  local path="${T}/sysbin" out err rc
  [ -n "${extra}" ] && path="${extra}:${path}"
  local -a envs=(env -i "HOME=${T}" "PATH=${path}" "WHEELS_JVM_DIR=${jvm}")
  [ "${java_home}" != "-" ] && envs+=("JAVA_HOME=${java_home}")
  set +e
  out="$("${envs[@]}" /bin/bash -c "set -euo pipefail; source '${T}/select.sh'; echo \"SELECTED=\${JAVA_HOME}\"" 2> "${T}/err")"
  rc=$?
  set -e
  err="$(cat "${T}/err")"
  local problems=""
  [ "${rc}" = "${want_rc}" ] || problems+=" exit ${rc} (want ${want_rc});"
  if [ -n "${want_home}" ] && [ "${out}" != "SELECTED=${want_home}" ]; then
    problems+=" selected '${out#SELECTED=}' (want '${want_home}');"
  fi
  if [ -n "${want_err}" ] && [[ "${err}" != *"${want_err}"* ]]; then
    problems+=" stderr missing '${want_err}';"
  fi
  if [ -z "${want_err}" ] && [ -n "${err}" ]; then
    problems+=" unexpected stderr '${err}';"
  fi
  if [ -z "${problems}" ]; then
    PASS=$((PASS + 1)); echo "ok   ${name}"
  else
    FAIL=$((FAIL + 1)); echo "FAIL ${name}:${problems}"
    if [ -n "${err}" ]; then printf '       stderr: %s\n' "${err}"; fi
  fi
}

NONE="Java 21 or newer is required but was not found"

check "JAVA_HOME at Java 21 is used"               0 "${J}/jdk21" "" "${J}/jdk21" "${T}/jvm-empty" ""
check "JAVA_HOME at a newer Java (25) is used"      0 "${J}/jdk25" "" "${J}/jdk25" "${T}/jvm-empty" ""
check "JAVA_HOME at Java 17 falls back to Java 21"  0 "${T}/jvm-deb21/java-21-openjdk-amd64" "ignoring JAVA_HOME=${J}/jdk17 (Java 17)" "${J}/jdk17" "${T}/jvm-deb21" ""
check "JAVA_HOME at Java 8 (1.8) falls back"        0 "${T}/jvm-deb21/java-21-openjdk-amd64" "(Java 8)" "${J}/jdk8" "${T}/jvm-deb21" ""
check "JAVA_HOME without a release file is probed" 0 "${T}/jvm-deb21/java-21-openjdk-amd64" "(Java 17)" "${J}/jdk17-norelease" "${T}/jvm-deb21" ""
check "JAVA_HOME that does not exist falls back"   0 "${T}/jvm-deb21/java-21-openjdk-amd64" "(unknown)" "${T}/no-such-jdk" "${T}/jvm-deb21" ""
check "JAVA_HOME at Java 17 with no Java 21 fails"  1 "" "${NONE}" "${J}/jdk17" "${T}/jvm-empty" ""
check "no JAVA_HOME: Debian java-21 dir is used"    0 "${T}/jvm-deb21/java-21-openjdk-amd64" "" "-" "${T}/jvm-deb21" ""
check "no JAVA_HOME: default-java at 17 is skipped" 1 "" "${NONE}" "-" "${T}/jvm-default17" ""
check "no JAVA_HOME: default-java at 21 is used"    0 "${T}/jvm-default21/default-java" "" "-" "${T}/jvm-default21" ""
check "no JAVA_HOME: alternatives java 21 is used"  0 "${J}/jdk21" "" "-" "${T}/jvm-empty" "${T}/alt21"
check "no JAVA_HOME: alternatives java 17 fails"    1 "" "${NONE}" "-" "${T}/jvm-empty" "${T}/alt17"
check "no JAVA_HOME: version-stamped RHEL dir"      0 "${T}/jvm-rhel21/java-21-openjdk-21.0.4.0.7-1.el9.x86_64" "" "-" "${T}/jvm-rhel21" ""
check "no Java at all fails naming Java 21"         1 "" "${NONE}" "-" "${T}/jvm-empty" ""

if [ "${1:-}" = "--real" ]; then
  echo
  echo "Real environment: JAVA_HOME=${JAVA_HOME:-<unset>}"
  set +e
  real_home="$(bash -c "set -euo pipefail; source '${T}/select.sh'; echo \"\${JAVA_HOME}\"" 2> "${T}/real-err")"
  real_rc=$?
  set -e
  if [ -s "${T}/real-err" ]; then sed 's/^/  stderr: /' "${T}/real-err"; fi
  if [ "${real_rc}" != "0" ]; then
    FAIL=$((FAIL + 1)); echo "FAIL real environment: the block exited ${real_rc}"
  else
    real_version="$("${real_home}/bin/java" -version 2>&1 | head -n 1)"
    real_major="$(bash -c "source '${T}/select.sh' >/dev/null 2>&1; _wheels_java_major '${real_home}'" 2>/dev/null || echo 0)"
    echo "  selected ${real_home}: ${real_version}"
    if [ "${real_major}" -ge 21 ] 2>/dev/null; then
      PASS=$((PASS + 1)); echo "ok   real environment selects Java ${real_major}"
    else
      FAIL=$((FAIL + 1)); echo "FAIL real environment selected Java '${real_major}'"
    fi
  fi
fi

echo
echo "${PASS} passed, ${FAIL} failed"
[ "${FAIL}" = "0" ]
