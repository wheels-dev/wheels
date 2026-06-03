#!/bin/bash
# Regenerates apt metadata for the selected distributions (default: `stable` +
# `bleeding-edge`) under dists/, then signs Release with GPG (detached →
# Release.gpg, inline → InRelease). Both signed forms are required: older apt
# clients read Release + Release.gpg, newer clients prefer InRelease.
#
# Inputs (env vars):
#   GPG_PASSPHRASE  — passphrase for the imported signing key
#   GPG_KEY_ID      — long-form key ID (set by the workflow after `gpg --import`)
#   CHANNELS        — space-separated channels to (re)generate. Defaults to
#                     "stable bleeding-edge". The release workflow sets this to
#                     the single dispatched channel so a run only ever rewrites
#                     the dist whose pool it actually synced (see wheels#2838).
#
# Idempotent: safe to run by hand against an existing tree to repair a torn
# release. Re-reads everything in pool/ for the selected CHANNELS and rewrites
# their dists/ from scratch — so the pool for each selected channel MUST be
# present locally first, otherwise that channel's index is emitted empty.

set -euo pipefail

if [ -z "${GPG_KEY_ID:-}" ]; then
  echo "::error::GPG_KEY_ID is unset — sign step would default to an arbitrary secret key."
  exit 1
fi

ARCHITECTURES="amd64"
COMPONENTS="main"
# Only regenerate the channels we were asked to. The workflow syncs just the
# dispatched channel's pool (pool/<channel>/), so regenerating a channel whose
# pool isn't present would scan an empty dir, emit an empty Packages, and the
# upload would clobber that channel's index on R2. Defaulting to both preserves
# the by-hand full-tree repair path (which must sync both pools first). #2838.
DISTRIBUTIONS="${CHANNELS:-stable bleeding-edge}"

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
