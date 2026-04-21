#!/usr/bin/env bash
# Aspirational command-string diff vs Ruby Kamal. Currently a no-op stub.
#
# The Phase 1 plan called for a `kamal deploy --dry-run` vs
# `wheels deploy --dry-run` byte-ish comparison. Ruby Kamal 2.8.2 does
# NOT expose a dry-run flag on `kamal deploy` — it attempts real SSH
# and errors out before emitting the command plan. `KAMAL_DEBUG=1`
# dumps emitted SSHKit commands but also still tries to run them.
#
# Closing this gap requires one of:
#
#   (a) Upstream Kamal adds a first-class `--dry-run` that serializes
#       the command plan to stdout without opening SSH. (No tracking
#       issue at time of writing.)
#
#   (b) We ship a mock SSH transport (e.g. an `SSHKit::Backend::Printer`
#       shim) loaded via `KAMAL_CONFIG_ARGV` or similar that swallows
#       `execute`/`capture` calls and records them. This would live in
#       `tools/kamal-capture/` and be invoked here.
#
# Until one of those lands, the Phase 1 exit gate is:
#   - tools/deploy-config-diff.sh  (config-layer parity smoke test)
#   - bash tools/test-cli-local.sh (our CLI suite including command-
#     string unit tests for AppCommands/BuilderCommands/ProxyCommands/
#     RegistryCommands/AuditorCommands/DeployMainCli)
#
# The normalizer `tools/deploy-dry-run-normalize.py` is ready to use
# once option (a) or (b) exists — it handles ANSI stripping, host prefix
# removal, flag sorting, and line sorting so cosmetic differences don't
# mask real divergence.
#
# See docs/superpowers/plans/2026-04-21-phase1-retrospective.md for
# the honest Phase 1 write-up and the recommended relaxation of the
# exit criteria.
echo "deploy-dry-run-diff.sh: stub — Ruby Kamal 2.8.2 does not expose a"
echo "dry-run flag on 'kamal deploy' that emits commands without SSH."
echo "Use tools/deploy-config-diff.sh for the Phase 1 config-layer gate."
exit 0
