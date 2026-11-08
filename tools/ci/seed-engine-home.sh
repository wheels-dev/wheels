#!/usr/bin/env bash
#
# Seed the host engine home that compose.ci.yml bind-mounts over the image's
# warm engine home.
#
# compose.ci.yml reverses the per-engine named volume to a host bind so CI can
# seed Oracle's JDBC jar and collect cold-start logs from ./.engine/<engine>.
# An empty host directory masks the warm engine baked into the image, so the
# container re-downloads the engine at startup — exactly the #4691 failure.
# This copies the image's warm home into the host path before `up`.
#
# Usage: tools/ci/seed-engine-home.sh <engine>
# COMPOSE_FILE must include compose.ci.yml; the image tag comes from compose.
set -euo pipefail

engine="${1:?usage: tools/ci/seed-engine-home.sh <engine>}"
config=$(docker compose config --format json "$engine")

# Only engines whose compose.ci.yml override bind-mounts .engine/<engine> need
# seeding (Adobe + BoxLang). Lucee's engine home stays inside the image and is
# not masked by any bind, so copy nothing for it.
if ! jq -e --arg s "$engine" --arg t "/wheels-test-suite/.engine/${engine}" \
    '.services[$s].volumes[]? | select(.target == $t)' <<<"$config" >/dev/null; then
  echo "No .engine/${engine} bind for ${engine}; nothing to seed"
  exit 0
fi

image=$(jq -er --arg s "$engine" '.services[$s].image' <<<"$config")
dest=".engine/${engine}"
mkdir -p "$dest"

docker run --rm --entrypoint /bin/sh -v "$PWD/${dest}:/seed" "$image" -c "
  if [ -d '/wheels-test-suite/.engine/${engine}' ]; then
    cp -a '/wheels-test-suite/.engine/${engine}/.' /seed/
    echo 'Seeded warm engine home from the image'
  elif [ -d /usr/local/lib/serverHome ]; then
    # Images built before the Dockerfiles copied server.json warmed
    # CommandBox's default home instead; it is still a complete server home.
    cp -a /usr/local/lib/serverHome/. /seed/
    echo 'Seeded warm server home from the image (legacy layout)'
  else
    echo 'No warm engine home in the image; nothing to seed'
  fi
"
