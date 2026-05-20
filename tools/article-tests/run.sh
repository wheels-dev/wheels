#!/usr/bin/env bash
# Run the article test harness against the live middleware code.
#
# The harness instantiates wheels.middleware.* directly and exercises every
# claim the blog post "Skip the Plugin: Building a Rate-Limited API in
# Wheels 4.0" makes. It does NOT spin up an HTTP server — the middleware
# objects work fine with synthetic request structs, which is sufficient for
# article validation.
#
# Requires BoxLang 1.5+ on PATH or at /opt/boxlang/bin/boxlang.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

if command -v boxlang >/dev/null 2>&1; then
    BOXLANG=boxlang
elif [ -x /opt/boxlang/bin/boxlang ]; then
    BOXLANG=/opt/boxlang/bin/boxlang
else
    echo "boxlang not found. Install from https://boxlang.io" >&2
    exit 1
fi

# Run from project root with a custom boxlang.json that maps:
#   /         -> project root            (so /app/global/functions.cfm resolves for the Mapper bootstrap)
#   /wheels   -> vendor/wheels           (so the dotted path wheels.middleware.X resolves)
# classPaths also includes vendor/ so unqualified component lookups work.
cd "$ROOT"
exec "$BOXLANG" --bx-config "$ROOT/tools/article-tests/boxlang.json" "$ROOT/tools/article-tests/run.cfm"
