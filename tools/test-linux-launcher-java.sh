#!/usr/bin/env bash
# Exercises the Java 21 resolution in the /usr/bin/wheels launcher that
# tools/distribution-drafts/linux-packages/build-linux-packages.sh generates
# for the .deb and .rpm packages (#3728 smoke: a pre-set JAVA_HOME at Temurin
# 17 used to win over the openjdk-21 the package pulled in, and `wheels info`
# died with UnsupportedClassVersionError).
#
# The launcher block between its `java-resolve begin/end` markers is extracted,
# /usr/lib/jvm is rewritten to a temp dir of fake JDKs (stub `java` scripts
# that print a chosen `-version` banner), and the block runs under `env -i`
# with a PATH holding only readlink (+ an optional fake java), so no real Java
# on this machine can influence the result.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

SRC="tools/distribution-drafts/linux-packages/build-linux-packages.sh"
BASH_BIN="$(command -v bash)"
READLINK_BIN="$(command -v readlink)"

TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

BLOCK="${TMP}/block.sh"
sed -n '/^# --- java-resolve begin/,/^# --- java-resolve end/p' "${SRC}" > "${BLOCK}"
if ! grep -q 'java-resolve end' "${BLOCK}"; then
  echo "FAIL: could not extract the java-resolve block from ${SRC}"
  exit 1
fi

fail=0
n=0

# fake_jdk <dir> <version-banner-string> [release-JAVA_VERSION]
fake_jdk() {
  mkdir -p "$1/bin"
  printf '#!%s\necho '\''%s'\'' >&2\n' "${BASH_BIN}" "$2" > "$1/bin/java"
  chmod +x "$1/bin/java"
  if [ -n "${3:-}" ]; then
    printf 'IMPLEMENTOR="Fake"\nJAVA_VERSION="%s"\n' "$3" > "$1/release"
  fi
}
banner() { printf 'openjdk version "%s" 2026-07-15' "$1"; }

# new_case: fresh fake /usr/lib/jvm + PATH dir for one scenario.
new_case() {
  n=$((n + 1))
  CASE="${TMP}/case${n}"
  JVM="${CASE}/jvm"
  BIN="${CASE}/bin"
  mkdir -p "${JVM}" "${BIN}"
  ln -s "${READLINK_BIN}" "${BIN}/readlink"
  sed "s#/usr/lib/jvm#${JVM}#g" "${BLOCK}" > "${CASE}/launcher.sh"
  printf 'printf "%%s\\n" "${JAVA_HOME}"\n' >> "${CASE}/launcher.sh"
}

# run_case <JAVA_HOME or "-" for unset>  -> sets OUT, ERR, RC
run_case() {
  local jh=()
  [ "$1" != "-" ] && jh=("JAVA_HOME=$1")
  OUT="$(env -i PATH="${BIN}" ${jh[@]+"${jh[@]}"} "${BASH_BIN}" -euo pipefail "${CASE}/launcher.sh" 2>"${CASE}/stderr")"
  RC=$?
  ERR="$(cat "${CASE}/stderr")"
}

check() { # <description> <condition-result 0/1>
  if [ "$2" -eq 0 ]; then echo "ok   $1"; else
    echo "FAIL $1"; echo "     rc=${RC} out='${OUT}'"; echo "     stderr: ${ERR}"; fail=1
  fi
}
is() { [ "$1" = "$2" ]; echo $?; }
has() { case "$1" in *"$2"*) echo 0 ;; *) echo 1 ;; esac; }

# 1. JAVA_HOME=17 (the GitHub runner case) is rejected; the probed 21 wins.
new_case
fake_jdk "${CASE}/temurin-17" "$(banner 17.0.20)"
fake_jdk "${JVM}/java-21-openjdk-amd64" "$(banner 21.0.12)"
run_case "${CASE}/temurin-17"
check "JAVA_HOME=17 rejected, probe finds 21" "$(is "${RC}:${OUT}" "0:${JVM}/java-21-openjdk-amd64")"
check "JAVA_HOME=17 rejection prints a one-line notice" \
  "$(is "${ERR}" "wheels: ignoring JAVA_HOME=${CASE}/temurin-17 (Java 17); Wheels needs Java 21+")"

# 2. JAVA_HOME=21 is accepted as-is, silently.
new_case
fake_jdk "${CASE}/jdk21" "$(banner 21.0.2)"
fake_jdk "${JVM}/java-21-openjdk-amd64" "$(banner 21.0.12)"
run_case "${CASE}/jdk21"
check "JAVA_HOME=21 accepted" "$(is "${RC}:${OUT}" "0:${CASE}/jdk21")"
check "JAVA_HOME=21 prints nothing" "$(is "${ERR}" "")"

# 3. JAVA_HOME=25 (and an -ea build string) is accepted.
new_case
fake_jdk "${CASE}/jdk25" "$(banner 25-ea)"
run_case "${CASE}/jdk25"
check "JAVA_HOME=25-ea accepted" "$(is "${RC}:${OUT}" "0:${CASE}/jdk25")"

# 4. Legacy 1.8 version scheme parses as 8 and is rejected.
new_case
fake_jdk "${CASE}/jdk8" 'java version "1.8.0_402"'
fake_jdk "${JVM}/java-21-openjdk-arm64" "$(banner 21.0.12)"
run_case "${CASE}/jdk8"
check "JAVA_HOME=1.8 rejected as Java 8" "$(is "${RC}:${OUT}" "0:${JVM}/java-21-openjdk-arm64")"
check "JAVA_HOME=1.8 notice names Java 8" "$(has "${ERR}" "(Java 8)")"

# 5. The release file is read first (no JVM started): release says 17 even
#    though the stub banner claims 21 -> rejected.
new_case
fake_jdk "${CASE}/jdk-rel17" "$(banner 21.0.0)" "17.0.9"
fake_jdk "${JVM}/java-21-openjdk" "$(banner 21.0.5)" "21.0.5"
run_case "${CASE}/jdk-rel17"
check "release file JAVA_VERSION=17 rejected" "$(is "${RC}:${OUT}" "0:${JVM}/java-21-openjdk")"

# 5b. A "Picked up JAVA_TOOL_OPTIONS" line ahead of the version banner (the
#     JVM prints it first whenever that variable is set) does not hide it.
new_case
fake_jdk "${CASE}/jdk17-opts" "Picked up JAVA_TOOL_OPTIONS: -Dfoo=\"bar\"
$(banner 17.0.20)"
fake_jdk "${JVM}/java-21-openjdk-amd64" "Picked up JAVA_TOOL_OPTIONS: -Dfoo=\"bar\"
$(banner 21.0.12)"
run_case "${CASE}/jdk17-opts"
check "JAVA_TOOL_OPTIONS banner: 17 rejected, 21 found" "$(is "${RC}:${OUT}" "0:${JVM}/java-21-openjdk-amd64")"
check "JAVA_TOOL_OPTIONS banner: notice still names Java 17" "$(has "${ERR}" "(Java 17)")"

# 6. JAVA_HOME pointing nowhere is ignored with a notice.
new_case
fake_jdk "${JVM}/java-21-openjdk-amd64" "$(banner 21.0.12)"
run_case "${CASE}/does-not-exist"
check "missing JAVA_HOME dir ignored" "$(is "${RC}:${OUT}" "0:${JVM}/java-21-openjdk-amd64")"
check "missing JAVA_HOME notice" "$(has "${ERR}" "(no bin/java there)")"

# 7. Unset JAVA_HOME: probe candidates are version-checked too (default-java
#    at 17 is skipped in favour of a later 21 via the glob fallback).
new_case
fake_jdk "${JVM}/default-java" "$(banner 17.0.20)"
fake_jdk "${JVM}/java-21-openjdk-21.0.5.0.11-2.el9.x86_64" "$(banner 21.0.5)"
run_case -
check "unset JAVA_HOME skips default-java=17, glob finds 21" \
  "$(is "${RC}:${OUT}" "0:${JVM}/java-21-openjdk-21.0.5.0.11-2.el9.x86_64")"

# 8. `java` on PATH (alternatives symlink) resolving to 21 is used.
new_case
fake_jdk "${CASE}/opt/jdk21" "$(banner 21.0.8)"
ln -s "${CASE}/opt/jdk21/bin/java" "${BIN}/java"
run_case -
check "PATH java -> 21 resolved to its JAVA_HOME" "$(is "${RC}:${OUT}" "0:${CASE}/opt/jdk21")"

# 9. `java` on PATH resolving to 17 (runner alternatives default) is skipped.
new_case
fake_jdk "${CASE}/opt/jdk17" "$(banner 17.0.20)"
ln -s "${CASE}/opt/jdk17/bin/java" "${BIN}/java"
fake_jdk "${JVM}/temurin-21-jdk-amd64" "$(banner 21.0.12)"
run_case -
check "PATH java -> 17 skipped, probe finds 21" "$(is "${RC}:${OUT}" "0:${JVM}/temurin-21-jdk-amd64")"

# 10. JAVA_HOME=17 and no Java 21 anywhere: notice + the final error, exit 1.
new_case
fake_jdk "${CASE}/temurin-17" "$(banner 17.0.20)"
fake_jdk "${JVM}/default-java" "$(banner 17.0.20)"
run_case "${CASE}/temurin-17"
check "no Java 21 anywhere exits 1" "$(is "${RC}" "1")"
check "no Java 21 anywhere keeps the final error" "$(has "${ERR}" "cannot find a Java 21 or newer runtime")"
check "no Java 21 anywhere still prints the notice" "$(has "${ERR}" "ignoring JAVA_HOME=${CASE}/temurin-17 (Java 17)")"

# 11. The generated wrapper as a whole still parses.
sed -n "/^cat > \"\${BUILD_DIR}\/build\/wrapper.sh\" <<'WRAPPER_EOF'/,/^WRAPPER_EOF/p" "${SRC}" \
  | sed '1d;$d' > "${TMP}/wrapper.sh"
RC=0; OUT=""; ERR="$("${BASH_BIN}" -n "${TMP}/wrapper.sh" 2>&1)" || RC=$?
check "generated wrapper passes bash -n" "$(is "${RC}" "0")"
[ -s "${TMP}/wrapper.sh" ] || { echo "FAIL could not extract the wrapper heredoc"; fail=1; }

exit $fail
