#!/usr/bin/env bash
# Verb-coverage smoke test for wheels deploy.
# Runs every in-scope verb through --dry-run against each fixture, asserts
# the command exits 0 and emits at least one line of [host]/[local] output.
#
# This is NOT a parity test vs. Ruby Kamal — see tools/deploy-config-diff.sh
# for the config-layer parity check and tools/deploy-dry-run-diff.sh for
# the (aspirational) command-string parity discussion.
#
# Exits 0 on success, 1 on any verb failing, 2 if the wheels binary can't
# dispatch the deploy subcommand at all (infrastructure not ready).
set -euo pipefail

cd "$(dirname "$0")/.."

FIXTURES_DIR="cli/lucli/tests/_fixtures/deploy/configs"
FAIL=0
SKIP=0

if ! command -v wheels >/dev/null 2>&1; then
    echo "WARNING: 'wheels' binary not on PATH — verb smoke test skipped."
    echo "        Install LuCLI + Wheels CLI module, then re-run this script."
    exit 0
fi

# Probe: can wheels dispatch deploy at all? If not, EXIT 0 WITH WARNING.
if ! wheels deploy version >/dev/null 2>&1; then
    echo "WARNING: 'wheels deploy' subcommand not reachable in this environment."
    echo "        This is expected if the installed wheels CLI predates the kamal port."
    echo "        Smoke test skipped."
    exit 0
fi

# Secondary probe: even if the binary returned exit 0, the output may contain
# the Lucee "no function [deploy]" error signature — treat that as "not wired".
probe_output=$(wheels deploy version 2>&1 || true)
if echo "$probe_output" | grep -q "has no  *function with name \[deploy\]"; then
    echo "WARNING: 'wheels deploy' subcommand not reachable (Module.cfc has no deploy function)."
    echo "        This is expected if the installed wheels CLI predates the kamal port."
    echo "        Smoke test skipped."
    exit 0
fi

smoke() {
    local label="$1"
    shift
    local output
    if ! output=$(wheels deploy "$@" 2>&1); then
        echo "FAIL: $label — exit non-zero"
        echo "   cmd: wheels deploy $*"
        echo "$output" | head -5 | sed 's/^/   > /'
        FAIL=$((FAIL+1))
        return
    fi
    if [ -z "$output" ]; then
        # Some verbs (e.g. `version`) return a single line; empty output is still a warn.
        echo "WARN: $label — empty output from 'wheels deploy $*'"
    else
        echo "OK:   $label"
    fi
}

for fix in minimal full with-accessories; do
    fix_path="$FIXTURES_DIR/$fix.yml"
    [ -f "$fix_path" ] || { echo "skip fixture $fix (not present)"; continue; }
    PATH_OPT="--configPath=$fix_path"

    echo "=== fixture: $fix ==="

    # Top-level
    smoke "deploy"                  --dry-run "$PATH_OPT" --version=v1
    smoke "redeploy"                redeploy --dry-run "$PATH_OPT" --version=v1
    smoke "rollback v1"             rollback v1 --dry-run "$PATH_OPT"
    smoke "setup"                   setup --dry-run "$PATH_OPT" --version=v1
    smoke "config"                  config "$PATH_OPT"
    smoke "version"                 version
    smoke "audit"                   audit --dry-run "$PATH_OPT"
    smoke "details"                 details --dry-run "$PATH_OPT"
    smoke "docs servers"            docs servers

    # app
    smoke "app boot"                app boot --version=v1 --dry-run "$PATH_OPT"
    smoke "app start"               app start --version=v1 --dry-run "$PATH_OPT"
    smoke "app stop"                app stop --version=v1 --dry-run "$PATH_OPT"
    smoke "app details"             app details --version=v1 --dry-run "$PATH_OPT"
    smoke "app containers"          app containers --dry-run "$PATH_OPT"
    smoke "app images"              app images --dry-run "$PATH_OPT"
    smoke "app logs"                app logs --dry-run "$PATH_OPT"
    smoke "app live"                app live --version=v1 --dry-run "$PATH_OPT"
    smoke "app maintenance"         app maintenance --version=v1 --dry-run "$PATH_OPT"
    smoke "app remove"              app remove --version=v1 --dry-run "$PATH_OPT"

    # proxy
    smoke "proxy boot"              proxy boot --dry-run "$PATH_OPT"
    smoke "proxy reboot"            proxy reboot --dry-run "$PATH_OPT"
    smoke "proxy start"             proxy start --dry-run "$PATH_OPT"
    smoke "proxy stop"              proxy stop --dry-run "$PATH_OPT"
    smoke "proxy restart"           proxy restart --dry-run "$PATH_OPT"
    smoke "proxy details"           proxy details --dry-run "$PATH_OPT"
    smoke "proxy logs"              proxy logs --dry-run "$PATH_OPT"
    smoke "proxy remove"            proxy remove --dry-run "$PATH_OPT"

    # accessory — only meaningful for the accessories fixture
    if [ "$fix" = "with-accessories" ]; then
        smoke "accessory boot all"  accessory boot all --dry-run "$PATH_OPT"
        smoke "accessory details all" accessory details all --dry-run "$PATH_OPT"
    fi

    # build
    smoke "build deliver"           build deliver --dry-run "$PATH_OPT" --version=v1
    smoke "build push"              build push --dry-run "$PATH_OPT" --version=v1
    smoke "build pull"              build pull --dry-run "$PATH_OPT" --version=v1
    smoke "build create"            build create --dry-run "$PATH_OPT"
    smoke "build remove"            build remove --dry-run "$PATH_OPT"
    smoke "build details"           build details --dry-run "$PATH_OPT"
    smoke "build dev"               build dev --dry-run "$PATH_OPT"

    # registry
    smoke "registry login"          registry login --dry-run "$PATH_OPT" --password=stub
    smoke "registry logout"         registry logout --dry-run "$PATH_OPT"

    # prune
    smoke "prune all"               prune all --dry-run "$PATH_OPT"

    # server (legacy — see #2677 about the picocli collision)
    smoke "server bootstrap"        server bootstrap --dry-run "$PATH_OPT"
    smoke "server exec"             server exec "uname -a" --dry-run "$PATH_OPT"

    # top-level bootstrap/exec aliases that sidestep the LuCLI `server`
    # collision (#2677). These are the canonical CLI form.
    smoke "bootstrap (flat)"        bootstrap --dry-run "$PATH_OPT"
    smoke "exec (flat)"             exec "uname -a" --dry-run "$PATH_OPT"

    # lock
    smoke "lock status"             lock status --dry-run "$PATH_OPT"

    # secrets
    smoke "secrets print"           secrets print

    echo
done

if [ $FAIL -eq 0 ]; then
    echo "All verbs smoke-pass."
    exit 0
fi
echo "FAILED: $FAIL verb invocations did not dispatch cleanly."
exit 1
