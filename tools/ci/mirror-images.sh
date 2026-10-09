#!/usr/bin/env bash
# Copy Docker Hub images to the GHCR mirror, unchanged (multi-arch indexes and
# digests preserved), for .github/workflows/mirror-images.yml.
#
#   bash tools/ci/mirror-images.sh list            # print the config's references as JSON
#   bash tools/ci/mirror-images.sh map  <ref>      # print the mirror reference for <ref>
#   bash tools/ci/mirror-images.sh copy <ref>      # copy <ref> with crane (must be logged in to ghcr.io)
#
# MIRROR_CONFIG overrides tools/ci/mirror-images.txt; MIRROR_PREFIX overrides
# ghcr.io/wheels-dev/mirror. `copy` skips the pull when the mirror already holds
# the source's digest: a HEAD for the digest doesn't count toward Docker Hub's
# pull limit, a manifest GET does.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${MIRROR_CONFIG:-${SCRIPT_DIR}/mirror-images.txt}"
PREFIX="${MIRROR_PREFIX:-ghcr.io/wheels-dev/mirror}"

# A reference is name[:tag][@sha256:hex] with a Docker Hub name: no registry
# host in front (a first segment with a dot or colon is one).
parse() {
  local ref="$1" rest
  NAME="" TAG="" DIGEST=""
  case "$ref" in
    *@sha256:*) DIGEST="${ref##*@}"; rest="${ref%@*}" ;;
    *@*) echo "unsupported digest in ${ref}" >&2; return 1 ;;
    *) rest="$ref" ;;
  esac
  if [[ "${rest##*/}" == *:* ]]; then
    TAG="${rest##*:}"; NAME="${rest%:*}"
  else
    NAME="$rest"
  fi
  if [[ "${NAME%%/*}" == *[.:]* && "$NAME" == */* ]]; then
    echo "not a Docker Hub reference: ${ref}" >&2; return 1
  fi
  if [[ -z "$NAME" || ( -z "$TAG" && -z "$DIGEST" ) ]]; then
    echo "pin a tag or digest: ${ref}" >&2; return 1
  fi
  if [[ -n "$DIGEST" && ! "$DIGEST" =~ ^sha256:[0-9a-f]{64}$ ]]; then
    echo "malformed digest in ${ref}" >&2; return 1
  fi
}

# The reference to pull from the mirror, keeping the tag and digest as written.
map() {
  parse "$1"
  local out="${PREFIX}/${NAME}"
  [[ -n "$TAG" ]] && out+=":${TAG}"
  [[ -n "$DIGEST" ]] && out+="@${DIGEST}"
  printf '%s\n' "$out"
}

refs() {
  grep -vE '^[[:space:]]*(#|$)' "$CONFIG" | sed -E 's/[[:space:]]+$//'
}

list() {
  local first=1 ref
  printf '['
  while IFS= read -r ref; do
    parse "$ref"
    [[ $first -eq 1 ]] || printf ','
    printf '"%s"' "$ref"
    first=0
  done < <(refs)
  printf ']\n'
}

# Retries cover Docker Hub's 429s and short outages: 4 tries over ~7 minutes.
retry() {
  local attempt=1 delay=30
  until "$@"; do
    if [[ $attempt -ge 4 ]]; then
      echo "::error::failed after ${attempt} attempts: $*" >&2
      return 1
    fi
    echo "attempt ${attempt} failed; retrying in ${delay}s" >&2
    sleep "$delay"
    attempt=$((attempt + 1)) delay=$((delay * 2))
  done
}

copy() {
  parse "$1"
  local src="docker.io/${NAME}" dst="${PREFIX}/${NAME}" want have
  if [[ -n "$DIGEST" ]]; then
    # A digest pin: copy those exact bytes under a tag that keeps them listed.
    src+="@${DIGEST}" dst+=":${DIGEST/:/-}"
    want="$DIGEST"
  else
    src+=":${TAG}" dst+=":${TAG}"
    want="$(retry crane digest "$src")"
  fi
  have="$(crane digest "$dst" 2>/dev/null || true)"
  if [[ "$have" == "$want" ]]; then
    echo "up to date: ${dst} (${want})"
    return 0
  fi
  echo "copying ${src} -> ${dst}"
  retry crane copy "$src" "$dst"
  have="$(crane digest "$dst")"
  if [[ "$have" != "$want" ]]; then
    # A floating tag can move between the HEAD and the copy; the copy is still
    # a faithful snapshot of the tag, so report it rather than fail.
    echo "::notice::${dst} is ${have}; the source tag pointed at ${want} before the copy"
  fi
  echo "mirrored ${dst} (${have})"
}

case "${1:-}" in
  list) list ;;
  map)  map "${2:?usage: map <ref>}" ;;
  copy) copy "${2:?usage: copy <ref>}" ;;
  *) sed -n '2,12p' "$0" >&2; exit 2 ;;
esac
