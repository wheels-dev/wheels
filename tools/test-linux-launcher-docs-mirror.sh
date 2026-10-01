#!/usr/bin/env bash
# Exercises the offline-docs mirror in the /usr/bin/wheels launcher that
# tools/distribution-drafts/linux-packages/build-linux-packages.sh generates
# for the .deb and .rpm packages. The launcher used to delete and re-copy
# ./public/wheels-docs on every command run from an app root (hardlinked to the
# shared ~/.wheels/docs cache), and a failed copy aborted the user's command.
#
# The block between its `docs-mirror begin/end` markers is extracted and run
# under `bash -euo pipefail` inside a temp app root, with a fake docs cache as
# DOCS_DST. A line after the block proves the rest of the launcher still runs.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

SRC="tools/distribution-drafts/linux-packages/build-linux-packages.sh"
BASH_BIN="$(command -v bash)"

TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

BLOCK="${TMP}/block.sh"
sed -n '/^# --- docs-mirror begin/,/^# --- docs-mirror end/p' "${SRC}" > "${BLOCK}"
if ! grep -q 'docs-mirror end' "${BLOCK}"; then
  echo "FAIL: could not extract the docs-mirror block from ${SRC}"
  exit 1
fi

fail=0
n=0

# new_case: fresh app root + docs cache at version 1.0.0.
new_case() {
  n=$((n + 1))
  CASE="${TMP}/case${n}"
  APP="${CASE}/app"
  CACHE="${CASE}/cache"
  mkdir -p "${APP}/vendor/wheels" "${APP}/public" "${CASE}/bin"
  echo '{}' > "${APP}/vendor/wheels/wheels.json"
  make_cache 1.0.0
}

# make_cache <version>: the unpacked bundle for <version> at ${CACHE}/<version>.
make_cache() {
  mkdir -p "${CACHE}/$1/guides"
  echo "{\"version\":\"$1\"}" > "${CACHE}/$1/manifest.json"
  echo "guide $1" > "${CACHE}/$1/guides/index.html"
}

# run_case <version>  -> sets RC, ERR, AFTER
run_case() {
  {
    printf 'INSTALLED_VERSION=%q\nDOCS_DST=%q\n' "$1" "${CACHE}/$1"
    cat "${BLOCK}"
    printf 'echo after-block\n'
  } > "${CASE}/launcher.sh"
  AFTER="$(cd "${APP}" && PATH="${CASE}/bin:${PATH}" "${BASH_BIN}" -euo pipefail "${CASE}/launcher.sh" 2>"${CASE}/stderr")"
  RC=$?
  ERR="$(cat "${CASE}/stderr")"
}

check() { # <description> <condition-result 0/1>
  if [ "$2" -eq 0 ]; then echo "ok   $1"; else
    echo "FAIL $1"; echo "     rc=${RC} after='${AFTER}'"; echo "     stderr: ${ERR}"; fail=1
  fi
}
is() { [ "$1" = "$2" ]; echo $?; }
has() { case "$1" in *"$2"*) echo 0 ;; *) echo 1 ;; esac; }
yes() { if "$@"; then echo 0; else echo 1; fi; }

MIRROR_REL="public/wheels-docs"

# 1. First run creates the mirror.
new_case
run_case 1.0.0
M="${APP}/${MIRROR_REL}"
check "first run creates the mirror" "$(yes [ -f "${M}/guides/index.html" ])"
check "first run exits 0 and the launcher continues" "$(is "${RC}:${AFTER}" "0:after-block")"
check "first run prints nothing" "$(is "${ERR}" "")"

# 2. The mirror is a copy, not hardlinked to the shared cache: an edit in the
#    app must not reach ~/.wheels/docs.
check "mirror files are not hardlinks of the cache" \
  "$(yes [ ! "${M}/guides/index.html" -ef "${CACHE}/1.0.0/guides/index.html" ])"
echo "edited" > "${M}/guides/index.html" 2>/dev/null || true
check "editing the mirror leaves the cache intact" \
  "$(is "$(cat "${CACHE}/1.0.0/guides/index.html")" "guide 1.0.0")"

# 3. A second run at the same version (identical manifest.json) leaves the
#    mirror in place: a sentinel written into it survives.
echo keep > "${M}/sentinel"
run_case 1.0.0
check "same-version rerun keeps the existing mirror" "$(yes [ -f "${M}/sentinel" ])"
check "same-version rerun exits 0 and continues" "$(is "${RC}:${AFTER}" "0:after-block")"

# 4. A new docs version refreshes the mirror.
make_cache 2.0.0
run_case 2.0.0
check "version change refreshes the mirror" "$(is "$(cat "${M}/guides/index.html")" "guide 2.0.0")"
check "version change drops the old mirror's files" "$(yes [ ! -e "${M}/sentinel" ])"
check "version change leaves no temp dirs in public/" \
  "$(is "$(cd "${APP}/public" && ls -A)" "wheels-docs")"

# 5. A public/wheels-docs that is not a docs mirror (no manifest.json) is the
#    user's own: left alone on the same version and after an upgrade.
new_case
mkdir -p "${APP}/${MIRROR_REL}"
echo mine > "${APP}/${MIRROR_REL}/notes.txt"
run_case 1.0.0
check "user-owned public/wheels-docs is untouched" \
  "$(is "$(ls -A "${APP}/${MIRROR_REL}"):$(cat "${APP}/${MIRROR_REL}/notes.txt")" "notes.txt:mine")"
make_cache 2.0.0
run_case 2.0.0
check "user-owned public/wheels-docs is untouched after an upgrade" \
  "$(is "$(ls -A "${APP}/${MIRROR_REL}")" "notes.txt")"

# 5b. A mirror made by the old wrapper (or `wheels docs`): manifest.json, no
#     other marker, hardlinked to the cache. Same version: left as-is.
new_case
cp -R -l "${CACHE}/1.0.0" "${APP}/${MIRROR_REL}"
M="${APP}/${MIRROR_REL}"
check "setup: old-wrapper mirror is hardlinked to the cache" \
  "$(yes [ "${M}/guides/index.html" -ef "${CACHE}/1.0.0/guides/index.html" ])"
echo keep > "${M}/sentinel"
run_case 1.0.0
check "same-version old-wrapper mirror is left as-is" \
  "$([ -f "${M}/sentinel" ] && [ "${M}/guides/index.html" -ef "${CACHE}/1.0.0/guides/index.html" ]; echo $?)"
check "same-version old-wrapper mirror: exits 0 and continues" "$(is "${RC}:${AFTER}" "0:after-block")"

# 5c. ...and a package upgrade refreshes it (plus clears temp dirs a killed
#     run left behind), without touching the old version's cache.
make_cache 2.0.0
mkdir -p "${APP}/public/.wheels-docs-new.99999/x" "${APP}/public/.wheels-docs-old.99999/x"
run_case 2.0.0
check "old-wrapper mirror is refreshed on a version change" \
  "$(is "$(cat "${M}/guides/index.html")" "guide 2.0.0")"
check "refreshed mirror is not hardlinked to the cache" \
  "$(yes [ ! "${M}/guides/index.html" -ef "${CACHE}/2.0.0/guides/index.html" ])"
check "replacing the hardlinked mirror leaves the old cache intact" \
  "$(is "$(cat "${CACHE}/1.0.0/guides/index.html"):$(cat "${CACHE}/1.0.0/manifest.json")" \
    'guide 1.0.0:{"version":"1.0.0"}')"
check "leftover temp dirs from killed runs are cleared" \
  "$(is "$(cd "${APP}/public" && ls -A)" "wheels-docs")"

# 6. A copy failure warns on stderr but does not abort the user's command.
new_case
printf '#!%s\nexit 1\n' "${BASH_BIN}" > "${CASE}/bin/cp"
chmod +x "${CASE}/bin/cp"
run_case 1.0.0
check "copy failure exits 0 and the launcher continues" "$(is "${RC}:${AFTER}" "0:after-block")"
check "copy failure prints a warning" "$(has "${ERR}" "could not copy the offline docs")"
check "copy failure leaves public/ clean" "$(is "$(ls -A "${APP}/public")" "")"

# 7. A failed refresh keeps the previous mirror rather than deleting it.
new_case
run_case 1.0.0
make_cache 2.0.0
printf '#!%s\nexit 1\n' "${BASH_BIN}" > "${CASE}/bin/cp"
chmod +x "${CASE}/bin/cp"
run_case 2.0.0
check "failed refresh keeps the previous mirror" \
  "$(is "$(cat "${APP}/${MIRROR_REL}/guides/index.html" 2>/dev/null)" "guide 1.0.0")"
check "failed refresh exits 0 and continues" "$(is "${RC}:${AFTER}" "0:after-block")"

# 8. Outside an app root nothing is created.
new_case
rm -rf "${APP}/vendor"
run_case 1.0.0
check "no mirror outside an app root" "$(yes [ ! -e "${APP}/${MIRROR_REL}" ])"

# 9. The generated wrapper as a whole still parses.
sed -n "/^cat > \"\${BUILD_DIR}\/build\/wrapper.sh\" <<'WRAPPER_EOF'/,/^WRAPPER_EOF/p" "${SRC}" \
  | sed '1d;$d' > "${TMP}/wrapper.sh"
RC=0; AFTER=""; ERR="$("${BASH_BIN}" -n "${TMP}/wrapper.sh" 2>&1)" || RC=$?
check "generated wrapper passes bash -n" "$(is "${RC}" "0")"
[ -s "${TMP}/wrapper.sh" ] || { echo "FAIL could not extract the wrapper heredoc"; fail=1; }

exit $fail
