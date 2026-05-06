# tools/docs-validation

Per-function and per-guide-page documentation validation, run by Claude
agents. The agent reads `docs/api/v4.0.0.json` (the framework's live
self-introspection), walks the listed functions, and for each one:

1. Reads the CFC source for the function in `vendor/wheels/`.
2. Reads any existing example body in
   `vendor/wheels/public/docs/reference/<scope>/<name>.txt`.
3. Validates samples by compiling them with `wheels cfml` (existing
   `verify-docs` harness primitive) or by running them through a fresh
   fixture app (also reused from `verify-docs`).
4. Reconciles the docblock prose in the CFC against actual behavior.
   When the body is genuinely buggy and the documented contract is
   right, fixes the body — bounded by the test suite staying green.
5. Commits the edits.

## Edit scope (enforced)

- `vendor/wheels/**/*.cfc` — docblock hint + `@param` hints + (rarely)
  function bodies when behavior contradicts the contract
- `vendor/wheels/public/docs/reference/<scope>/<name>.txt` — examples
- Nothing else. Anything else trips the "needs human" flag.

## Running locally

    cd tools/docs-validation
    pnpm install
    ANTHROPIC_API_KEY=sk-... node orchestrate.mjs --section "Model Class" --dry-run
    ANTHROPIC_API_KEY=sk-... node orchestrate.mjs --function findEach
    node orchestrate.mjs --section "Model Class" --status     # show progress

## Running in CI

`.github/workflows/docs-validation.yml` exposes `workflow_dispatch`
with a `section` input. Triggering it picks one of the 9 sections,
runs the orchestrator over every function in that section, opens a
draft PR against `develop` with the edits.

## State

`state.json` (committed) tracks per-function status:
`pending` → `in_progress` → `done` | `failed` | `needs_human`.
Re-runs are idempotent — only `pending` and `failed` items are
re-attempted.
