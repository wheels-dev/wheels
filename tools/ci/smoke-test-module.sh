#!/usr/bin/env bash
set -euo pipefail

# Smoke test for the built wheels-module-*.tar.gz.
#
# Installs the just-built Wheels LuCLI module into an isolated LUCLI_HOME, then
# exercises every template-driven generator against a scratch project. Catches
# packaging regressions (like #1944) where a generator silently produces empty
# output or fails because its templates weren't copied into the module tar.
#
# Usage:
#   tools/ci/smoke-test-module.sh <module-tar> <core-zip>
#
# Arguments:
#   <module-tar>   Path to wheels-module-*.tar.gz (built by release.yml)
#   <core-zip>     Path to wheels-core-*.zip     (built by release.yml)
#
# Requirements: lucli on PATH, java, unzip, tar. SQLite JDBC is not required
# because we assert on generator output, not migration execution.
#
# See issue #2208.

MODULE_TAR="${1:-}"
CORE_ZIP="${2:-}"

if [[ -z "$MODULE_TAR" || -z "$CORE_ZIP" ]]; then
    echo "Usage: $0 <module-tar> <core-zip>" >&2
    exit 2
fi
if [[ ! -f "$MODULE_TAR" ]]; then
    echo "Module tar not found: $MODULE_TAR" >&2
    exit 2
fi
if [[ ! -f "$CORE_ZIP" ]]; then
    echo "Core zip not found: $CORE_ZIP" >&2
    exit 2
fi

if ! command -v lucli >/dev/null 2>&1; then
    echo "lucli not on PATH" >&2
    exit 2
fi

SMOKE_ROOT="$(mktemp -d -t wheels-smoke.XXXXXX)"
export LUCLI_HOME="$SMOKE_ROOT/lucli-home"
FRAMEWORK_ROOT="$SMOKE_ROOT/framework"
WORKDIR="$SMOKE_ROOT/work"

cleanup() {
    rm -rf "$SMOKE_ROOT"
}
trap cleanup EXIT

PASS=0
FAIL=0
pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

assert_file_nonempty() {
    local path="$1" label="$2"
    if [[ -s "$path" ]]; then
        pass "$label ($(wc -c < "$path" | tr -d ' ') bytes)"
    else
        fail "$label — file missing or empty: $path"
    fi
}

assert_grep() {
    local pattern="$1" path="$2" label="$3"
    if [[ -f "$path" ]] && grep -qE "$pattern" "$path"; then
        pass "$label"
    else
        fail "$label — pattern '$pattern' not found in $path"
        if [[ -f "$path" ]]; then
            echo "    --- first 20 lines of $path ---"
            sed -n '1,20p' "$path" | sed 's/^/    /'
        fi
    fi
}

echo "=== Phase 1: Install module from built tar ==="
mkdir -p "$LUCLI_HOME/modules/wheels"
tar xzf "$MODULE_TAR" -C "$LUCLI_HOME/modules/wheels"

for f in module.json Module.cfc; do
    assert_file_nonempty "$LUCLI_HOME/modules/wheels/$f" "module root has $f"
done

for d in services templates templates/codegen; do
    if [[ -d "$LUCLI_HOME/modules/wheels/$d" ]]; then
        pass "module has $d/"
    else
        fail "module missing $d/ — codegen templates unbundled (see #1944)"
    fi
done

# Spot-check a few codegen templates that are known to have gone missing.
for t in HelperContent.txt ModelContent.txt ControllerContent.txt ApiControllerContent.txt; do
    assert_file_nonempty "$LUCLI_HOME/modules/wheels/templates/codegen/$t" "codegen template $t bundled"
done

if lucli modules list 2>&1 | grep -q "wheels"; then
    pass "lucli modules list shows 'wheels'"
else
    fail "lucli modules list does not show 'wheels'"
fi

echo ""
echo "=== Phase 2: Extract framework core for WHEELS_FRAMEWORK_PATH ==="
mkdir -p "$FRAMEWORK_ROOT"
unzip -q "$CORE_ZIP" -d "$FRAMEWORK_ROOT"
if [[ -d "$FRAMEWORK_ROOT/wheels" ]]; then
    pass "wheels-core extracted to $FRAMEWORK_ROOT/wheels"
    export WHEELS_FRAMEWORK_PATH="$FRAMEWORK_ROOT/wheels"
else
    fail "wheels-core zip layout unexpected (no wheels/ at root)"
    ls "$FRAMEWORK_ROOT" || true
    echo "Cannot continue without framework source."
    exit 1
fi

echo ""
echo "=== Phase 3: Scaffold a scratch app ==="
mkdir -p "$WORKDIR"
cd "$WORKDIR"
if lucli wheels new smoke --no-open-browser 2>&1 | sed 's/^/    /'; then
    pass "wheels new smoke succeeded"
else
    fail "wheels new smoke failed"
    exit 1
fi

if [[ -d "smoke" ]]; then
    cd smoke
    pass "smoke/ directory created"
else
    fail "smoke/ directory not created"
    exit 1
fi

assert_file_nonempty "config/settings.cfm" "config/settings.cfm"
assert_file_nonempty "config/routes.cfm" "config/routes.cfm"

echo ""
echo "=== Phase 4: Exercise every template-driven generator ==="

echo ""
echo "--- generate model User name:string email:string ---"
lucli wheels generate model User name:string email:string 2>&1 | sed 's/^/    /' || true
assert_file_nonempty "app/models/User.cfc" "model User.cfc generated"
# Current ModelContent template renders component shell + config() scaffold but
# does not emit validations from attrs. Assert structure, not content we don't emit.
assert_grep 'extends="Model"' "app/models/User.cfc" "model extends Model"
assert_grep "function config" "app/models/User.cfc" "model has config()"

echo ""
echo "--- generate controller Users index show ---"
lucli wheels generate controller Users index show 2>&1 | sed 's/^/    /' || true
assert_file_nonempty "app/controllers/Users.cfc" "controller Users.cfc generated"
assert_grep "function index" "app/controllers/Users.cfc" "controller has function index"

echo ""
echo "--- generate api-resource Product name price:decimal ---"
lucli wheels generate api-resource Product name price:decimal 2>&1 | sed 's/^/    /' || true
# api-resource generator namespaces the controller under api/ to keep API and
# web controllers separate.
assert_file_nonempty "app/controllers/api/Products.cfc" "api-resource Products.cfc generated"
assert_grep "renderWith" "app/controllers/api/Products.cfc" "api-resource has renderWith"
assert_file_nonempty "app/models/Product.cfc" "api-resource Product.cfc model generated"

echo ""
echo "--- generate helper formatting truncateText ---"
lucli wheels generate helper formatting truncateText 2>&1 | sed 's/^/    /' || true
# Helper file path convention: app/helpers/<Name>Helper.cfc
if [[ -s "app/helpers/FormattingHelper.cfc" ]]; then
    assert_file_nonempty "app/helpers/FormattingHelper.cfc" "helper FormattingHelper.cfc generated"
elif [[ -s "app/helpers/Formatting.cfc" ]]; then
    assert_file_nonempty "app/helpers/Formatting.cfc" "helper Formatting.cfc generated"
else
    fail "no FormattingHelper.cfc or Formatting.cfc under app/helpers/"
    ls -la app/helpers 2>/dev/null || echo "    app/helpers missing"
fi

echo ""
echo "--- generate scaffold Post title:string body:text ---"
lucli wheels generate scaffold Post title:string body:text 2>&1 | sed 's/^/    /' || true
assert_file_nonempty "app/views/posts/index.cfm" "scaffold view posts/index.cfm generated"
assert_file_nonempty "app/controllers/Posts.cfc" "scaffold controller Posts.cfc generated"
assert_file_nonempty "app/models/Post.cfc" "scaffold model Post.cfc generated"
# Scaffold must also drop a migration — template path that gets missed otherwise.
migration_count=$(find app/migrator/migrations -maxdepth 1 -name '*.cfc' 2>/dev/null | wc -l | tr -d ' ')
if [[ "$migration_count" -gt 0 ]]; then
    pass "scaffold created $migration_count migration(s)"
else
    fail "scaffold did not create any migration under app/migrator/migrations"
fi

echo ""
echo "--- generate snippets auth ---"
lucli wheels generate snippets auth 2>&1 | sed 's/^/    /' || true
assert_file_nonempty "app/controllers/Sessions.cfc" "snippets auth created Sessions.cfc"

echo ""
echo "=== Results ==="
TOTAL=$((PASS + FAIL))
echo "$PASS/$TOTAL passed, $FAIL failed"
if [[ "$FAIL" -gt 0 ]]; then
    echo "SMOKE TEST FAILED — installed distribution regressions present" >&2
    exit 1
fi
echo "ALL SMOKE TESTS PASSED"
