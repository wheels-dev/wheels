#!/usr/bin/env bash
# Stop the E2E deploy fixture started by deploy-e2e-up.sh.
set -euo pipefail

FIX_DIR="$(cd "$(dirname "$0")/.." && pwd)/cli/lucli/tests/_fixtures/deploy/e2e"

docker compose -f "$FIX_DIR/docker-compose.yml" down
