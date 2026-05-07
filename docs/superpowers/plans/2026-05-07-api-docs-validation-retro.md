# API Docs Validation Retrospective + Guides Loop Plan

**Date:** 2026-05-07
**Scope:** Closes the v4 API docs validation rollout (PRs #2440 → #2469). Plans the next phase: guides-page validation.

## What we shipped

A self-contained agent system at `tools/docs-validation/` that walks the framework's introspected API surface (`docs/api/v4.0.0.json`, 378 functions across 8 sections) and produces validated reference examples + fixes documentation drift in the framework's docblocks.

End state: every public function on `api.wheels.dev/v4-0-0-snapshot/` has an Examples section. Total cost: ~$30–35 across all 8 sections.

## The pipeline

```
docs/api/v4.0.0.json (snapshot)                    ← framework introspection
    ↓
tools/docs-validation/orchestrate.mjs              ← per-section dispatcher
    ↓
Anthropic API loop (Sonnet 4.6, max 24 turns)      ← with prompt caching
    ↓
Sandboxed tools: read_file, write_file, edit_file, ← path-allowlisted
                 run_bash, report_outcome
    ↓
vendor/wheels/public/docs/reference/<scope>/<name>.txt   ← agent output
vendor/wheels/**/*.cfc (docblock-only edits)             ← drift fixes
    ↓
snapshot.yml (CI on develop)                       ← regenerates JSON
    ↓
generate-api-docs.mjs                              ← MD pages
    ↓
Cloudflare Pages → api.wheels.dev/v4-0-0-snapshot/
```

## Final tally

| Section | Functions | Section PR | Done |
|---|---|---|---|
| Model Class | 47 | #2454 | 47 |
| Global Helpers | 23 | #2455 + #2457 (injector fix) | 23 |
| Model Object | 29 | #2459 | 29 |
| Configuration | 33 | #2460 | 33 |
| Model Configuration | 44 | #2461 | 44 |
| Controller | 48 | #2462 | 48 |
| Migrator | 49 | #2463 | 49 |
| View Helpers | 88 | #2465 + #2469 (h fix) | 88 |
| **Total** | **378** | 8 sections | **378 ✓** |

## What worked

- **Treat the framework's introspection JSON as canonical.** Building agents around the same JSON the deployed docs site consumes meant we never had to invent a separate function inventory. The snapshot was always source of truth for what exists.
- **One PR per section.** Reviewable. Reverting one section never affected another. State.json kept the workflow idempotent so partial completions were safe to resume.
- **Bounded turn budget per function** (24 max, 3 typical). Cost predictability followed directly from this. Cap × cost-per-turn × functions = a single number we could project, and reality came in cheaper than the projection.
- **Sandboxed tool layer with path allowlist.** Edits constrained to `vendor/wheels/**/*.cfc` + `vendor/wheels/public/docs/reference/<scope>/<name>.txt`. Several agent attempts to write outside the allowlist were correctly rejected at the tool layer. The agent never had to guess about scope; the tool either accepted or denied with a clear error.
- **`needs_human` as a real status.** When the View Helpers run hit the single-char filename constraint, the agent stopped cleanly with a precise diagnosis rather than fabricating a workaround. Worth more than another 87 successful runs combined.
- **Prompt caching.** System prompt + tool definitions + initial reads of large CFCs (`Global.cfc` is huge) cached once per section, then reused. Cache reads ran 90× cheaper than cache writes. This was the difference between "expensive" and "trivially affordable".

## What needed iteration

- **Initial turn cap of 16 was too tight.** First real run exhausted the budget on a successful function because the agent thrashed against `wheels cfml` thinking it could execute framework calls. Cap raised to 24, prompt clarified that `wheels cfml` is bare CFML (no framework loaded). Fixed in PR #2447.
- **Auto-finalize fallback was wrong twice.** First version promoted any file edit to `done` — would have mismarked CFC-only docblock edits and edit→revert cycles. Fix in PR #2447 split tracking into `referencesWritten` (the deliverable) vs. `filesChanged` (any touched file). Second nit caught in review: hardcoded "exhausted turn budget" message when the agent could also stop early via `stop_reason=end_turn`. Both fixed in the same PR before merge.
- **Agent fabricated APIs from function names.** `injector()` example used a made-up `register()` method because the agent only read `Global.cfc` (which just returns the container) and never followed through to `Injector.cfc`. Caught manually, fixed in #2457, prompt enhanced in #2458 ("when a function returns an object, also read the returned type's source"). Prevented similar issues on `controller()`, `model()`, etc. in later sections.
- **Style conventions drifted.** First batches mixed `WriteOutput`/`writeOutput` and used `<br>` HTML in iteration examples. Locked in via prompt update (#2451): camelCase for all CFML builtins, no HTML in example output. Re-ran the affected 6 functions with `force=true` to normalize.
- **Workflow timeout was 90 min.** Fine for the 7 small sections, broke on View Helpers (88 functions × ~5 turns × 30s + 3 min setup ≈ 140 min). Bumped to 240 in #2464.
- **CFML pipeline path resolution.** Most subtle bug. `helpers.cfm:475` called `$getExtendedCodeExamples("wheels/public/docs/reference/", slug)` without a leading slash — `ExpandPath()` resolved relative to the request template instead of via the `/wheels` mapping. All 378 v4 functions reported `extended.hasExtended=false`, hiding every example from the live site (including pre-existing v3 examples that had been working fine before some refactor). Diagnosed by comparing `hasExtended` counts across versioned snapshots (`v3.0.0.json`: 307/309 true, `v4.0.0.json`: 0/378 true). Fixed in #2449 with one character.

## Framework bugs caught (beyond docs)

The agent caught real, multi-year documentation gaps in the framework that a function-by-function manual review would have plausibly missed too. These all required reading source carefully and noticing the docblock disagreed with the code:

- **Polymorphic associations** undocumented. `belongsTo @polymorphic`, `hasMany @as`, `hasOne @as` — real, working parameters that had no `@param` doc. Users couldn't have known the feature existed from the API site.
- **`addErrorToBase` docblock copy-pasted from `addError`** — said it "Adds an error on a specific property" when it actually does the opposite (object-level error, no property).
- **`capitalize` docblock described `titleize`'s behavior** ("Capitalizes all words…"). Function only capitalizes the first character.
- **`singularize` had `@string` param** but the actual param is named `word`.
- **`sendFile @deliver`, `redirectTo @method`** — undocumented params.
- **`checkBox @value`** — wrong name, real param is `checkedValue`.
- **5 form-helper docblock copy-paste bugs** in `formsdateplain.cfc` (day/hour/minute/second select tags had each others' descriptions).
- **`count() @reload`** — stale param hint pointing at a parameter that no longer exists in the signature.

None of these are "bugs" in code behavior, but every one of them would have confused users reading the API docs.

## Cost / turn metrics

| Section | Avg turns | Notes |
|---|---|---|
| Model Class | 3.0 | After prompt fixes |
| Global Helpers | ~5 | Higher because Global.cfc cache miss on first reads |
| Model Object | ~3.2 | Tight |
| Configuration | 4.5 | Routing helpers return Mapper object → extra reads (prompt enhancement working as designed) |
| Model Configuration | ~3.4 | Polymorphic CFC fixes added a turn |
| Controller | ~3.7 | A few outliers (getEmails 11 turns) |
| Migrator | ~5 | Tabledefinition helpers all return objects |
| View Helpers | ~5 | Form helpers diverse |

3-turn floor: read source → write file → report. Higher turn counts correlate with: object-returning functions (need extra source read), CFC docblock edits (read + edit + verify), and complex examples needing extra read of related references.

## What I'd do differently

1. **Prompt the cheat sheet earlier.** The first batch produced HTML-output examples and mixed casing; locking conventions in the prompt could have happened in v0 of the prompt instead of v3. Saved one re-run cycle.
2. **Test the deploy chain before shipping the agent.** The `helpers.cfm` path resolution bug had been silently breaking v4 example rendering for who knows how long. The agent's output lit up the bug because suddenly examples *should* have been there, but I should have done a single-function test against a deployed snapshot before scaling up the pipeline.
3. **Wire `--function <name>` input on the workflow.** Re-running a specific function required either editing state.json by hand or burning the alphabetical-first slot. Worth ~30 minutes of work; would have saved more than that in cumulative friction.
4. **Pre-populate state.json with a single placeholder per function before the first run.** Would let the orchestrator distinguish "never attempted" from "completed in a different section" without surprises about cross-section overlap.

---

## Guides loop — plan

The guides corpus is fundamentally different from the API:

- **181 v4 guide pages** across 9 directory groups (`start-here`, `basics`, `core-concepts`, `digging-deeper`, `command-line-tools`, `database`, `testing`, `deployment`, `upgrading`). Plus `glossary.mdx` and `index.mdx`.
- **55 pages currently have any `{test:*}` annotations** (343 annotated code blocks total). The other 126 pages have NO annotated blocks — code is illustrative, untested.
- **Existing harness already validates annotated blocks.** `web/sites/guides/scripts/verify-docs/` runs `compile`/`cli`/`tutorial` drivers; CI gates PRs via `docs-verify.yml`.
- **The agent's job is different** — instead of writing examples in framework docblock files, it adds `{test:*}` annotations to existing blocks in `.mdx` files, fixes prose that's gone stale against current framework behavior, and surfaces which blocks genuinely can't be tested (illustrative-only, requires full app context, etc.).

### What changes in the agent design

1. **Per-page, not per-function.** State key is `guide:<path>` (e.g. `guide:basics/getting-started.mdx`). Each agent run takes one page.
2. **Different prompt, same orchestrator.** New `tools/docs-validation/agent/prompt-guide.md`. Reuse `orchestrate.mjs`, state, snapshot, sandboxed tools.
3. **Edit scope shifts.** Agent edits `.mdx`/`.md` files under `web/sites/guides/src/content/docs/v4-0-0-snapshot/` (new write glob). May still edit `vendor/wheels/**/*.cfc` for docblock drift the agent finds while validating, but reference `.txt` files are out of scope for this loop.
4. **Validation is the existing harness.** Agent calls `pnpm --filter @wheels/guides verify:docs <path>` to validate just the page it just edited. Exit 0 = annotations work; non-zero = broken example or annotation mismatch; agent revises and retries (up to turn cap).
5. **Per-section dispatch maps to top-level directories.** Instead of `Configuration`/`Controller`/etc., the workflow input becomes one of: `start-here`, `basics`, `core-concepts`, `digging-deeper`, `command-line-tools`, `database`, `testing`, `deployment`, `upgrading`. Each is a small batch (10–30 pages each).

### Per-page agent workflow

1. **Read the page.** `read_file` on the `.mdx`.
2. **Enumerate untagged code blocks.** Anything in fenced ```cfm/```bash/```sh that doesn't carry a `{test:*}` meta is a candidate.
3. **For each candidate, decide:**
   - **Compile-validate** (`{test:compile}`): standalone CFML expression that doesn't depend on app state. Single statements, struct literals, function definitions in isolation. Most idiomatic snippets fall here.
   - **CLI-validate** (`{test:cli cmd="..."}`): a `wheels` CLI command. Annotate with the command and expected output.
   - **Tutorial-validate** (`{test:tutorial step=N file="path"}`): code that needs to land in a fixture app and serve a request. Steps are sequenced across files.
   - **Illustrative-only** (no annotation): code that demonstrates an API surface that can't be exercised in isolation (e.g. a snippet referencing imaginary models, or showing an error message). Mark with `title="illustrative"`.
4. **Reconcile prose.** If the page describes behavior that contradicts current framework, fix the prose. Same authority as API loop: docblock-drift fixes allowed.
5. **Run validation.** `pnpm --filter @wheels/guides verify:docs <relative-path>`. If pass, write changes and `report_outcome status="done"`. If fail, revise; if budget runs out with annotations applied but verify failing, `report_outcome status="needs_human"` with the failure tail.

### State key & idempotency

```
state.json items:
  "guide:basics/getting-started.mdx": { ... }
  "guide:core-concepts/routing.mdx":  { ... }
```

Status semantics same as API loop. `--force` re-runs already-`done` pages (useful if framework changes break previously-validated annotations).

### Open design questions to resolve before building

1. **Should the agent edit `vendor/wheels/**/*.cfc` for drift it finds in guides?** Probably yes for docblock-only fixes (continues the API-loop pattern), but worth confirming. Could also be scoped to docblock-only edits matching the v4 snapshot's source-of-truth hint.
2. **Tutorial-step ordering across files** — the existing harness orders by `(frontmatter sidebar.order, step, file line)`. The agent needs to read the sidebar order to assign coherent step numbers. May require an extra context piece in the user message.
3. **What's the right batch size?** API was per-section (~30–88 functions). Guides natural batches are top-level dirs (10–30 pages). Probably fine; per-page agents are cheaper than per-function (less framework source to read), so a section can run in one dispatch with the existing 240-min timeout.
4. **Cost projection.** If per-page averages 6 turns × 25K input tokens + heavy cache use, that's ~$0.15/page × 181 pages ≈ **$27 total**. In line with API ($30–35). Worth confirming on the smallest section (`upgrading` or `start-here`) first.
5. **Prose-drift edits to mdx vs. tutorial-step ordering.** A page that's mostly prose with a few inline snippets is mostly a "fix prose, lightly annotate" task. A tutorial chapter is mostly "annotate every block in step order". The prompt should distinguish these.

### Build order

1. **Day 1**: branch new prompt at `tools/docs-validation/agent/prompt-guide.md`. Update `tools.mjs` to add `WRITE_GLOBS_GUIDE` allowlist for `web/sites/guides/src/content/docs/v4-0-0-snapshot/**/*.{md,mdx}`. Add `--mode=guide --path <relative>` plumbing to `orchestrate.mjs`.
2. **Day 1**: smoke-test against one small page locally (no API key needed for the dry-run path).
3. **Day 1**: extend the workflow with a `mode` input (`api`/`guide`) and a `path` input for guide mode. Or split into two workflows; cleaner.
4. **Day 1**: dispatch the smallest section (`upgrading`, ~6 pages) live as proof of concept.
5. **Day 2**: review output. Tune prompt. Scale to remaining 8 sections one at a time.

### Success criteria

- Every code block in `web/sites/guides/src/content/docs/v4-0-0-snapshot/` either carries a `{test:*}` annotation that passes `verify-docs`, or is explicitly marked `title="illustrative"` with a justification.
- `docs-verify.yml` (CI gate on guide PRs) stays green at full coverage instead of soft-failing on missing annotations.
- Total cost ≤ 1.5× API run, given guides are smaller per-item but more numerous.

## Closing notes

The cheapest way to validate documentation isn't to write better docs from scratch — it's to surface the disagreements between docs and code, then let an agent decide which side is wrong on each one. The agent finds gaps a human reviewer would skim past (`@param` copy-pastes, type names, undocumented parameters) because the agent reads carefully every time.

The bigger win was unrelated to docs accuracy: by making the agent's output flow through the deployment pipeline, we surfaced the `helpers.cfm` path bug that had been silently hiding all v4 examples on the live site. A doc-quality task became an end-to-end sanity check of the docs production chain.
