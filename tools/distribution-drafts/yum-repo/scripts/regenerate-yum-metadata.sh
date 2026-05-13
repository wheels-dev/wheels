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

for CHANNEL in $CHANNELS; do
  CHANNEL_DIR="$CHANNEL"
  PKG_DIR="${CHANNEL_DIR}/packages"

  # Skip channels that don't have any packages yet (first run after bucket creation).
  if [ ! -d "$PKG_DIR" ] || [ -z "$(ls -A "$PKG_DIR" 2>/dev/null | grep -E '\.rpm$' || true)" ]; then
    echo "── Skipping ${CHANNEL} (no .rpm files in ${PKG_DIR}) ──"
    continue
  fi

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
