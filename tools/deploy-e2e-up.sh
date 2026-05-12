#!/usr/bin/env bash
# Start the E2E deploy fixture: a single openssh-server container on port
# 22024 that mocks `docker` and `kamal-proxy` by recording invocations to
# /tmp/docker-invocations.log inside the container.
#
# Used by cli/lucli/tests/specs/deploy/integration/E2EDeploySpec.cfc when
# the env var DEPLOY_E2E=1 is set. Without that flag the spec skips and
# this script is never invoked.
#
# Paths resolve relative to the script location so this works regardless
# of the caller's cwd. Modeled on tools/deploy-sshd-up.sh.
set -euo pipefail

FIX_DIR="$(cd "$(dirname "$0")/.." && pwd)/cli/lucli/tests/_fixtures/deploy/e2e"

docker compose -f "$FIX_DIR/docker-compose.yml" up -d

# Poll for the sshd banner on 22024. openssh-server's s6-overlay runs
# /custom-cont-init.d BEFORE sshd binds, so if we see the banner the shims
# are already installed.
wait_ssh_banner() {
  local port="$1"
  local attempts=0
  while (( attempts < 60 )); do
    if bash -c "exec 3<>/dev/tcp/localhost/$port; read -t 2 line <&3; exec 3<&-; [[ \$line == SSH-* ]]" 2>/dev/null; then
      return 0
    fi
    sleep 1
    attempts=$((attempts + 1))
  done
  echo "sshd on port $port did not advertise an SSH banner within 60s" >&2
  return 1
}

wait_ssh_banner 22024
