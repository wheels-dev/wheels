#!/bin/bash
# Regenerates apt metadata for both `stable` and `bleeding-edge` distributions
# under dists/, then signs Release with GPG (detached → Release.gpg, inline →
# InRelease). Both signed forms are required: older apt clients read Release +
# Release.gpg, newer clients prefer InRelease.
#
# Inputs (env vars):
#   GPG_PASSPHRASE  — passphrase for the imported signing key
#   GPG_KEY_ID      — long-form key ID (set by the workflow after `gpg --import`)
#
# Idempotent: safe to run by hand against an existing tree to repair a torn
# release. Re-reads everything in pool/ and rewrites dists/ from scratch.

set -euo pipefail

if [ -z "${GPG_KEY_ID:-}" ]; then
  echo "::error::GPG_KEY_ID is unset — sign step would default to an arbitrary secret key."
  exit 1
fi

ARCHITECTURES="amd64"
COMPONENTS="main"
DISTRIBUTIONS="stable bleeding-edge"

# apt-ftparchive uses a config file to know where the pool lives. The same
# config drives both distributions — only the dist-name and the scan path
# change between invocations.
APT_CONF_TEMPLATE="templates/aptftparchive.conf"

if [ ! -f "$APT_CONF_TEMPLATE" ]; then
  echo "::error::Missing $APT_CONF_TEMPLATE — template is expected to ship in the bucket repo."
  exit 1
fi

for DIST in $DISTRIBUTIONS; do
  echo "── Regenerating dists/${DIST}/ ──"
  DIST_DIR="dists/${DIST}"
  mkdir -p "$DIST_DIR"
  # First publish for a brand-new channel: the pool dir may not exist yet.
  # apt-ftparchive aborts on a missing scan path, so create an empty pool
  # for now — it'll be backfilled by the first publish dispatch on that channel.
  mkdir -p "pool/${DIST}"

  for COMPONENT in $COMPONENTS; do
    for ARCH in $ARCHITECTURES; do
      BIN_DIR="${DIST_DIR}/${COMPONENT}/binary-${ARCH}"
      mkdir -p "$BIN_DIR"

      # apt-ftparchive packages <override> <pool-path> emits Packages on stdout.
      # We don't use an override file (no priority overrides for now).
      apt-ftparchive \
        --arch "$ARCH" \
        packages "pool/${DIST}" \
        > "${BIN_DIR}/Packages"

      gzip -9 --keep --force "${BIN_DIR}/Packages"
    done
  done

  # apt-ftparchive release emits the Release file metadata. The config template
  # provides Origin/Label/Codename/Description etc.; we override -o APT::FTPArchive::Release::Codename
  # per distribution so a single conf can drive both.
  apt-ftparchive \
    -c "$APT_CONF_TEMPLATE" \
    -o "APT::FTPArchive::Release::Codename=${DIST}" \
    -o "APT::FTPArchive::Release::Suite=${DIST}" \
    release "$DIST_DIR" \
    > "${DIST_DIR}/Release"

  # Detached signature → Release.gpg (legacy clients).
  rm -f "${DIST_DIR}/Release.gpg" "${DIST_DIR}/InRelease"
  gpg --batch --yes \
    --pinentry-mode loopback \
    --passphrase "${GPG_PASSPHRASE:-}" \
    --default-key "$GPG_KEY_ID" \
    --armor --detach-sign \
    --output "${DIST_DIR}/Release.gpg" \
    "${DIST_DIR}/Release"

  # Inline-signed Release → InRelease (modern clients).
  gpg --batch --yes \
    --pinentry-mode loopback \
    --passphrase "${GPG_PASSPHRASE:-}" \
    --default-key "$GPG_KEY_ID" \
    --clearsign \
    --output "${DIST_DIR}/InRelease" \
    "${DIST_DIR}/Release"

  echo "  ✓ Release + Release.gpg + InRelease written for ${DIST}"
done

echo "Done."
