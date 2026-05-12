#!/usr/bin/env bash
set -euo pipefail

# Integration test: LuCLI module install and basic generator functionality
#
# Verifies the full pipeline:
#   1. Install wheels module from distribution repo
#   2. Validate module structure at ~/.lucli/modules/wheels/
#   3. Scaffold a new Wheels project
#   4. Generate a model and controller in the project
#
# Prerequisites:
#   - lucli binary on PATH
#   - git available
#   - Network access to github.com
#
# Usage:
#   ./test-module-install.sh                                          # default: wheels-dev/wheels-cli-lucli
#   ./test-module-install.sh https://github.com/wheels-dev/wheels-cli-lucli#v3.1.0  # specific version

DIST_REPO="${1:-https://github.com/wheels-dev/wheels-cli-lucli}"
TMPDIR=$(mktemp -d)
PASS=0
FAIL=0

cleanup() {
    rm -rf "$TMPDIR"
}
trap cleanup EXIT

pass() {
    echo "  PASS: $1"
    ((PASS++))
}

fail() {
    echo "  FAIL: $1"
    ((FAIL++))
}

echo "=== Test Suite: LuCLI Wheels Module Install ==="
echo "Distribution repo: $DIST_REPO"
echo ""

# --- Phase 1: Install module ---
echo "--- Phase 1: Install module from distribution repo ---"
if lucli modules install wheels --url "$DIST_REPO" --force 2>&1; then
    pass "Module installed successfully"
else
    fail "Module install failed"
    echo "Cannot continue without module installed."
    exit 1
fi

if lucli modules list 2>&1 | grep -q "wheels"; then
    pass "Module appears in 'lucli modules list'"
else
    fail "Module not found in 'lucli modules list'"
fi

# --- Phase 2: Validate module structure ---
echo ""
echo "--- Phase 2: Validate module structure ---"
MODULE_DIR="$HOME/.lucli/modules/wheels"

for f in module.json Module.cfc; do
    if [ -f "$MODULE_DIR/$f" ]; then
        pass "$f exists at module root"
    else
        fail "$f missing from $MODULE_DIR"
    fi
done

for d in services templates; do
    if [ -d "$MODULE_DIR/$d" ]; then
        pass "$d/ directory exists"
    else
        fail "$d/ directory missing from $MODULE_DIR"
    fi
done

# Verify module.json has correct name
if jq -e '.name == "wheels"' "$MODULE_DIR/module.json" > /dev/null 2>&1; then
    pass "module.json name is 'wheels'"
else
    fail "module.json name is not 'wheels'"
fi

# --- Phase 3: Scaffold a test project ---
echo ""
echo "--- Phase 3: Scaffold a test project ---"
cd "$TMPDIR"
# `wheels new` requires a discoverable vendor/wheels/ framework source and
# now exits non-zero if one isn't found (GH #2211). The distribution module
# itself does not ship the framework, so the caller must point at a checkout
# via WHEELS_FRAMEWORK_PATH. Skip the scaffold phase gracefully if it isn't set.
if [ -z "${WHEELS_FRAMEWORK_PATH:-}" ]; then
    echo "  SKIP: WHEELS_FRAMEWORK_PATH not set — skipping scaffold phases"
    echo "  Set WHEELS_FRAMEWORK_PATH=/path/to/wheels/vendor/wheels to run full test"
    echo ""
    echo "=== Summary: $PASS pass, $FAIL fail (scaffold phases skipped) ==="
    [ "$FAIL" -eq 0 ] && exit 0 || exit 1
fi
if lucli wheels new testapp 2>&1; then
    pass "wheels new testapp succeeded"
else
    fail "wheels new testapp failed"
fi

if [ -d "testapp" ]; then
    pass "testapp/ directory created"
    cd testapp
else
    fail "testapp/ directory not created"
    echo "Cannot continue without project directory."
    exit 1
fi

for f in config/settings.cfm config/routes.cfm; do
    if [ -f "$f" ]; then
        pass "$f exists in scaffolded project"
    else
        fail "$f missing from scaffolded project"
    fi
done

# --- Phase 4: Generate a model ---
echo ""
echo "--- Phase 4: Generate a model ---"
if lucli wheels generate model User firstName lastName email 2>&1; then
    pass "generate model User succeeded"
else
    fail "generate model User failed"
fi

if [ -f "app/models/User.cfc" ]; then
    pass "app/models/User.cfc created"
else
    fail "app/models/User.cfc not created"
fi

# --- Phase 5: Generate a controller ---
echo ""
echo "--- Phase 5: Generate a controller ---"
if lucli wheels generate controller Users index show 2>&1; then
    pass "generate controller Users succeeded"
else
    fail "generate controller Users failed"
fi

if [ -f "app/controllers/Users.cfc" ]; then
    pass "app/controllers/Users.cfc created"
else
    fail "app/controllers/Users.cfc not created"
fi

# --- Results ---
echo ""
echo "=== Results ==="
TOTAL=$((PASS + FAIL))
echo "$PASS/$TOTAL passed, $FAIL failed"

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
echo "ALL TESTS PASSED"
