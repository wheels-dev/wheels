# tools/docs-validation

Agent-driven docs validation. Two modes:

- **`--mode=api`** (the original) — walks `docs/api/v4.0.0.json` and
  validates each public function: reads CFC source, refreshes/authors
  reference example at `vendor/wheels/public/docs/reference/<scope>/<name>.txt`,
  fixes docblock drift in the CFC.
- **`--mode=guide`** — walks `web/sites/guides/src/content/docs/v4-0-0-snapshot/`
  and validates each page: enumerates code blocks, adds `{test:*}`
  annotations to anything tag-able, marks illustrative blocks with
  `title="..."`, fixes prose drift, validates via the existing
  `verify-docs` harness.

## Edit scope (enforced at the tool layer)

- `vendor/wheels/**/*.cfc` — docblock hint + `@param` hints + (rarely)
  function bodies when behavior contradicts the contract
- `vendor/wheels/public/docs/reference/<scope>/<name>.txt` — API
  examples (api mode)
- `web/sites/guides/src/content/docs/v4-0-0-snapshot/**/*.mdx?` —
  guide page edits (guide mode)
- Nothing else. Anything else trips the `needs_human` flag.

## Running locally

    cd tools/docs-validation
    npm install

    # API mode
    node orchestrate.mjs --list-sections
    node orchestrate.mjs --section "Model Class" --dry-run
    ANTHROPIC_API_KEY=sk-... node orchestrate.mjs --function findEach

    # Guide mode
    node orchestrate.mjs --mode=guide --list-directories
    node orchestrate.mjs --mode=guide --directory upgrading --dry-run
    ANTHROPIC_API_KEY=sk-... node orchestrate.mjs --mode=guide --path "upgrading/3x-to-4x.mdx"

    # Shared
    node orchestrate.mjs --status

## Running in CI

`.github/workflows/docs-validation.yml` exposes `workflow_dispatch` with
a `mode` input (`api` / `guide`). Pick the appropriate `section` (api
mode) or `directory` (guide mode), and the orchestrator opens a draft
PR back into `develop`.

## State

`state.json` (committed) tracks per-item status:
`pending` → `in_progress` → `done` | `failed` | `needs_human`.

Item keys: `function:<name>` for api mode, `guide:<rel-path>` for
guide mode (e.g. `guide:upgrading/3x-to-4x.mdx`).

Re-runs are idempotent — `done` items are skipped unless `--force` is
passed; `pending` and `failed` items are re-attempted.
