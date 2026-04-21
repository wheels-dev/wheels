#!/bin/sh
# Runs inside the openssh-server container via /custom-cont-init.d. Installs
# the mocked docker + kamal-proxy shims into PATH so remote commands dispatched
# by `wheels deploy` land on them (rather than actually trying to run docker,
# which isn't present in the image).
#
# Placing shims in /usr/local/bin keeps them ahead of any future real binaries
# on PATH without clobbering anything.
set -e

# Copy rather than symlink — the source is a read-only bind mount, and some
# shells get confused resolving symlinks across bind mount boundaries.
cp /shims/docker-shim.sh /usr/local/bin/docker
cp /shims/docker-shim.sh /usr/local/bin/kamal-proxy
chmod 755 /usr/local/bin/docker /usr/local/bin/kamal-proxy

# Pre-create the log so the test can `cat` it even when zero invocations
# arrived (otherwise the assertion scripts would see a missing-file error
# rather than a clean "no invocations yet" empty string).
: > /tmp/docker-invocations.log
chmod 666 /tmp/docker-invocations.log
