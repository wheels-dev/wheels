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
#   ship-consumer-docs.sh verify <artifact-root>
#       Validate a BUILT package: its CLAUDE.md, AGENTS.md and every .ai/*.md
#       file are byte-identical to the consumer tier, .ai/ holds nothing else,
#       and no maintainer-only path is present. Exits 1 with a message on failure.
#
# Keep in sync with:
#   - tools/build/scripts/prepare-core.sh        (calls `ship`)
#   - tools/build/scripts/prepare-starterApp.sh  (calls `ship`)
#   - tools/build/scripts/prepare-base.sh        (calls `ship`)
#   - .github/workflows/release.yml              (calls `check` + `verify`)
#   - .github/workflows/commandbox-install-smoke.yml (calls `verify` on the base template)
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$DIR/../../.." && pwd)"
CONSUMER_DIR="$REPO_ROOT/docs/consumer-ai"

# Files/dirs that must NEVER appear in a consumer artifact (relative paths,
# matched against the destination root).
MAINTAINER_PATTERNS=(
    ".ai"
    ".claude"
    ".opencode"
    ".github"
    "CLAUDE.local.md"
    "docs/superpowers"
    "docs/plans"
)

# The consumer tier's files, relative to docs/consumer-ai/: CLAUDE.md, AGENTS.md
# and every .ai/*.md topic file (README.md plus any topic files).
consumer_files() {
    echo "CLAUDE.md"
    echo "AGENTS.md"
    (cd "$CONSUMER_DIR" && find .ai -type f -name '*.md' | sort)
}

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

    # `wheels new` scaffolds ship a committed copy of the consumer tier;
    # it must stay byte-identical to the source.
    local tpl="$REPO_ROOT/cli/lucli/templates/app"
    for f in $(consumer_files); do
        if ! cmp -s "$CONSUMER_DIR/$f" "$tpl/$f"; then
            echo "ERROR: cli/lucli/templates/app/$f differs from docs/consumer-ai/$f (cp to resync)" >&2
            failures=$((failures + 1))
        fi
    done
    # ...and the template must not carry .ai/ files the consumer tier doesn't have.
    if [ -d "$tpl/.ai" ]; then
        for f in $(cd "$tpl" && find .ai -type f | sort); do
            if [ ! -f "$CONSUMER_DIR/$f" ]; then
                echo "ERROR: cli/lucli/templates/app/$f has no docs/consumer-ai/$f counterpart" >&2
                failures=$((failures + 1))
            fi
        done
    fi

    # CLAUDE.md is read in full by agent harnesses that cap or elide long files,
    # so it stays small; the reference material lives in .ai/<topic>.md (#3960).
    local budget=8192
    local size
    size=$(wc -c < "$CONSUMER_DIR/CLAUDE.md" | tr -d ' ')
    if [ "$size" -gt "$budget" ]; then
        echo "ERROR: docs/consumer-ai/CLAUDE.md is $size bytes, over the $budget-byte budget (move reference material to .ai/<topic>.md)" >&2
        failures=$((failures + 1))
    fi

    # Every .ai/ topic file is reachable from the CLAUDE.md topic index, and
    # every .ai/ file the index names exists.
    for f in $(cd "$CONSUMER_DIR" && find .ai -type f -name '*.md' | sort); do
        if ! grep -qF "\`$f\`" "$CONSUMER_DIR/CLAUDE.md"; then
            echo "ERROR: docs/consumer-ai/$f is not linked from the CLAUDE.md topic index" >&2
            failures=$((failures + 1))
        fi
    done
    for f in $(grep -oE '`\.ai/[A-Za-z0-9_./-]+\.md`' "$CONSUMER_DIR/CLAUDE.md" | tr -d '`' | sort -u); do
        if [ ! -f "$CONSUMER_DIR/$f" ]; then
            echo "ERROR: the CLAUDE.md topic index links $f, which doesn't exist" >&2
            failures=$((failures + 1))
        fi
    done

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
    for f in $(cd "$CONSUMER_DIR" && find .ai -type f -name '*.md' | sort); do
        cp "$CONSUMER_DIR/$f" "$dest/$f"
    done
    echo "Shipped consumer AI docs -> $dest"
}

verify() {
    local root="${1:?artifact root required}"
    local failures=0
    for f in $(consumer_files); do
        if ! cmp -s "$CONSUMER_DIR/$f" "$root/$f"; then
            echo "ERROR: $root/$f is missing or differs from docs/consumer-ai/$f" >&2
            failures=$((failures + 1))
        fi
    done
    if [ -d "$root/.ai" ]; then
        for f in $(cd "$root" && find .ai -type f | sort); do
            if [ ! -f "$CONSUMER_DIR/$f" ]; then
                echo "ERROR: $root/$f is not part of the consumer AI docs" >&2
                failures=$((failures + 1))
            fi
        done
    fi
    for pattern in "${MAINTAINER_PATTERNS[@]}"; do
        [ "$pattern" = ".ai" ] && continue
        if [ -e "$root/$pattern" ]; then
            echo "ERROR: $root leaks maintainer-only path: $pattern" >&2
            failures=$((failures + 1))
        fi
    done
    if [ "$failures" -gt 0 ]; then
        echo "consumer-docs verify FAILED for $root ($failures problem(s))" >&2
        exit 1
    fi
    echo "consumer-docs verify OK: $root"
}

case "${1:-}" in
    ship)   ship "${2:?usage: ship-consumer-docs.sh ship <dest-root>}" ;;
    check)  check ;;
    verify) verify "${2:?usage: ship-consumer-docs.sh verify <artifact-root>}" ;;
    *)      echo "usage: ship-consumer-docs.sh {ship <dest-root>|check|verify <artifact-root>}" >&2; exit 2 ;;
esac
