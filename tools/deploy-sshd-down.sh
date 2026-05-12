#!/usr/bin/env bash
# Stop the dockerized sshd fixture used by deploy integration tests.
set -euo pipefail

FIX_DIR="$(cd "$(dirname "$0")/.." && pwd)/cli/lucli/tests/_fixtures/deploy/sshd"

docker compose -f "$FIX_DIR/docker-compose.yml" down
