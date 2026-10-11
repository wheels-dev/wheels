#!/usr/bin/env bash
# Start the dockerized sshd fixture used by deploy integration tests.
#
# Two openssh-server containers on ports 22022 + 22023 with a shared
# deterministic ed25519 key. See cli/lucli/tests/_fixtures/deploy/sshd/README.md.
set -euo pipefail

FIX_DIR="$(cd "$(dirname "$0")/.." && pwd)/cli/lucli/tests/_fixtures/deploy/sshd"

# The fixture is one Compose project shared by every checkout on the machine.
# When both containers are already up and answering, use them as they are:
# another checkout may be mid-run on them, and `up -d` from a different
# checkout could recreate them underneath it.
banner_ok() {
  bash -c "exec 3<>/dev/tcp/localhost/$1; read -t 2 line <&3; exec 3<&-; [[ \$line == SSH-* ]]" 2>/dev/null
}
running="$(docker compose -f "$FIX_DIR/docker-compose.yml" ps --status running --quiet 2>/dev/null | wc -l | tr -d ' ')"
if [[ "$running" == "2" ]] && banner_ok 22022 && banner_ok 22023; then
  echo "sshd fixture already running on 22022/22023; reusing it."
  exit 0
fi

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
