#!/usr/bin/env bash
#
# Build an engine image through the Actions buildx cache and seed the host
# engine home before `up`.
#
# The cache scope is `<engine>-<hash of its Dockerfile + ForgeBox manifests>`,
# identical to the scope compat-matrix populates, so cold-start-smoke and
# smoke-env restore the same warm image instead of re-downloading the engine
# from downloads.ortussolutions.com (#4691). The image is cached; the container
# and its engine volume/bind are still created fresh, so cold-start semantics
# are unchanged.
#
# Usage: tools/ci/build-engine-image.sh <engine>
# Requires docker/setup-buildx-action in the workflow (type=gha needs the
# docker-container driver). COMPOSE_FILE layers compose.ci.yml as usual.
set -euo pipefail

engine="${1:?usage: tools/ci/build-engine-image.sh <engine>}"
config=$(docker compose config --format json "$engine")
image=$(jq -er --arg s "$engine" '.services[$s].image' <<<"$config")
dockerfile=$(jq -er --arg s "$engine" '.services[$s].build.dockerfile' <<<"$config")
context=$(jq -er --arg s "$engine" '.services[$s].build.context // "."' <<<"$config")
dockerfile_path="$context/${dockerfile#./}"
engine_dir=$(dirname "$dockerfile_path")

# The cache scope covers the pinned engine version and base digest in the
# Dockerfile plus the ForgeBox manifest, so a version bump starts a fresh scope.
cache_files=("$dockerfile_path")
for f in box.json server.json CFConfig.json; do
  if [ -f "${engine_dir}/${f}" ]; then
    cache_files+=("${engine_dir}/${f}")
  fi
done
cache_key=$(cat "${cache_files[@]}" | sha256sum | cut -c1-16)
scope="${engine}-${cache_key}"

echo "Building ${engine}: ${image} from ${dockerfile_path} (cache scope ${scope})"
max_attempts="${MAX_ATTEMPTS:-3}"
attempt=1
cache_args=("--cache-from" "type=gha,scope=${scope}" "--cache-to" "type=gha,mode=max,scope=${scope}")
while true; do
  if docker buildx build --load --tag "$image" --file "$dockerfile_path" "${cache_args[@]}" "$context"; then
    break
  fi
  if [ "$attempt" -ge "$max_attempts" ]; then
    echo "::error::${engine} image build failed after ${max_attempts} attempts (engine/ForgeBox download; see the named URL and HTTP status in the build log above)"
    exit 1
  fi
  echo "::warning::Build attempt ${attempt} failed — retrying with --no-cache so a poisoned cache entry cannot brick every attempt"
  attempt=$((attempt + 1))
  cache_args=("--no-cache")
  sleep 30
done

bash "$(dirname "$0")/seed-engine-home.sh" "$engine"
