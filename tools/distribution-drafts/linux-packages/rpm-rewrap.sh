#!/bin/bash
# rpm-rewrap.sh <nfpm-built.rpm> <output.rpm>
#
# Rebuilds an nfpm-built .rpm with rpmbuild so its header is what rpm expects
# (#3975). nfpm writes RPMTAG_ARCHIVESIZE / LONGARCHIVESIZE as the sum of the
# file contents instead of the size of the cpio archive (which adds the cpio
# headers and padding). rpm 4.19's rpm2cpio (Rocky 10) checks the bytes it wrote
# against that header and exits 1; rpm 4.16 (Rocky 9) doesn't check. A newer nfpm
# doesn't help (2.40.0 and 2.47.0 both do it, with any payload compression).
#
# nfpm stays the source of truth: everything the rebuilt package carries is read
# back from the nfpm rpm (payload, file modes and owners, requires, recommends,
# metadata), so nfpm-wheels*.yaml remains the only place to change the package.
# The rebuild runs in a rockylinux:9 container (rpm 4.16, where rpm2cpio reads
# the nfpm payload cleanly). The result is then checked:
#   - same files, modes, owners, sizes and digests, same requires/recommends and
#     metadata as the nfpm rpm (anything else fails the build);
#   - ARCHIVESIZE equals the cpio stream length;
#   - rpm2cpio | cpio -t exits 0 on Rocky 10 (rpm 4.19) and Rocky 9 (rpm 4.16).
#
# Needs docker. Unsupported nfpm features (install scripts, conflicts, obsoletes,
# config files) fail loudly rather than being dropped.

set -euo pipefail

IN="${1:?usage: rpm-rewrap.sh <nfpm.rpm> <out.rpm>}"
OUT="${2:?usage: rpm-rewrap.sh <nfpm.rpm> <out.rpm>}"
BUILD_IMAGE="${RPM_REWRAP_BUILD_IMAGE:-rockylinux/rockylinux:9}"
CHECK_IMAGES="${RPM_REWRAP_CHECK_IMAGES:-rockylinux/rockylinux:10 rockylinux/rockylinux:9}"

IN_ABS="$(cd "$(dirname "${IN}")" && pwd)/$(basename "${IN}")"
OUT_DIR_ABS="$(mkdir -p "$(dirname "${OUT}")" && cd "$(dirname "${OUT}")" && pwd)"
OUT_NAME="$(basename "${OUT}")"
WORK="$(mktemp -d)"
trap 'rm -rf "${WORK}"' EXIT
cp "${IN_ABS}" "${WORK}/in.rpm"

cat > "${WORK}/rewrap-inside.sh" <<'INSIDE_EOF'
#!/bin/bash
set -euo pipefail
dnf -q -y install rpm-build cpio >/dev/null
IN=/w/in.rpm
q() { rpm -qp --qf "$1" "${IN}"; }

# Refuse what this rewrap does not reproduce.
if [ -n "$(rpm -qp --scripts "${IN}")" ]; then echo "rpm-rewrap: install scripts are not supported" >&2; exit 1; fi
for tag in CONFLICTNAME OBSOLETENAME; do
  if [ "$(q "[%{${tag}}\n]" | grep -v '^(none)$' | grep -c . || true)" != "0" ]; then echo "rpm-rewrap: ${tag} is not supported" >&2; exit 1; fi
done
if q '[%{FILEFLAGS:fflags}\n]' | grep -q 'c'; then echo "rpm-rewrap: %config files are not supported" >&2; exit 1; fi

ROOT=/w/root
mkdir -p "${ROOT}"
# nfpm stores absolute paths in the payload; keep them under ${ROOT}.
(cd "${ROOT}" && rpm2cpio "${IN}" | cpio -idm --quiet --no-absolute-filenames)

SPEC=/w/rewrap.spec
{
  echo "Name: $(q '%{NAME}')"
  echo "Version: $(q '%{VERSION}')"
  echo "Release: $(q '%{RELEASE}')"
  echo "Summary: $(q '%{SUMMARY}')"
  echo "License: $(q '%{LICENSE}')"
  [ "$(q '%{URL}')" = "(none)" ] || echo "URL: $(q '%{URL}')"
  [ "$(q '%{GROUP}')" = "(none)" ] || echo "Group: $(q '%{GROUP}')"
  [ "$(q '%{VENDOR}')" = "(none)" ] || echo "Vendor: $(q '%{VENDOR}')"
  [ "$(q '%{PACKAGER}')" = "(none)" ] || echo "Packager: $(q '%{PACKAGER}')"
  echo "BuildArch: $(q '%{ARCH}')"
  # nfpm adds no automatic dependencies; rpmbuild must not either.
  echo "AutoReqProv: no"
  rpm -qp --requires "${IN}" | grep -v '^rpmlib(' | sed 's/^/Requires: /' || true
  rpm -qp --recommends "${IN}" | sed 's/^/Recommends: /' || true
  # Payload the same way nfpm does (gzip), so the package still installs on older rpm.
  echo "%define _binary_payload w9.gzdio"
  echo "%define __os_install_post %{nil}"
  echo "%define __jar_repack 0"
  echo "%define _build_id_links none"
  echo "%description"
  q '%{DESCRIPTION}'; echo
  echo "%install"
  echo "mkdir -p %{buildroot}"
  echo "cp -a ${ROOT}/. %{buildroot}/"
  echo "%files"
  # One line per path with its exact mode and owner; directories as %dir.
  q '[%{FILEMODES:perms}\t%{FILEMODES:octal}\t%{FILEUSERNAME}\t%{FILEGROUPNAME}\t%{FILENAMES}\n]' |
    while IFS=$'\t' read -r perms octal user group path; do
      mode=$(printf '%o' $(( 8#${octal} & 07777 )))
      case "${perms}" in
        d*) printf '%%dir %%attr(%s,%s,%s) "%s"\n' "${mode}" "${user}" "${group}" "${path}" ;;
        *)  printf '%%attr(%s,%s,%s) "%s"\n' "${mode}" "${user}" "${group}" "${path}" ;;
      esac
    done
} > "${SPEC}"

rpmbuild -bb --quiet --define "_topdir /w/rpmbuild" "${SPEC}" >/w/rpmbuild.log 2>&1 || { tail -30 /w/rpmbuild.log >&2; exit 1; }
OUTRPM="$(ls /w/rpmbuild/RPMS/*/*.rpm)"

# The rebuilt package must carry exactly what the nfpm one did.
# A directory's recorded size is a filesystem artifact (nfpm writes 4096,
# rpmbuild what the build root reports), so it is not compared.
fp() { rpm -qp --qf '[%{FILEMODES:perms} %{FILEMODES:octal} %{FILEUSERNAME} %{FILEGROUPNAME} %{FILESIZES} %{FILEDIGESTS} %{FILENAMES}\n]' "$1" | awk '{ if (substr($1, 1, 1) == "d") $5 = "-"; print }' | sort; }
meta() { rpm -qp --qf '%{NAME}|%{VERSION}|%{RELEASE}|%{ARCH}|%{SUMMARY}|%{LICENSE}|%{URL}|%{GROUP}|%{VENDOR}\n' "$1"; }
deps() { { rpm -qp --requires "$1" | grep -v '^rpmlib(' || true; rpm -qp --recommends "$1" | sed 's/^/recommends: /'; } | sort; }
for f in fp meta deps; do
  if ! diff <("${f}" "${IN}") <("${f}" "${OUTRPM}") >/w/diff.txt; then
    echo "rpm-rewrap: rebuilt package differs from the nfpm one (${f}):" >&2; head -20 /w/diff.txt >&2; exit 1
  fi
done
ARCHIVE="$(rpm -qp --qf '%{LONGARCHIVESIZE}' "${OUTRPM}")"
STREAM="$(rpm2cpio "${OUTRPM}" | wc -c)"
[ "${ARCHIVE}" = "${STREAM}" ] || { echo "rpm-rewrap: ARCHIVESIZE ${ARCHIVE} != cpio stream ${STREAM}" >&2; exit 1; }
cp "${OUTRPM}" /w/out.rpm
echo "rpm-rewrap: rebuilt $(basename "${OUTRPM}") (archive ${ARCHIVE} bytes = stream)"
INSIDE_EOF

docker run --rm -v "${WORK}:/w" "${BUILD_IMAGE}" bash /w/rewrap-inside.sh

# rpm2cpio | cpio -t must exit 0 on each target rpm version.
for image in ${CHECK_IMAGES}; do
  docker run --rm --network none -v "${WORK}:/w:ro" "${image}" bash -c '
    set -o pipefail
    command -v cpio >/dev/null || { echo "rpm-rewrap: no cpio in '"${image}"'; checking rpm2cpio alone" >&2; rpm2cpio /w/out.rpm >/dev/null; exit $?; }
    rpm2cpio /w/out.rpm | cpio -t --quiet >/dev/null' \
    || { echo "rpm-rewrap: rpm2cpio | cpio -t failed on ${image}" >&2; exit 1; }
  echo "rpm-rewrap: rpm2cpio OK on ${image}"
done

cp "${WORK}/out.rpm" "${OUT_DIR_ABS}/${OUT_NAME}"
