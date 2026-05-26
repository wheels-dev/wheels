#!/bin/bash
# Regenerates yum metadata for both `stable` and `bleeding-edge` channels
# under the bucket-repo root, then signs `repomd.xml` with GPG (detached →
# `repomd.xml.asc`).
#
# Inputs (env vars):
#   GPG_PASSPHRASE  — passphrase for the imported signing key
#   GPG_KEY_ID      — long-form key ID (set by the workflow after `gpg --import`)
#
# Idempotent: safe to run by hand against an existing tree. `createrepo_c`
# rebuilds the metadata from the current state of <channel>/packages/, so
# stale entries get cleared automatically.

set -euo pipefail

if [ -z "${GPG_KEY_ID:-}" ]; then
  echo "::error::GPG_KEY_ID is unset — sign step would default to an arbitrary secret key."
  exit 1
fi

CHANNELS="stable bleeding-edge"

# nfpm produces unsigned .rpm files. The wheels.repo / wheels-be.repo files
# served by this bucket set gpgcheck=1, so dnf REJECTS unsigned packages with
# "Package is not signed: GPG check FAILED". Sign every .rpm in the channel's
# packages/ dir before regenerating metadata — rpm --addsign embeds the
# signature in the .rpm header, which createrepo_c then records in the
# primary.xml.gz hash chain. Re-runs are idempotent (rpm --addsign replaces
# any existing signature).
#
# Requires rpm-sign (Fedora/RHEL) for the rpm command itself.
#
# Why a custom %__gpg_sign_cmd: in CI there is no TTY, so the default
# rpm-build sign command (`gpg ... --pinentry-mode loopback --passphrase-fd 3 ...`)
# either fails to open /dev/tty or has no fd 3 wired up. Override with an
# explicit `--passphrase-file` pointing at a chmod-600 file we control. The
# file lives under $RUNNER_TEMP (or /tmp as a fallback), is unreadable by
# other users, and is wiped at the end of the script.
PASS_FILE="${RUNNER_TEMP:-/tmp}/wheels-rpm-pass.$$"
umask 077
printf '%s' "${GPG_PASSPHRASE:-}" > "$PASS_FILE"
trap 'rm -f "$PASS_FILE"' EXIT

cat > ~/.rpmmacros <<RPMMACROS
%_signature gpg
%_gpg_name ${GPG_KEY_ID}
%_gpg_path ${GNUPGHOME:-${HOME}/.gnupg}
%__gpg $(command -v gpg)
%__gpg_sign_cmd %{__gpg} --batch --no-armor --no-secmem-warning --pinentry-mode loopback --passphrase-file ${PASS_FILE} --local-user "%{_gpg_name}" --sign --detach-sign --output %{__signature_filename} %{__plaintext_filename}
RPMMACROS

# Also configure gpg-agent to allow loopback (belt-and-braces — the macro
# above is the load-bearing piece, but other gpg invocations later in the
# script — repomd.xml signing, public-key export — still rely on the agent).
mkdir -p "${GNUPGHOME:-${HOME}/.gnupg}"
cat > "${GNUPGHOME:-${HOME}/.gnupg}/gpg-agent.conf" <<GPGAGENT
allow-loopback-pinentry
GPGAGENT
cat > "${GNUPGHOME:-${HOME}/.gnupg}/gpg.conf" <<GPGCONF
use-agent
pinentry-mode loopback
GPGCONF
gpg-connect-agent reloadagent /bye >/dev/null 2>&1 || true

for CHANNEL in $CHANNELS; do
  CHANNEL_DIR="$CHANNEL"
  PKG_DIR="${CHANNEL_DIR}/packages"

  # Skip channels that don't have any packages yet (first run after bucket creation).
  if [ ! -d "$PKG_DIR" ] || [ -z "$(ls -A "$PKG_DIR" 2>/dev/null | grep -E '\.rpm$' || true)" ]; then
    echo "── Skipping ${CHANNEL} (no .rpm files in ${PKG_DIR}) ──"
    continue
  fi

  echo "── Signing .rpm files in ${PKG_DIR}/ ──"
  for rpm_file in "${PKG_DIR}"/*.rpm; do
    [ -f "$rpm_file" ] || continue
    # --addsign with the macro setup above. Passphrase via env (rpm reads
    # $GNUPGHOME/gpg.conf which sets pinentry-mode loopback).
    rpm --addsign "$rpm_file" >/dev/null
    echo "  ✓ signed $(basename "$rpm_file")"
  done

  echo "── Regenerating ${CHANNEL_DIR}/repodata/ ──"

  # createrepo_c scans <channel>/packages/ and writes <channel>/repodata/.
  # --update reuses existing metadata where possible (faster on large pools).
  createrepo_c \
    --update \
    --workers 2 \
    --general-compress-type=gz \
    --xz \
    "$CHANNEL_DIR"

  REPOMD="${CHANNEL_DIR}/repodata/repomd.xml"
  if [ ! -f "$REPOMD" ]; then
    echo "::error::createrepo_c didn't produce ${REPOMD}"
    exit 1
  fi

  # Detached signature on repomd.xml is the trust root — package checksums
  # live inside the metadata, so signing repomd.xml signs the whole tree
  # transitively.
  rm -f "${REPOMD}.asc"
  gpg --batch --yes \
    --pinentry-mode loopback \
    --passphrase "${GPG_PASSPHRASE:-}" \
    --default-key "$GPG_KEY_ID" \
    --armor --detach-sign \
    --output "${REPOMD}.asc" \
    "$REPOMD"

  # Some dnf clients fetch repomd.xml.key alongside repomd.xml.asc on first
  # refresh. Export the public key there so installs don't fail with
  # "GPG key not available" on hosts that don't pre-trust the key.
  gpg --armor --export "$GPG_KEY_ID" > "${CHANNEL_DIR}/repodata/repomd.xml.key"

  echo "  ✓ repodata + repomd.xml.asc + repomd.xml.key written for ${CHANNEL}"
done

echo "Done."
