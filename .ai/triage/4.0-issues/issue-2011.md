# Issue #2011: Core framework tests are placed inside application tests instead of core tests

## Verdict
FIX NOW

## Summary
The `tests/specs/` directory (intended as an **app-level** example suite shipped with the framework template) currently contains 11 spec files plus supporting fixtures that exercise core framework APIs (`findEach`, `findInBatches`, query scopes, enums, query builder, pagination helpers, `env()` helper, middleware pipeline/order-resolver/rate-limiter, route model binding). These belong in `vendor/wheels/tests/specs/` so they run in the core test suite (`/wheels/core/tests`) across every engine × DB matrix. Move the specs, merge the test-model and populate-schema deltas into the core fixtures, and reduce `tests/specs/` back to a minimal app-starter example.

## Root cause
Release-phase PRs (batch processing, query builder, query scopes, enums, pagination, middleware pipeline, route model binding, `env()` helper) landed spec files under `tests/specs/` — the app suite — rather than `vendor/wheels/tests/specs/` — the core suite. Per CLAUDE.md: "Core tests: `vendor/wheels/tests/specs/` — framework tests… This is what CI runs across all engines × databases." The app suite should ship as a starter (one `ExampleSpec`), so contributors and Wheels users don't see framework internals when they click the Tests tab on a scaffolded app.

Misplaced spec files (all in `tests/specs/`):

1. `models/BatchProcessingSpec.cfc` — tests `findEach()` / `findInBatches()` on `Model.cfc`; no equivalent exists under `vendor/wheels/tests/specs/model/`. Core framework behavior.
2. `models/EnumSpec.cfc` — tests `is*()` checkers and auto-generated `<value>()` scopes on enum-decorated models. Core behavior. Requires a `status` column on `c_o_r_e_posts` that does not exist in `vendor/wheels/tests/populate.cfm`. The core suite already has `model/enumScopeEscapingSpec.cfc` (SQL-escaping) and `security/EnumScopeSqlSpec.cfc` (injection) but zero end-to-end enum spec.
3. `models/QueryBuilderSpec.cfc` — tests `.where()/.orWhere()/.whereIn()/.orderBy()/.get()` chainable API. Core behavior. Note: `vendor/wheels/tests/specs/QueryBuilderSpec.cfc` exists at the top level — confirm during move whether they overlap; ship either a merge or a second file under `model/`.
4. `models/QueryScopesSpec.cfc` — tests user-defined and dynamic scopes. Core behavior. Depends on a new fixture model `AuthorScoped.cfc` that only lives under `tests/_assets/models/`.
5. `view/PaginationHelpersSpec.cfc` — tests `paginationInfo`, `paginationNav`, `pageNumberLinks`, first/prev/next/last helpers. Core behavior. No pagination spec exists under `vendor/wheels/tests/specs/view/`.
6. `middleware/MiddlewareOrderResolverSpec.cfc` — tests `wheels.middleware.MiddlewareOrderResolver`. Core behavior. Ships with three helper middleware CFCs under `_helpers/`.
7. `middleware/MiddlewarePipelineSpec.cfc` — tests `wheels.middleware.Pipeline`. Core behavior. Uses `tests.specs.middleware._helpers.*` imports via dotted path.
8. `middleware/RateLimiterSpec.cfc` — smaller variant of the same spec that already exists under `vendor/wheels/tests/specs/middleware/RateLimiterSpec.cfc` (377 vs 653 lines). Duplicate — delete the app-level one after confirming no unique assertions.
9. `middleware/_helpers/BlockingMiddleware.cfc`, `EnrichingMiddleware.cfc`, `TrackingMiddleware.cfc` — test fixtures for #6 + #7, not tests themselves; move with the specs.
10. `dispatch/RouteModelBindingSpec.cfc` — tests `Dispatch.$resolveRouteModelBinding()`. Core behavior. No equivalent exists in `vendor/wheels/tests/specs/dispatch/`.
11. `functional/EnvHelperSpec.cfc` — tests `env()` defined in `vendor/wheels/Global.cfc:410`. Core behavior.

Keep in place:
- `functional/ExampleSpec.cfc` — genuine app-starter example (asserts `"true" == true`). This is what should live here.

Test fixtures that must follow the moves:
- `tests/_assets/models/AuthorScoped.cfc` (referenced only by QueryScopesSpec)
- `tests/_assets/models/PostWithEnum.cfc` (referenced only by EnumSpec)
- The `status` column on `c_o_r_e_posts` + published/archived seed rows added to `tests/populate.cfm` — required by EnumSpec, must be back-ported to `vendor/wheels/tests/populate.cfm` so the moved spec keeps passing.

## Files to change

Moves (spec → core):

| From | To |
|------|-----|
| `tests/specs/models/BatchProcessingSpec.cfc` | `vendor/wheels/tests/specs/model/batchProcessingSpec.cfc` |
| `tests/specs/models/EnumSpec.cfc` | `vendor/wheels/tests/specs/model/enumSpec.cfc` |
| `tests/specs/models/QueryBuilderSpec.cfc` | `vendor/wheels/tests/specs/model/queryBuilderSpec.cfc` (see note re top-level `QueryBuilderSpec.cfc`) |
| `tests/specs/models/QueryScopesSpec.cfc` | `vendor/wheels/tests/specs/model/queryScopesSpec.cfc` |
| `tests/specs/view/PaginationHelpersSpec.cfc` | `vendor/wheels/tests/specs/view/paginationHelpersSpec.cfc` |
| `tests/specs/middleware/MiddlewareOrderResolverSpec.cfc` | `vendor/wheels/tests/specs/middleware/MiddlewareOrderResolverSpec.cfc` |
| `tests/specs/middleware/MiddlewarePipelineSpec.cfc` | `vendor/wheels/tests/specs/middleware/MiddlewarePipelineSpec.cfc` |
| `tests/specs/middleware/_helpers/BlockingMiddleware.cfc` | `vendor/wheels/tests/specs/middleware/_helpers/BlockingMiddleware.cfc` |
| `tests/specs/middleware/_helpers/EnrichingMiddleware.cfc` | `vendor/wheels/tests/specs/middleware/_helpers/EnrichingMiddleware.cfc` |
| `tests/specs/middleware/_helpers/TrackingMiddleware.cfc` | `vendor/wheels/tests/specs/middleware/_helpers/TrackingMiddleware.cfc` |
| `tests/specs/dispatch/RouteModelBindingSpec.cfc` | `vendor/wheels/tests/specs/dispatch/routeModelBindingSpec.cfc` |
| `tests/specs/functional/EnvHelperSpec.cfc` | `vendor/wheels/tests/specs/global/envHelperSpec.cfc` (core uses `global/` for Global.cfc helpers) |
| `tests/_assets/models/AuthorScoped.cfc` | `vendor/wheels/tests/_assets/models/AuthorScoped.cfc` |
| `tests/_assets/models/PostWithEnum.cfc` | `vendor/wheels/tests/_assets/models/PostWithEnum.cfc` |

Delete (duplicate):

- `tests/specs/middleware/RateLimiterSpec.cfc` — the core `vendor/wheels/tests/specs/middleware/RateLimiterSpec.cfc` is the authoritative, larger version. Diff first and port any unique assertions back into the core version, then delete the app copy.

Modify:

- `vendor/wheels/tests/populate.cfm` — add `status varchar(20) DEFAULT 'draft' NOT NULL` column to `c_o_r_e_posts` CREATE TABLE and add enum-bearing seed rows (draft/published/archived) matching what `tests/populate.cfm` seeds today. Keep DB-agnostic (verified SQL-Server/MySQL/Postgres/H2/SQLite identity paths are present).
- `tests/populate.cfm` — can drop the `status` column and the published/archived seed rows after the moves; leave the authors + posts seeds because the remaining `ExampleSpec` doesn't depend on them, but retaining the minimal authors/posts skeleton matches what a scaffolded Wheels app ships with. Judgment call — acceptable to simplify to bare fixture tables.
- `tests/_assets/models/Author.cfc`, `Post.cfc`, `Model.cfc` — decide whether to strip the app-starter down to an empty `tests/` skeleton (matches CLAUDE.md statement "Application tests should typically remain empty") or keep the minimal seed so the starter template runs out-of-the-box. Recommendation: keep Author/Post/Model minimally because `ExampleSpec` plus any future generator-emitted spec will want a working `populate.cfm` path.
- Any dotted-path CFC references inside the moved pipeline spec: `new tests.specs.middleware._helpers.TrackingMiddleware(...)` → `new wheels.tests.specs.middleware._helpers.TrackingMiddleware(...)`. Same for BlockingMiddleware + EnrichingMiddleware (six occurrences in MiddlewarePipelineSpec). Grep the moved file for `tests.specs.middleware._helpers` and update.
- If any moved spec imports `tests._assets.models.*` by dotted path, update to `wheels.tests._assets.models.*`. Grep each moved spec.

## Implementation steps

Use `git mv` so history is preserved. Run from repo root.

1. **Baseline: capture current pass count.** Start the test server and run both suites so regressions are detectable after moves.
   ```bash
   bash tools/test-local.sh 2>&1 | tee /tmp/baseline-core.txt
   curl -sf "http://localhost:8080/wheels/app/tests?db=sqlite&format=json" | \
     python3 -c "import json,sys; d=json.load(sys.stdin); print(f'app: {d[\"totalPass\"]} pass, {d[\"totalFail\"]} fail, {d[\"totalError\"]} error')" | tee /tmp/baseline-app.txt
   ```

2. **Update `vendor/wheels/tests/populate.cfm` first** so the moved `EnumSpec` has a `status` column to query.
   - In the `CREATE TABLE c_o_r_e_posts` block (~line 198), add after `averagerating`: `,status varchar(20) DEFAULT 'draft' NOT NULL`.
   - Mirror the DB-agnostic default for SQLite if needed (it accepts the same literal).
   - In the seed-posts section, update existing `createPost(...)` calls to pass `status = "published" | "archived" | "draft"` so there is at least one row per enum value (match what `tests/populate.cfm` lines 67-74 do today).
   - Verify: `bash tools/test-local.sh model` passes before moving any specs.

3. **Move the test fixtures** so they exist when the specs arrive.
   ```bash
   git mv tests/_assets/models/AuthorScoped.cfc vendor/wheels/tests/_assets/models/AuthorScoped.cfc
   git mv tests/_assets/models/PostWithEnum.cfc vendor/wheels/tests/_assets/models/PostWithEnum.cfc
   ```

4. **Move model specs:**
   ```bash
   git mv tests/specs/models/BatchProcessingSpec.cfc  vendor/wheels/tests/specs/model/batchProcessingSpec.cfc
   git mv tests/specs/models/EnumSpec.cfc             vendor/wheels/tests/specs/model/enumSpec.cfc
   git mv tests/specs/models/QueryScopesSpec.cfc      vendor/wheels/tests/specs/model/queryScopesSpec.cfc
   ```

5. **QueryBuilder spec — reconcile with top-level `vendor/wheels/tests/specs/QueryBuilderSpec.cfc`.** Diff them:
   ```bash
   diff tests/specs/models/QueryBuilderSpec.cfc vendor/wheels/tests/specs/QueryBuilderSpec.cfc
   ```
   If the top-level file is interface-only / narrower, fold the app-test assertions into it (prefer appending; that file is already core-cited). Otherwise `git mv` to `vendor/wheels/tests/specs/model/queryBuilderSpec.cfc` — placing runtime specs under `model/` is consistent with `enumScopeEscapingSpec`, `scopeHandlerSanitizationSpec`, etc.

6. **Move pagination spec:**
   ```bash
   git mv tests/specs/view/PaginationHelpersSpec.cfc vendor/wheels/tests/specs/view/paginationHelpersSpec.cfc
   ```
   Verify the top of the moved file still says `g = application.wo` — that pattern is used throughout the core view specs, so no rewrite needed.

7. **Move middleware specs + helpers:**
   ```bash
   mkdir -p vendor/wheels/tests/specs/middleware/_helpers
   git mv tests/specs/middleware/_helpers/BlockingMiddleware.cfc  vendor/wheels/tests/specs/middleware/_helpers/
   git mv tests/specs/middleware/_helpers/EnrichingMiddleware.cfc vendor/wheels/tests/specs/middleware/_helpers/
   git mv tests/specs/middleware/_helpers/TrackingMiddleware.cfc  vendor/wheels/tests/specs/middleware/_helpers/
   git mv tests/specs/middleware/MiddlewareOrderResolverSpec.cfc  vendor/wheels/tests/specs/middleware/MiddlewareOrderResolverSpec.cfc
   git mv tests/specs/middleware/MiddlewarePipelineSpec.cfc       vendor/wheels/tests/specs/middleware/MiddlewarePipelineSpec.cfc
   ```
   Then rewrite dotted paths inside `MiddlewarePipelineSpec.cfc` (six occurrences per current grep):
   ```
   tests.specs.middleware._helpers.TrackingMiddleware  → wheels.tests.specs.middleware._helpers.TrackingMiddleware
   tests.specs.middleware._helpers.BlockingMiddleware  → wheels.tests.specs.middleware._helpers.BlockingMiddleware
   tests.specs.middleware._helpers.EnrichingMiddleware → wheels.tests.specs.middleware._helpers.EnrichingMiddleware
   ```

8. **Reconcile the duplicate `RateLimiterSpec.cfc`.**
   ```bash
   diff tests/specs/middleware/RateLimiterSpec.cfc vendor/wheels/tests/specs/middleware/RateLimiterSpec.cfc
   ```
   Port any assertions present only in the app version into the core version. Then:
   ```bash
   git rm tests/specs/middleware/RateLimiterSpec.cfc
   ```

9. **Move dispatch spec:**
   ```bash
   git mv tests/specs/dispatch/RouteModelBindingSpec.cfc vendor/wheels/tests/specs/dispatch/routeModelBindingSpec.cfc
   ```

10. **Move env helper spec:**
    ```bash
    git mv tests/specs/functional/EnvHelperSpec.cfc vendor/wheels/tests/specs/global/envHelperSpec.cfc
    ```

11. **Clean up empty app-test directories.** After the moves, `tests/specs/models/`, `tests/specs/middleware/`, `tests/specs/dispatch/`, `tests/specs/view/` will be empty. Either `rmdir` them or leave stub `.keep` files if the scaffold template expects them. Check how `wheels generate app` and the `wheels test` generator handle missing directories; match that behavior.

12. **Strip ported seed data from `tests/populate.cfm`** if it is no longer needed by the single remaining `ExampleSpec`. ExampleSpec does not touch models, so the minimal option is to leave only the `c_o_r_e_authors` + `c_o_r_e_posts` CREATE-and-seed (kept as a starter example for generator output). Do *not* delete `tests/populate.cfm` entirely — the `TestRunner.cfc` includes it unconditionally when `url.populate != false`.

13. **Reload + re-run both suites.** Append `&reload=true` once after the moves so Wheels picks up the new model/spec CFCs.

14. **Commit with `test` scope** per CLAUDE.md ("valid commit scope for test moves is `test`"):
    - `test(test): move core framework specs from app tests to core tests`
    - Body: list of moved files + note about `populate.cfm` schema update + duplicate `RateLimiterSpec` deletion.

## Testing

Run both suites and confirm zero regressions vs the baseline captured in step 1.

```bash
# Core suite — this is the one that must stay green across engines × DBs
bash tools/test-local.sh                                    # all core dirs
bash tools/test-local.sh model                              # moved: batch, enum, queryBuilder, queryScopes
bash tools/test-local.sh middleware                         # moved: MiddlewareOrderResolver, MiddlewarePipeline, RateLimiter
bash tools/test-local.sh view                               # moved: paginationHelpers
bash tools/test-local.sh dispatch                           # moved: routeModelBinding

# App suite — should still run, now effectively only ExampleSpec
curl -sf "http://localhost:8080/wheels/app/tests?db=sqlite&format=json" | \
  python3 -c "import json,sys; d=json.load(sys.stdin); print(f'{d[\"totalPass\"]} pass, {d[\"totalFail\"]} fail, {d[\"totalError\"]} error')"

# Cross-engine smoke (per CLAUDE.md — Lucee + Adobe minimum before push)
cd rig && docker compose up -d lucee6 adobe2025
sleep 60
for port in 60006 62025; do
  curl -sf "http://localhost:$port/wheels/core/tests?db=sqlite&format=json" | \
    python3 -c "import json,sys; d=json.load(sys.stdin); print(f'port $port: {d[\"totalPass\"]} pass, {d[\"totalFail\"]} fail, {d[\"totalError\"]} error')"
done
```

Expected: core pass count rises by ~the number of assertions in the moved specs; app pass count drops to ExampleSpec's single assertion; zero failures, zero errors across both suites and both engines.

## Risk & dependencies

- **Populate.cfm schema change is the hot spot.** Adding the `status` column to the core `c_o_r_e_posts` table is load-bearing for every database engine's SQL. Verify no existing core spec queries `c_o_r_e_posts` with column-count-sensitive assertions (e.g. `SELECT *` row-shape checks, introspection specs). `vendor/wheels/tests/specs/model/introspectionSpec.cfc` is the most likely bite — read it before committing the schema delta.
- **Dotted-path rewrites in `MiddlewarePipelineSpec.cfc`** are mandatory or the spec will CFC-lookup-fail under the new location. Grep for `tests.specs.middleware._helpers` after the move; count must be zero.
- **Model fixtures under `tests/_assets/models/`** referenced by core (`Author.cfc`, `Post.cfc`) are the thinner app-starter copies. They already coexist with the fuller core versions under `vendor/wheels/tests/_assets/models/`. The moves don't touch them; they stay as app starters.
- **Related issues / PRs.** None blocking. This is tidy-up in service of the 4.0 GA bar: "what a user sees when they click the Tests tab on a scaffolded app should be a minimal example, not framework internals" (issue wording).
- **Are the displaced tests actually testing framework or app behavior?** All 11 moved specs test framework code (model methods on `Model.cfc`, helpers in `wheels.Global`, middleware under `wheels.middleware.*`, dispatch logic, view helpers). The only truly app-level spec is `ExampleSpec.cfc`, which stays.
- **populate.cfm** — `tests/populate.cfm` (app) and `vendor/wheels/tests/populate.cfm` (core) are different enough that we can't just delete the app one. Keep both. Back-port only the minimal delta (status column + seed rows) to core. Strip from app optionally.
- **Generator behavior.** If `wheels generate test …` emits specs into `tests/specs/…` (per the README), it will continue to work — we're moving the *framework's own* misplaced specs, not the generator target.

## Effort estimate
M — about a dozen `git mv` calls plus a careful `populate.cfm` schema merge, dotted-path rewrite in one spec, and a diff-merge of the duplicate `RateLimiterSpec`. Full cross-engine smoke test before PR. ~3–4 hours with the matrix run dominating the wall-clock.
