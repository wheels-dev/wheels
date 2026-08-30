#!/bin/bash
# Two-tier AI documentation: swap consumer-facing docs into distribution
# artifacts and keep maintainer-only docs out.
#
# The framework repo carries TWO AI doc tiers:
#
#   MAINTAINER tier (repo only, never shipped):
#     CLAUDE.md, AGENTS.md, .ai/, .claude/
#     — cross-engine invariants, test infrastructure, release engineering.
#     Excluded from git archives via .gitattributes and never copied by
#     prepare-*.sh.
#
#   CONSUMER tier (ships in every artifact):
#     docs/consumer-ai/{CLAUDE.md, AGENTS.md, .ai/}
#     — application-developer quick references, MCP workflow guidance.
#     Copied into:
#       * the ForgeBox `wheels` core package (prepare-core.sh)
#       * the ForgeBox starter app        (prepare-starterApp.sh)
#       * every `wheels new` scaffold     (cli/lucli/templates/app/)
#
# Usage:
#   ship-consumer-docs.sh ship <dest-root>
#       Copy CLAUDE.md + AGENTS.md + .ai/ into <dest-root> and then
#       defensively REMOVE any maintainer-tier files that may have slipped
#       into the artifact root (defense in depth against future copy
#       changes broadening `cp -r vendor/wheels/*`).
#
#   ship-consumer-docs.sh check
#       Validate the SOURCE tree: consumer docs exist, the root CLAUDE.md
#       carries the pointer section, and no maintainer-only subtree sits
#       under docs/consumer-ai/. Exits 1 with a message on failure.
#
# Keep in sync with:
#   - tools/build/scripts/prepare-core.sh        (calls `ship`)
#   - tools/build/scripts/prepare-starterApp.sh  (calls `ship`)
#   - .github/workflows/release.yml              (calls `check` + artifact assertions)
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$DIR/../../.." && pwd)"
CONSUMER_DIR="$REPO_ROOT/docs/consumer-ai"

# Files/dirs that must NEVER appear in a consumer artifact (relative paths,
# matched against the destination root).
MAINTAINER_PATTERNS=(
    ".ai"
    ".claude"
    ".github"
    "CLAUDE.local.md"
    "docs/superpowers"
    "docs/plans"
)

check() {
    local failures=0

    # Consumer tier must exist and be complete.
    for f in CLAUDE.md AGENTS.md .ai/README.md; do
        if [ ! -f "$CONSUMER_DIR/$f" ]; then
            echo "ERROR: consumer doc missing: docs/consumer-ai/$f" >&2
            failures=$((failures + 1))
        fi
    done

    # Root CLAUDE.md must point at the consumer copy (keeps the split honest).
    if ! grep -q "docs/consumer-ai/CLAUDE.md" "$REPO_ROOT/CLAUDE.md"; then
        echo "ERROR: CLAUDE.md no longer points at docs/consumer-ai/CLAUDE.md" >&2
        failures=$((failures + 1))
    fi

    # The consumer tier must not accidentally grow maintainer content.
    if grep -Rq "test-local.sh\|compat-matrix.yml\|onboarding-harness" "$CONSUMER_DIR" 2>/dev/null; then
        echo "ERROR: maintainer-only content detected under docs/consumer-ai/" >&2
        failures=$((failures + 1))
    fi

    if [ "$failures" -gt 0 ]; then
        echo "consumer-docs check FAILED ($failures problem(s))" >&2
        exit 1
    fi
    echo "consumer-docs check OK"
}

ship() {
    local dest="${1:?destination root required}"
    [ -d "$dest" ] || mkdir -p "$dest"

    # 1. Defense in depth FIRST: strip anything maintainer-only that may
    #    have been copied in by a broader cp in the calling prepare script
    #    (run before shipping so the consumer .ai/ we copy next survives).
    local removed=0
    for pattern in "${MAINTAINER_PATTERNS[@]}"; do
        if [ -e "$dest/$pattern" ]; then
            rm -rf "$dest/$pattern"
            echo "Removed maintainer-only path from artifact: $pattern"
            removed=$((removed + 1))
        fi
    done
    [ "$removed" -eq 0 ] && echo "No maintainer-only paths present (good)"

    # 2. Ship the consumer tier.
    cp "$CONSUMER_DIR/CLAUDE.md" "$dest/CLAUDE.md"
    cp "$CONSUMER_DIR/AGENTS.md" "$dest/AGENTS.md"
    mkdir -p "$dest/.ai"
    cp "$CONSUMER_DIR/.ai/README.md" "$dest/.ai/README.md"
    echo "Shipped consumer AI docs -> $dest"
}

case "${1:-}" in
    ship)   ship "${2:?usage: ship-consumer-docs.sh ship <dest-root>}" ;;
    check)  check ;;
    *)      echo "usage: ship-consumer-docs.sh {ship <dest-root>|check}" >&2; exit 2 ;;
esac
