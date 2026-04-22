# Issue #2178: Node 22 test-runner spawn ENOENT in verify-docs harness unit tests

## Verdict
FIX NOW (small, targeted workaround — pin Node 20 for the harness job + preserve/remove the soft-fail)

## Summary
Node 22's `node --test` workers return `spawn ENOENT` for child-process invocations on ubuntu-latest (Linuxbrew) — even for absolute paths that `statSync`/`accessSync` confirm are executable (including `/bin/bash`). Only test-runner worker contexts hit this; the main process `pnpm verify:docs` run is unaffected. Currently masked by `continue-on-error: true` in `.github/workflows/docs-verify.yml`, so harness regressions silently green CI.

## Root cause
Node 22's test-runner worker lifecycle + posix_spawn interaction on Linuxbrew's self-installed binaries. The harness lib (`web/sites/guides/scripts/verify-docs/lib/exec.mjs`) already resolves `wheels` to an absolute path at module load exactly to dodge PATH inheritance issues in workers (comment L3–L13). Even with that workaround, ENOENT persists on every spawn inside `--test` workers on CI. Main-process spawns work fine (the separate `verify:docs` step and local runs on both macOS and Linux pass). This is a Node 22 worker quirk, not a harness bug. Node team has not shipped a scoped fix as of 22.x on the current runner image. Because the main-process `verify:docs` step is the actual content gate, the harness unit tests are "can the harness itself spawn?" smoke tests — they run the same `wheels` binary the real run uses and therefore add no coverage the main run doesn't already have, except for the pure-logic units (extract, orchestrator partition/sort, parseHttpAssert).

## Files to change
Primary (Option A — pin Node 20 for harness job):
- `.github/workflows/docs-verify.yml` — split the single `verify` job, or add a matrix/second Node setup for `Run harness unit tests` step at `node-version: 20`, then drop `continue-on-error: true` from that step.

Optional follow-ups (either in same PR or tracked separately):
- `web/sites/guides/package.json` — add a `test:docs-harness:pure` script that runs only the non-spawn tests (`extract.test.mjs`, and the pure unit tests from `orchestrator.test.mjs` / `tutorial.test.mjs`) so those can gate CI unconditionally.
- `web/sites/guides/scripts/verify-docs/test/orchestrator.test.mjs` — currently spawns `node` to run `verify-docs.mjs` via `child_process.spawn` (lines 13–25). If keeping on Node 22, refactor `runEntry` to invoke the module in-process via dynamic `import()` instead of spawning `node`, or gate those two cases behind a `SKIP_SPAWN` env var.
- `web/sites/guides/scripts/verify-docs/test/cli.test.mjs`, `compile.test.mjs`, `tutorial.test.mjs` — the subprocess-heavy specs. Leave as-is under pinned Node 20; flag for future rewrite if the Node 20 pin isn't viable long-term.

## Implementation steps
1. **Reproduce once on CI** before changing anything. Push a throwaway branch that runs `node --version && node --test scripts/verify-docs/test/extract.test.mjs` as the harness step (extract.test.mjs has zero subprocess spawns). Confirm it passes on Node 22 — this proves spawns, not the runner itself, are the failure. Then run the same extract-only suite under Node 22 on the full matrix to confirm isolation.

2. **Open the "pin Node 20" PR.** Edit `.github/workflows/docs-verify.yml`:
   - Insert a new `Set up Node.js (harness tests)` step immediately before `Run harness unit tests`:
     ```yaml
     - name: Set up Node.js (harness tests)
       uses: actions/setup-node@v4
       with:
         node-version: 20
         cache: pnpm
         cache-dependency-path: web/pnpm-lock.yaml
     ```
   - Remove `continue-on-error: true` from the `Run harness unit tests` step.
   - After the harness step, re-add a `Set up Node.js (main)` step pinning back to 22 before `Verify v4 docs` runs (so the content gate still runs on the shipping Node version).
   - Update the comment block on the `verify` job to cite issue #2178 and this plan file.

3. **Verify in CI** on the PR branch:
   - Harness step must be **required** (not `continue-on-error`) and green on Node 20.
   - `Verify v4 docs` step continues on Node 22 with its existing `continue-on-error` (that's gap #11 / #2176, a separate issue).
   - `Build guides site` remains green.

4. **(Optional, recommended) Split the harness suite.** Add to `web/sites/guides/package.json`:
   ```json
   "test:docs-harness:pure": "node --test scripts/verify-docs/test/extract.test.mjs"
   ```
   and a step in the workflow that runs `pnpm test:docs-harness:pure` on Node 22 without `continue-on-error`, in addition to the Node 20 full run. This keeps the pure-logic tests gated on the shipping Node version so they don't quietly rot.

5. **(Optional) Refactor `orchestrator.test.mjs` to avoid spawning `node`.** Replace `runEntry()` helper with `import('../verify-docs.mjs')` and call the exported entrypoint directly, capturing stdout via a pluggable writer or `process.stdout` monkey-patch. This removes one of the three spawn-per-test sources and makes orchestrator coverage Node-22-safe without a version pin. Only do this if verify-docs.mjs has (or can gain) a programmatic entrypoint cleanly; otherwise defer.

6. **Track the upstream Node issue.** Search nodejs/node for `test-runner spawn ENOENT` / `posix_spawn worker`. If an existing issue is found, link in the workflow comment so we know when to drop the Node 20 pin. If not, file one with a minimal repro drawn from `exec.mjs` + a ubuntu-latest + Linuxbrew setup.

7. **Update the workflow comment block** (currently L15–L20 and L75–L82 of `docs-verify.yml`) to: cite #2178, note the pin, note that the pin is a workaround pending upstream Node fix, and state that the main content gate (`verify:docs`) is unaffected.

## Testing
- Local: `cd web/sites/guides && pnpm test:docs-harness` already passes on Node 22 macOS — baseline.
- CI matrix that must pass **without** `continue-on-error`:
  - `Run harness unit tests` on Node 20 (ubuntu-latest + Linuxbrew).
  - `pnpm test:docs-harness:pure` on Node 22 (ubuntu-latest) — if step 4 is taken.
- CI steps that remain soft-fail (tracked separately):
  - `Verify v4 docs` — gap #11 / #2176.
- Manual check: push a branch with an intentionally broken extract.mjs assertion → harness step should now fail the build (no more silent green).

## Risk & dependencies
- **Risk:** Low. Pinning one step to Node 20 is reversible and isolated to the docs-verify workflow. Doesn't touch the harness code or the shipping CLI. The harness tests have already been proven to work on Node 20 local runs on both developers' macOS machines and earlier CI.
- **Dependency on #2176** (gap #11, LuCLI atomic `lucee.json` write): independent. #2176 affects the *main* `verify:docs` run, #2178 affects only the harness unit-test job. Fixing either does not block the other.
- **Dependency on LuCLI:** harness spawns `wheels` (via Homebrew formula), so Linuxbrew's `JAVA_HOME` hack in the workflow (L52–L62) must stay. No changes needed there.
- **Upstream Node:** once Node 22.x patches the worker spawn regression, drop the Node 20 pin. Low-effort cleanup.
- **Harness-test rot risk** if Option A ships alone: the full harness keeps running on Node 20 while shipping Node is 22 — small divergence risk. Step 4 (pure-logic tests on Node 22) mitigates this cheaply.

## Effort estimate
S — ~1 hour for Option A alone (workflow edit + CI iteration + comment cleanup). Add ~1 hour for Step 4 (pure-suite split) and ~1–2 hours for Step 5 (orchestrator.test.mjs in-process refactor) if taken. Total realistic scope for this PR: S–M.
