#!/usr/bin/env bash
# Exercises the download checksum gate in
# tools/distribution-drafts/linux-packages/build-linux-packages.sh, which the
# LuCLI jar and the SQLite JDBC jar both pass through before being packaged.
#
# The `verify-sha256 begin/end` block is extracted and run against local files
# (no network): a matching sha256 must pass, and a wrong one must exit non-zero
# with a mismatch message. Both the sha256sum path and the `shasum -a 256`
# fallback are covered. A final check asserts that every download in the
# script is verified with its pinned checksum.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

SRC="tools/distribution-drafts/linux-packages/build-linux-packages.sh"
BASH_BIN="$(command -v bash)"

TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

BLOCK="${TMP}/block.sh"
sed -n '/^# --- verify-sha256 begin/,/^# --- verify-sha256 end/p' "${SRC}" > "${BLOCK}"
if ! grep -q 'verify-sha256 end' "${BLOCK}"; then
  echo "FAIL: could not extract the verify-sha256 block from ${SRC}"
  exit 1
fi

fail=0

# A local stand-in for a downloaded jar, and its sha256 computed independently.
FILE="${TMP}/download.jar"
printf 'not really a jar\n' > "${FILE}"
if command -v sha256sum >/dev/null 2>&1; then
  GOOD=$(sha256sum "${FILE}" | cut -d' ' -f1)
else
  GOOD=$(shasum -a 256 "${FILE}" | cut -d' ' -f1)
fi
BAD="0000000000000000000000000000000000000000000000000000000000000000"

# PATH with only the tools the block needs; <hasher> picks sha256sum or shasum.
make_path() { # <dir> <hasher>
  mkdir -p "$1"
  local t
  for t in cut "$2"; do
    ln -s "$(command -v "${t}")" "$1/${t}"
  done
}

# run_verify <path-dir> <expected>  -> sets OUT (stdout+stderr), RC
run_verify() {
  OUT="$(env -i PATH="$1" "${BASH_BIN}" -euo pipefail -c \
    'source "$1"; verify_sha256 "$2" "$3" "Test jar"; echo verified' \
    _ "${BLOCK}" "${FILE}" "$2" 2>&1)"
  RC=$?
}

check() { # <description> <condition>
  if eval "$2"; then echo "ok   $1"; else
    echo "FAIL $1"; echo "     rc=${RC} out='${OUT}'"; fail=1
  fi
}

hashers=()
command -v sha256sum >/dev/null 2>&1 && hashers+=(sha256sum)
command -v shasum >/dev/null 2>&1 && hashers+=(shasum)
if [ "${#hashers[@]}" -eq 0 ]; then
  echo "FAIL: neither sha256sum nor shasum is available"
  exit 1
fi

for h in "${hashers[@]}"; do
  P="${TMP}/path-${h}"
  make_path "${P}" "${h}"
  run_verify "${P}" "${GOOD}"
  check "${h}: matching sha256 passes" '[ "${RC}" -eq 0 ] && [ "${OUT}" = verified ]'
  run_verify "${P}" "${BAD}"
  check "${h}: wrong sha256 fails closed" \
    '[ "${RC}" -ne 0 ] && [ "${OUT}" = "Test jar checksum mismatch: expected ${BAD}, got ${GOOD}" ]'
done

# Every jar the script downloads goes through the gate with its pinned value.
RC=-; OUT=
check "LuCLI jar is verified against LUCLI_JAR_SHA256" \
  "grep -q '^verify_sha256 \"\${BUILD_DIR}/build/lucli.jar\" \"\${LUCLI_JAR_SHA256}\"' '${SRC}'"
check "SQLite JDBC jar is verified against SQLITE_JDBC_SHA256" \
  "grep -q '^verify_sha256 \"\${BUILD_DIR}/build/sqlite-jdbc.jar\" \"\${SQLITE_JDBC_SHA256}\"' '${SRC}'"
check "SQLITE_JDBC_SHA256 is pinned to a sha256" \
  "grep -Eq '^SQLITE_JDBC_SHA256=\"[0-9a-f]{64}\"$' '${SRC}'"
check "one verify per download" \
  '[ "$(grep -c "^curl .* -o " "${SRC}")" -eq "$(grep -c "^verify_sha256 " "${SRC}")" ]'

if [ "${fail}" -ne 0 ]; then
  echo "Linux package checksum tests FAILED"
  exit 1
fi
echo "All Linux package checksum tests passed"
