# Two-Tier AI Docs: Optimizing the Monorepo's AI Documentation for Maintainers vs. Framework Users

Date: 2026-08-30
Status: implemented (docs split + packaging swap + CI assertions)

## Problem statement

The `wheels-dev` workspace (17 sibling repos) accumulated AI-oriented
documentation organically. The framework repo (`wheels/`) ended up with:

1. **A 64 KB root `CLAUDE.md`** that mixes four audiences: maintainer-only
   invariants (20 cross-engine rules), framework-user quick references
   (Model/Routing/Middleware/DI/Packages/Migrations/Jobs/SSE), contribution
   conventions, and a reference index. Auto-loaded instruction files get
   truncated near that size, so the tail of the file (user quick refs) was
   being dropped by the harness.
2. **A stale `.ai/README.md`** advertising 17 `wheels/` subdirectories when
   only 7 exist — an aspirational structure that misleads agents into
   reading non-existent paths (the same stale paths are referenced by
   `examples/tweet/AGENTS.md`).
3. **Duplication** between `CLAUDE.md`'s invariant list and
   `.ai/wheels/cross-engine-compatibility.md`.
4. **No `AGENTS.md`** at the framework root (the emerging cross-tool
   standard), while `examples/tweet/AGENTS.md` (an app-developer-oriented
   file) predates any official consumer tier.
5. **No consumer-facing AI docs in any distribution.** The ForgeBox core
   ships `docs/api` + `AI_INTEGRATION_GUIDE.md` + `wheels-vs-frameworks.md`
   (allowlisted in `prepare-core.sh`) but no `CLAUDE.md`/`AGENTS.md`, and
   `wheels new` scaffolds MCP/OpenCode configs without any instruction
   files. Meanwhile `.gitattributes` already export-ignores the maintainer
   tier (`.ai/`, `.claude/`, `tools/`, `docs/`) — the exclusion machinery
   existed but the consumer tier never existed to swap in.

## Design: two tiers with a swap mechanism

### Maintainer tier (repo only, never ships)

- `CLAUDE.md` — slimmed to the always-load core: Code Map, verification
  workflow, the 20 Cross-Engine Invariants, the 15 Anti-Patterns,
  conventions, commit/changelog rules, CLI/MCP surface, reference index
  (881 → ~506 lines).
- `AGENTS.md` — cross-tool pointer: repo identity, two-tier rule, test
  workflow, commit conventions.
- `.ai/` — deep reference (CFML language + Wheels internals), with an
  accurate index (`.ai/README.md` regenerated from the real tree).
- `docs/superpowers/`, `docs/plans/`, `.claude/commands/` — specs, plans,
  bot prompts.

### Consumer tier (ships in every artifact)

`docs/consumer-ai/`:

- `CLAUDE.md` — the application-developer quick reference (Wheels
  conventions; Model/Routing/Pagination/Middleware/DI/Packages/CLI/
  Migrations/Seeding/Jobs/SSE; app-testing) — the content moved out of the
  root `CLAUDE.md`, plus pointers to guides.wheels.dev and the `/wheels/ai`
  endpoints.
- `AGENTS.md` — MCP-first workflow, convention summary, pointers.
- `.ai/README.md` — index of the bundled subset; explicitly notes the
  maintainer set does NOT ship.

### Swap mechanism

- `tools/build/scripts/ship-consumer-docs.sh` — single source of truth:
  - `ship <dest-root>` — strip any maintainer-only paths that leaked into
    the artifact (defense in depth), then copy `CLAUDE.md` + `AGENTS.md` +
    `.ai/README.md`.
  - `check` — source-tree invariants (consumer tier exists, root
    `CLAUDE.md` points at it, no maintainer content drifted into the
    consumer tier).
- Wired into:
  - `tools/build/scripts/prepare-core.sh` (ForgeBox `wheels` core) — ships
    the consumer tier into the artifact root after the docs allowlist copy.
  - `tools/build/scripts/prepare-starterApp.sh` (ForgeBox starter app) —
    same.
  - `cli/lucli/templates/app/{CLAUDE.md,AGENTS.md,.ai/README.md}` — every
    `wheels new` scaffold gets the consumer tier verbatim.
  - `.github/workflows/release.yml` — the "Validate Package Structure and
    Versions" step now runs `ship-consumer-docs.sh check` and asserts each
    artifact contains the consumer docs while leaking none of the
    maintainer-only paths (`docs/superpowers`, `docs/plans`, `.claude`,
    `.github`, `CLAUDE.local.md`).
- `.gitattributes` continues to export-ignore the maintainer tier for
  `git archive`-style consumers.

## Rollout steps (done in this change set)

1. Moved user-facing quick references out of root `CLAUDE.md` (881 → 506
   lines) into `docs/consumer-ai/CLAUDE.md`, replacing them with a pointer
   section.
2. Added root `AGENTS.md` + `docs/consumer-ai/AGENTS.md`.
3. Added `docs/consumer-ai/.ai/README.md`.
4. Added `tools/build/scripts/ship-consumer-docs.sh` and wired it into
   `prepare-core.sh`, `prepare-starterApp.sh`, and `release.yml`.
5. Added the consumer tier to `cli/lucli/templates/app/` (`wheels new`).
6. Regenerated `.ai/README.md` from the actual tree; removed the dead
   `guides` entry from `context7.json`.

## Follow-ups (not in this change set)

- **Single-source the invariant list**: generate the `CLAUDE.md` invariant
  summaries from `.ai/wheels/cross-engine-compatibility.md` (or split each
  invariant into its own `.ai` page) with a CI freshness check.
- **Sibling repos**: roll the two-tier + `AGENTS.md` convention out to
  `wheels-basecoat`, `wheels-hotwire`, `wheels.dev`, and the packaging
  repos; standardize on `wheels-basecoat`'s `.ai/` taxonomy
  (ARCHITECTURE/PITFALLS/HELPERS/PATTERNS/SCAFFOLDS) as the naming model.
- **Consumer `.ai` depth**: optionally expand the shipped subset with
  focused app-building pages (jobs, channels, SSE) sourced from the guides
  site, keeping the subset under a few hundred KB.
- **llms.txt**: export `llms.txt` from `web/sites/guides` for LLM
  scrapers, and consider wiring `context7.json` to the versioned
  `docs/api/v4.0.0.json` explicitly.
