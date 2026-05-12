#!/bin/sh
# Mock `docker` binary for E2E deploy tests.
#
# Records every invocation (with args) to /tmp/docker-invocations.log so the
# test can assert the real `wheels deploy` flow dispatched the expected
# command sequence to this "remote" host.
#
# Keeps behavior minimal: emits deterministic stdout for the few invocations
# the deploy flow inspects (`docker image inspect`, `docker container inspect`),
# exits 0 for everything else. No real containers are ever started.

LOG=/tmp/docker-invocations.log
mkdir -p /tmp
printf '%s\n' "docker $*" >> "$LOG"

case "$1" in
  image)
    # `docker image inspect ... -f {{.Id}}` — deploy flow checks if image exists
    # before trying to pull. Return a fake sha so "already pulled" branches work.
    if [ "$2" = "inspect" ]; then
      echo "sha256:e2e0000000000000000000000000000000000000000000000000000000000000"
      exit 0
    fi
    ;;
  container)
    # `docker container inspect <name>` — used by rollback + "is it running?"
    # checks. Return JSON that looks healthy.
    if [ "$2" = "inspect" ]; then
      echo '[{"State":{"Status":"running"}}]'
      exit 0
    fi
    ;;
  ps)
    # No running containers by default — forces the "not running" branch.
    exit 0
    ;;
esac

exit 0
