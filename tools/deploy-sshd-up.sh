#!/usr/bin/env bash
# Start the dockerized sshd fixture used by deploy integration tests.
#
# Two openssh-server containers on ports 22022 + 22023 with a shared
# deterministic ed25519 key. See cli/lucli/tests/_fixtures/deploy/sshd/README.md.
set -euo pipefail

FIX_DIR="$(cd "$(dirname "$0")/.." && pwd)/cli/lucli/tests/_fixtures/deploy/sshd"

docker compose -f "$FIX_DIR/docker-compose.yml" up -d

# linuxserver/openssh-server runs cont-init.d before sshd binds the port.
# On a cold start (image pulled, network created) this can take 15-20s; on
# warm restarts it's ~3s. Poll both ports instead of a blind sleep.
wait_ssh_banner() {
  local port="$1"
  local attempts=0
  # Wait for sshd's "SSH-2.0-..." banner. TCP-only check (nc -z) isn't enough:
  # the port binds before sshd finishes host-key generation on first boot.
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

wait_ssh_banner 22022
wait_ssh_banner 22023
