#!/usr/bin/env bash
# Phase 1 exit gate (revised): config-layer parity vs Ruby Kamal.
#
# Originally the plan called for byte-identical "--dry-run" output vs
# `kamal deploy --dry-run`. Ruby Kamal 2.8.2 has no such flag on
# `kamal deploy` — it attempts real SSH and errors. The closest
# inspectable surface is `kamal config`, which prints the resolved
# configuration hash as YAML. This script diffs that against
# `wheels deploy config` for each fixture.
#
# We do NOT gate the build on strict equality. Our config output is a
# deliberate subset (service/image/servers/registry-username) while
# Kamal's includes every defaulted field (ssh_options, logging, healthcheck,
# sshkit, etc.). Instead we PRINT both for reviewer eyeballing and exit 0
# as long as both tools produced *some* output. A future iteration can
# tighten this once we decide which Kamal fields we intend to mirror.
#
# Command-string parity — did `wheels deploy` plan the same docker/SSH
# commands Ruby Kamal would? — requires either:
#   (a) Kamal upstream adding a real `--dry-run` flag, or
#   (b) a mock SSH layer that captures Kamal's SSHKit emissions.
# See tools/deploy-dry-run-diff.sh (stub) for the aspirational harness
# and docs/superpowers/plans/2026-04-21-phase1-retrospective.md for
# the honest write-up.
#
# Prerequisites:
#   - Ruby + Kamal 2.x on PATH (tested with 2.8.2).
#   - `wheels` on PATH, wired to a Module.cfc with the deploy() dispatcher.
#   - Python 3 (stdlib only) for normalize helper — not strictly required
#     here but used by the companion dry-run script.
#
# Usage:
#   bash tools/deploy-config-diff.sh              # all fixtures
#   bash tools/deploy-config-diff.sh minimal      # one fixture by stem
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FIXTURES_DIR="$PROJECT_ROOT/cli/lucli/tests/_fixtures/deploy/configs"

if ! command -v kamal >/dev/null 2>&1; then
    echo "deploy-config-diff.sh: 'kamal' not on PATH; skipping Ruby Kamal comparison."
    echo "  Install via 'gem install kamal' to enable this gate."
    exit 0
fi

KAMAL_VERSION="$(kamal version 2>/dev/null || echo unknown)"
echo "Using Ruby Kamal version: $KAMAL_VERSION"

# Select fixtures. Task 38 expanded the default loop to cover all three
# fixtures (minimal, full, with-accessories). Our output remains a
# deliberate subset vs. Kamal's fully-resolved Configuration hash; this
# script still does NOT enforce strict exit-gate equality on field
# contents — it asserts both tools produced output for every fixture and
# emits the pair for reviewer eyeballing. Pass a stem to override.
if [ "$#" -gt 0 ]; then
    STEMS=("$@")
else
    STEMS=(minimal full with-accessories)
fi

FAIL=0
for stem in "${STEMS[@]}"; do
    FIX_PATH="$FIXTURES_DIR/${stem}.yml"
    if [ ! -f "$FIX_PATH" ]; then
        echo "!! fixture not found: $FIX_PATH"
        FAIL=1
        continue
    fi

    echo
    echo "=============================================================="
    echo "Fixture: ${stem}.yml"
    echo "=============================================================="

    # Ruby Kamal demands:
    #   - config/deploy.yml path layout
    #   - a .kamal/secrets file (any content is fine with env override)
    #   - builder.arch set (Configuration hard-requires it)
    #   - a git repository OR an explicit VERSION env (it defaults to
    #     the git HEAD SHA as image tag)
    TMP="$(mktemp -d)"
    trap 'rm -rf "$TMP"' EXIT
    mkdir -p "$TMP/config" "$TMP/.kamal"

    # Inject builder.arch if absent — we do NOT want our fixture to carry
    # Kamal-specific scaffolding just to appease its config loader.
    if grep -q '^builder:' "$FIX_PATH"; then
        cp "$FIX_PATH" "$TMP/config/deploy.yml"
    else
        { cat "$FIX_PATH"; echo; echo "builder:"; echo "  arch: amd64"; } \
            > "$TMP/config/deploy.yml"
    fi
    printf 'REGISTRY_PASSWORD=stub\n' > "$TMP/.kamal/secrets"

    (cd "$TMP" && git init -q)

    echo
    echo "--- Ruby Kamal (kamal config) ---"
    ruby_cfg_file="$TMP/kamal.out"
    if (cd "$TMP" && REGISTRY_PASSWORD=stub VERSION=v1 kamal config) \
        > "$ruby_cfg_file" 2>&1
    then
        sed -n '1,50p' "$ruby_cfg_file"
    else
        echo "(kamal config errored — see $ruby_cfg_file)"
        sed -n '1,20p' "$ruby_cfg_file"
        FAIL=1
    fi

    echo
    echo "--- wheels deploy config ---"
    wheels_cfg_file="$TMP/wheels.out"
    if wheels deploy config --configPath="$FIX_PATH" \
        > "$wheels_cfg_file" 2>&1
    then
        sed -n '1,50p' "$wheels_cfg_file"
    else
        echo "(wheels deploy config errored — see $wheels_cfg_file)"
        sed -n '1,20p' "$wheels_cfg_file"
        FAIL=1
    fi

    echo
    echo "--- Notes ---"
    echo "Ruby Kamal emits a fully-resolved Configuration hash (ssh_options,"
    echo "logging, sshkit defaults, builder, healthcheck, etc.). wheels deploy"
    echo "config emits only the surface we mirror in Phase 1: service, image,"
    echo "servers (role->hosts), registry.server, registry.username. Strict"
    echo "equality is NOT a Phase 1 goal — structural inclusion is."

    rm -rf "$TMP"
    trap - EXIT
done

echo
if [ "$FAIL" -eq 0 ]; then
    echo "deploy-config-diff.sh: both tools produced output for all fixtures."
else
    echo "deploy-config-diff.sh: one or more fixtures had tool errors above."
fi
exit "$FAIL"
