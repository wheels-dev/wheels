#!/usr/bin/env bash
# Aspirational command-string parity vs. Ruby Kamal.
#
# CURRENT STATE: This script is a placeholder.
#
# Ruby Kamal 2.8.2 has no reliable --dry-run flag. `KAMAL_DEBUG=1 kamal deploy`
# logs commands BUT also opens SSH connections and fails on missing targets,
# so it's not a clean diff source.
#
# Two realistic paths to enable this script:
#
#   1. Upstream: Kamal adds a genuine --dry-run flag that prints the command
#      plan without opening SSH. This has been discussed in the Kamal repo
#      but not shipped as of 2.8.2 (2026-04).
#
#   2. Local: write a small SSHKit capture shim (Ruby) that monkey-patches
#      the connection layer to record commands instead of running them, feed
#      our fixtures through it, diff against tools/deploy-dry-run-normalize.py
#      applied to wheels deploy --dry-run output.
#
# Until one of those lands, run tools/deploy-config-diff.sh for config-layer
# parity and tools/deploy-verb-smoke.sh for verb-coverage smoke.

echo "tools/deploy-dry-run-diff.sh: placeholder — see script comment for status."
exit 0
