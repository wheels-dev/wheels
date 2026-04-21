#!/usr/bin/env bash
set -euo pipefail
FIX_DIR="$(cd "$(dirname "$0")/.." && pwd)/cli/lucli/tests/_fixtures/deploy/sshd"
docker compose -f "$FIX_DIR/docker-compose.yml" up -d
sleep 5
