# Wheels v4.0 GA — Architectural Review
**Date:** 2026-04-22
**Method:** 6 parallel audit subagents (framework core / CLI+LuCLI / packages / test infra / app skeleton / public API+upgrade path), each applying 10 lenses (API consistency, cross-engine, coupling, deprecation, dead code, tests, security, perf, docs drift, upgrade path).
**Total raw findings:** 75. After dedup + re-triage by main reviewer: ~60 distinct items.
**Status:** Findings consolidated. Awaiting user triage into GA-blocker / v4.1 / v5.0 / won't-fix buckets.

---

## Executive summary

The framework is in **good shape for GA**. No finding surfaces a broken public API, corrupted data path, or unpatchable security hole. The blockers that *do* exist are largely:
- **Docs hygiene** (CHANGELOG misses the `viteStrictManifest` breaking change; version string hardcoded with a TODO next to it)
- **CLI divergence** (legacy `cli/src/` CommandBox module still defaults to 3.1.0 template, LuCLI canonical surface is correct)
- **Test-gate honesty** (browser-test CI infrastructure installed but `WHEELS_BROWSER_CI_ENABLE` not flipped, so browser specs silently skip)
- **Ecosystem scaffolding** (PackageLoader accepts `wheelsVersion` constraints but never validates; no package-creation guide; no distribution story)

**Agent severity distribution (before re-triage):**
| | Blockers | Major | Minor |
|---|---|---|---|
| Framework core | 0 | 1 | 9 |
| CLI / LuCLI | 5 | 6 | 4 |
| Packages | 0 | 4 | 6 |
| Test infra | 0 | 4 | 6 |
| App skeleton | 3 | 2 | 10 |
| Public API + upgrade | 2 | 5 | 8 |
| **Total** | **10** | **22** | **43** |

**After main-reviewer re-triage (rough):** real blockers ~4–6, majors ~15, rest minor. Several agent-flagged "blockers" miscategorized (e.g., `deploy server exec` shell injection — that command's *purpose* is running arbitrary shell via SSH).

---

## Cross-cutting themes

1. **Two CLIs still ship.** `cli/src/` (legacy CommandBox module) and `cli/lucli/` (canonical LuCLI). The legacy one defaults to 3.1.0 templates and has weaker defaults. Decision needed for GA: remove `cli/src/`, freeze it, or ship both with clear deprecation.
2. **Deprecation hygiene uneven.** `plugins/` folder warns but has no sunset version. `wheels.Test` class deprecated silently. `vendor/wheels/public/mcp/` marked deprecated with no removal schedule. Pattern of "deprecated but no end date" across the codebase.
3. **Doc drift from v3.x.** README claims Lucee 5.x but code floor is 5.3.2. CHANGELOG's "Breaking" section misses `viteStrictManifest`. Upgrade guide omits enums. CLAUDE.md references `app/db/seeds/` that doesn't exist.
4. **Ecosystem gaps.** Packages system ships but has no creation guide, no distribution channel, no tests for PackageLoader, no collision detection.
5. **Security hygiene is defensive-in-depth, not blocking.** Most "security" findings are paths that require user error or untrusted input where none should flow. Real audit items: Public.cfc prod-gating, deploy-config path validation (if deploy.yml is ever untrusted).

---

## Findings by layer

Severity below is the **re-triaged severity** (mine, after verification where possible). Agent's original severity noted where I downgraded/upgraded.

### Layer 1: Framework core (`vendor/wheels/`)

| # | Severity | Finding | Location | Note |
|---|---|---|---|---|
| F1 | **major** | `Public.cfc` methods implicitly public — routes like `/wheels/public/info`, `/routes`, `/routetester`, `/testbox` expose debug/test tools | `vendor/wheels/Public.cfc:14-252` | Need to verify: is `/wheels/public/*` routable in prod? If yes, **blocker**. Existing config/routes.cfm should prod-gate. |
| F2 | minor | `Migration.cfc` throws with undefined `#dbType#` in error message | `vendor/wheels/migrator/Migration.cfc:5-10` | Shadowed-variable bug in error message — broken error for unsupported DBs |
| F3 | minor | `vendor/wheels/public/mcp/` still shipped, marked deprecated, no removal date | `vendor/wheels/public/mcp/` | Schedule removal for v4.1 — users have migrated |
| F4 | minor | Lucee 7 `Left(str,0)` guard applied in one spot only | `vendor/wheels/view/links.cfc:564` | Sweep for other `Left(...)` / `Mid(...)` / `Right(...)` call sites |
| F5 | minor | `$getDBType()` silent empty return on unknown DB | `vendor/wheels/migrator/Base.cfc:77` | Caller throws, but helper should fail clearly |
| F6 | minor | `$include()` template path accepts any string | `vendor/wheels/Global.cfc:110-131` | Internal API ($-prefix); low risk, harden anyway |
| F7 | minor | Finder default params inconsistent (`"-1"` quoted numeric, empty strings for bools) | `vendor/wheels/model/read.cfc:30-54` | Cleanup pass, post-GA |
| F8 | minor | `$escapeSqlValue()` marked deprecated but used internally in scope handlers | `vendor/wheels/model/properties.cfc:716-758` | Decide: remove deprecation flag or route scope handlers off it |
| F9 | minor | `Seeder.runSeeds()` no re-entrance guard | `vendor/wheels/Seeder.cfc:40-71` | Defensive; user error needed to hit |
| F10 | minor | Error-type conventions inconsistent (`wheels.model.migrate.*` vs ad-hoc throws in adapters) | `vendor/wheels/databaseAdapters/Base.cfc` | Internal; post-GA normalization |

**Layer assessment:** Healthy. F1 needs verification. Everything else is polish.

---

### Layer 2: CLI / LuCLI (`cli/`)

I pruned the agent's over-flagged security findings — several blockers the agent cited are the command's *designed behavior* (e.g., `deploy server exec` runs arbitrary shell by definition, same as `ssh host cmd`).

| # | Severity | Finding | Location | Note |
|---|---|---|---|---|
| C1 | **blocker** | Legacy `wheels g app` (CommandBox CLI) defaults to `wheels-base-template@^3.1.0` despite docstring saying "Default is Bleeding Edge" | `cli/src/commands/wheels/generate/app.cfc:71` | **Verified.** LuCLI `wheels new` is canonical, but legacy CLI still ships on ForgeBox — users doing `box install wheels-cli && wheels g app` get a 3.x scaffold at 4.0 GA. Either update default to 4.0 template slug, or remove/deprecate legacy CLI entirely. |
| C2 | **blocker** | `viteStrictManifest` breaking change not in CHANGELOG "Breaking" section, not in upgrade guide | `CHANGELOG.md:60` | **Verified.** Default `true` + hard error on missing manifest = breaking vs 3.x silent fallback. Deploy procedure docs and upgrade guide both need the warning. |
| C3 | major | Silent-exit commands return `""` when no server running, hiding failures from MCP clients/scripts | `cli/lucli/Module.cfc` — `routes()`, `reload()`, `runTests()`, `console()` | Recent PRs #2214/#2219/#2221 fixed several silent-exit paths; this list needs a re-scan to confirm coverage. |
| C4 | major | `wheels deploy` returns `dryRunOutput()` unconditionally — blank output on real (non-dry-run) deploys | `cli/lucli/Module.cfc:1309-1525` | Needs verification; if true, users see blank screen on successful deploy |
| C5 | major | MCP command surface has no typed params — schemas come back empty | `cli/lucli/Module.cfc:129-1844` | Plan B2 tracks this (cybersonic/LuCLI#54 + Wheels follow-up PR). If Plan B2 doesn't land before 4.0 tag, this degrades MCP DX but isn't release-blocking. |
| C6 | major | Deploy config path (`--config-path=`) not validated against project root | `cli/lucli/Module.cfc:1298-1300`, `DeployMainCli.cfc:56-58` | Only an issue if deploy.yml ever comes from untrusted source; low risk but easy to harden |
| C7 | major | `wheels deploy init` writes to paths from flags without normalization | `DeployMainCli.cfc:285-323` | Same scope as C6 — user's own machine, user-provided paths, but still worth `expandPath` + project-root check |
| C8 | minor | Duplicate entry points `wheels new` vs `wheels create app` share implementation via `__arguments` trick | `cli/lucli/Module.cfc:170-174, 485-487, 392-456` | Maintainability risk; consolidate helper |
| C9 | minor | `console` REPL hides from MCP correctly but prints no helpful error when stdin is piped | `cli/lucli/Module.cfc:641-782` | Polish |
| C10 | minor | `--key=value` vs `--key value` parsing inconsistent across commands | `cli/lucli/Module.cfc` throughout | Standardize |
| C11 | minor | `wheels upgrade check` lacks docs page under command-line-tools/ | `cli/lucli/Module.cfc:1796-1820` | Add to docs/src/command-line-tools/ |
| C12 | minor | `wheels new` framework-source resolution order undocumented in help | `cli/lucli/Module.cfc:3447-3489` | Recent PR #2215 hard-fails on bad `WHEELS_FRAMEWORK_PATH`; help text should explain |
| C13 | minor | Secret-adapter wiring implicit in `DeploySecretsCli` init | `cli/lucli/services/deploy/cli/DeploySecretsCli.cfc` | Extract factory |
| C14 | minor | CLI commands typed `public string function ... return ""` — mixed signal vs stdout capture | `cli/lucli/Module.cfc` | Standardize to `void` or structured result |
| C15 | minor | Legacy `cli/src/` shares monorepo but points at 3.x docs (`wheels.dev/3.1.0/`) in comments | `cli/src/*` | Sunset plan needed |

**Layer assessment:** Functional. C1 and C2 are the two real GA blockers. C3–C7 are major polish items.

---

### Layer 3: Packages system

| # | Severity | Finding | Location | Note |
|---|---|---|---|---|
| P1 | major | `wheelsVersion` in package.json never validated against runtime version | `vendor/wheels/PackageLoader.cfc:27, 486-503` | Constraint is accepted and stored but never checked. Parse SemVer and reject incompatible packages. |
| P2 | major | No mixin collision detection across packages/plugins | `vendor/wheels/PackageLoader.cfc:395-396`, `vendor/wheels/Plugins.cfc:14-23` | `mixinCollisions` array exists in `Plugins.cfc` but never populated. Silent method shadowing when two mixins define the same name. |
| P3 | major | No docs on creating third-party packages | none | Ecosystem blocker. Third-party authors have no official guide — CLAUDE.md documents the schema but no external-facing guide. |
| P4 | major | No distribution story for packages | none | Where do third-party packages live? ForgeBox? Git URLs? No answer. Consumers just "copy to vendor/". |
| P5 | major | No framework-level tests for PackageLoader | `vendor/wheels/tests/` | Loader has no spec coverage. Individual shipped packages have their own tests but the contract is unverified. |
| P6 | minor | `packages/basecoat/` and `packages/hotwire/` ship no README | `packages/basecoat/`, `packages/hotwire/` | `sentry/` and `legacyadapter/` have READMEs — inconsistent. |
| P7 | minor | `provides.mixins` target list silently accepts typos | `vendor/wheels/PackageLoader.cfc:274-280` | Validate against known mixableComponents list. |
| P8 | minor | `plugins/` sunset has warning but no target version | `vendor/wheels/Plugins.cfc:128-132` | State "removed in 5.0" in the deprecation message. |
| P9 | minor | Checksum feature supported but unused + undocumented | `vendor/wheels/PackageLoader.cfc:315-342` | Either document + adopt, or remove. |
| P10 | minor | Lazy package loading (`"lazy": true`) supported but undocumented and unused | `vendor/wheels/PackageLoader.cfc:287-304` | Document or remove. |

**Layer assessment:** Core loader works, ecosystem scaffolding is incomplete. For GA: fix P1 (real correctness bug), commit to P3+P4 story (doc + distribution plan), leave rest for v4.1.

---

### Layer 4: Test infrastructure

| # | Severity | Finding | Location | Note |
|---|---|---|---|---|
| T1 | **blocker** | Browser test CI gate `WHEELS_BROWSER_CI_ENABLE` never set in workflows — all browser specs silently skip despite Playwright install running in CI | `.github/workflows/pr.yml`, `snapshot.yml` | **Known gap** per v4.0 roadmap memory (3 fixture issues blocking). Either fix fixtures + flip gate, or honestly label browser testing as "shipped, CI verification deferred to v4.1" in release notes. |
| T2 | major | `sendfile` directory-test skipped with TODO comment in CI | `vendor/wheels/tests/specs/controller/miscellaneousSpec.cfc:172` | `skip("Temporarily skipping to debug path issues in CI")` — blocks verification of a public controller API. Investigate and unskip. |
| T3 | major | PR fast-gate runs only Lucee 7 + SQLite — Adobe CF / BoxLang regressions only caught post-merge in weekly snapshot | `.github/workflows/pr.yml` | Per CLAUDE.md, users are told to "verify Adobe locally before pushing" — honor-system. Add adobe2025 to PR gate as parallel job, or accept the trade-off and doc it. |
| T4 | major | Browser test fixtures brittle — `BrowserTest.beforeAll()` manually re-includes routes.cfm to work around other specs clearing routes | `vendor/wheels/wheelstest/BrowserTest.cfc:64-70` | Root cause: no per-spec route scoping. Fix: snapshot-and-restore pattern around specs that `$clearRoutes()`. |
| T5 | minor | `redomigration 001` skipped as `xit` with comment "passes individually, not in pack" | `vendor/wheels/tests/specs/migrator/migratorSpec.cfc:185` | Test-isolation bug; investigate transactions |
| T6 | minor | `SOFT_FAIL_DBS=""` (all DBs hard-gated) — correct but confusing | `.github/workflows/compat-matrix.yml:389, 519` | Leave as-is per CLAUDE.md; add code comment |
| T7 | minor | `rocketunit_tests/` (64 CFCs) still shipped but not wired into any CI job | `vendor/wheels/rocketunit_tests/` | Dead code — delete for GA or post-GA cleanup |
| T8 | minor | Job backoff formula untested | `vendor/wheels/tests/specs/jobs/JobWorkerSpec.cfc` | Add coverage |
| T9 | minor | Enum cross-DB scope generation untested | `vendor/wheels/tests/specs/security/EnumScope*.cfc` | Extend to loop DB types |
| T10 | minor | `BrowserIntegrationSpec` inconsistent `this.browserTestSkipped` guards | `vendor/wheels/tests/specs/wheelstest/BrowserIntegrationSpec.cfc` | Audit all `it()` blocks |

**Layer assessment:** Mostly serviceable. T1 is the big GA honesty item: CI tells users browser tests run, but they silently skip. Either fix or tell the truth.

---

### Layer 5: App skeleton + generator output

| # | Severity | Finding | Location | Note |
|---|---|---|---|---|
| A1 | **blocker** | LuCLI `wheels mcp setup` generates `.mcp.json` / `.opencode.json` — verify this works at GA for first-run users (no `wheels console` over stdio etc.) | `cli/lucli/Module.cfc` | Part of canonical MCP surface — should be verified end-to-end. (Claim in summary was App-F14; real issue lives in C1.) |
| A2 | major | `.env.example` missing; new contributors don't know what env vars are expected | project root | Generate `.env.example` in app template with `WHEELS_ENV`, `BASE_URL` commented |
| A3 | major | `public/Application.cfc` loads `.env` files with no production-mode guard | `public/Application.cfc:58-95` (template) | Warn or refuse `.env` load when `WHEELS_ENV=production`; force system-env vars in prod |
| A4 | minor | CLAUDE.md references `app/db/seeds.cfm` and `app/db/seeds/` — neither exists in current repo | `CLAUDE.md:8-9` | CLAUDE.md drift; update or create directories |
| A5 | minor | Framework repo's own `config/settings.cfm:29` has `reloadPassword="wheels-dev"` | `config/settings.cfm:29` | Templates correctly use `{{reloadPassword}}` + `generateRandomPassword()`, so generated apps are fine. Framework's own dev config is the only one using this. Acceptable, but CLI's `config:check` should flag it. |
| A6 | minor | Default `app/views/layout.cfm` lacks HTML5 doctype / charset / viewport / lang | `app/views/layout.cfm:9-20` | First-run polish |
| A7 | minor | Config files `config/production/settings.cfm` and `config/development/settings.cfm` are empty (comments only) | `config/*/settings.cfm` | Add commented examples of common prod overrides (`showDebugInformation=false`, etc.) |
| A8 | minor | Default layout lacks Vite integration example | `app/views/layout.cfm` | Commented `viteScriptTag()` / `viteStyleTag()` |
| A9 | minor | CSRF meta-tag call in layout but no explicit `enableCSRFProtection=true` in settings.cfm | `app/views/layout.cfm:11`, `config/settings.cfm` | Make the setting visible |
| A10 | minor | `public/.htaccess` minimal; no modern security headers or file-denial directives | `public/.htaccess` | Expand for Apache users |
| A11 | minor | `Application.cfc` sets `sessionManagement=true` with no storage guidance | `public/Application.cfc` | Comment showing storage options |
| A12 | minor | `app/migrator/migrations/` empty (just `.keep`) — no illustrative example | `app/migrator/migrations/` | Ship one starter migration |
| A13 | minor | `config/routes.cfm` comments out `.root()` without explanation | `config/routes.cfm:25-26` | Help text cleanup |
| A14 | minor | CLAUDE.md lists `app/middleware/` — directory doesn't exist in template | `CLAUDE.md:13` | Create dir with `.keep`, or drop from docs |

**Layer assessment:** Polish. A2 + A3 are the only items that genuinely affect first-run safety / ergonomics.

---

### Layer 6: Public API + upgrade path

| # | Severity | Finding | Location | Note |
|---|---|---|---|---|
| U1 | **blocker** | `viteStrictManifest` breaking change not in CHANGELOG "Breaking" section, not in upgrade guide | `CHANGELOG.md:60`, `web/sites/guides/src/content/docs/v4-0-0-snapshot/upgrading/3x-to-4x.mdx` | Same as C2 — cross-references |
| U2 | major | `onapplicationstart.cfc:85` hardcodes `application.$wheels.version = "4.0.0"` with TODO above line 84 | `vendor/wheels/events/onapplicationstart.cfm:85` | Extract from `box.json` or `VERSION` file; blocks automated release management |
| U3 | major | Lucee 5 minimum actually `5.3.2` but README claims "Lucee 5.x" | `vendor/wheels/Global.cfc:2710-2750`, `README.md:30-46` | Either enforce 5.3.2+ and say so, or support 5.0+ |
| U4 | major | README claims CF 2018–2025 but CI matrix coverage per version unclear | `README.md:30-46`, `.github/workflows/compat-matrix.yml` | Table in README listing exact tested versions |
| U5 | major | `wheels.Test` legacy base class deprecated silently — no runtime warning | `vendor/wheels/Test.cfc` | Add deprecation log in `init()` |
| U6 | minor | Upgrade guide location mismatch between spec and actual | `docs/superpowers/specs/2026-04-16-wheels-4.0-upgrade-guide-design.md` vs `web/sites/guides/src/content/docs/v4-0-0-snapshot/upgrading/3x-to-4x.mdx` | Reconcile or doc that spec is design-only |
| U7 | minor | Legacy adapter package not documented in main docs | `packages/legacyadapter/` | Add to `digging-deeper/packages.mdx` |
| U8 | minor | `deleteAll()`/`deleteOne()`/`deleteByKey()` naming asymmetric with `findAll`/`findOne`/`findByKey` | `vendor/wheels/model/delete.cfc:22`, `vendor/wheels/model/query/QueryBuilder.cfc:361` | v5.0 rename; doc in 4.0 |
| U9 | minor | `findAll(returnAs=)` return-shape polymorphism undocumented in signature | `vendor/wheels/model/read.cfc:30-54` | JSDoc `@return query\|array` |
| U10 | minor | CHANGELOG `[Unreleased]` section lacks date/anchor; must be finalized at tag | `CHANGELOG.md:21` | Process reminder for tag day |
| U11 | minor | `plugins/` sunset has no target version in deprecation text | `vendor/wheels/Plugins.cfc:128-132` | Same as P8 — "removed in 5.0" |
| U12 | minor | Java 21 requirement in README but not enforced at startup | `README.md`, `vendor/wheels/Global.cfc` | LuCLI ships own Java — mostly moot, but nice to have check |
| U13 | minor | Enum feature not mentioned in upgrade guide | `web/sites/guides/src/content/docs/v4-0-0-snapshot/upgrading/3x-to-4x.mdx` | Add to "Recommended, not required" section |
| U14 | minor | `examples/README.md` still leads with CommandBox install, not `wheels new` | `examples/README.md:18-42` | Promote LuCLI path |
| U15 | minor | `web/sites/guides/src/content/docs/v4-0-0-snapshot/` — `v4-0-0-snapshot` in path suggests pre-GA staging | path structure | Will need rename on tag |

**Layer assessment:** API itself is stable and consistent enough to ship. Docs + upgrade-path drift is the real work.

---

## Proposed triage

### Bucket A — GA blockers (must fix before tagging 4.0.0)

1. **C1 / A1** — Legacy `cli/src/` CommandBox CLI defaults to `wheels-base-template@^3.1.0`. Decision: update default, or deprecate/remove the legacy CLI entirely before GA.
2. **C2 / U1** — `viteStrictManifest` breaking change missing from CHANGELOG "Breaking" and from upgrade guide.
3. **T1** — Browser-test CI gate `WHEELS_BROWSER_CI_ENABLE` not set; all browser specs silently skip. Either fix fixtures + flip gate, or honestly document the state in release notes.
4. **F1** — Verify `Public.cfc` route exposure is prod-gated. If not, gate it. If already gated, verify and close.
5. **P1** — `wheelsVersion` accepted but never validated. Real correctness bug.
6. **U2** — `onapplicationstart.cfc` hardcoded `"4.0.0"` version string with TODO — wire to a version file before GA so we aren't shipping a ticking debt item.

### Bucket B — GA blockers (verify first, may demote)

7. **C3** — silent-exit commands. Recent PRs covered some; need final scan.
8. **C4** — `wheels deploy` returning `dryRunOutput()` on real deploys. Verify; if true, critical UX bug.

### Bucket C — v4.1 candidates

- **C5** MCP typed params (blocked on Plan B2 merging upstream)
- **C6, C7** deploy-config path normalization
- **C8–C15** CLI polish
- **F2–F10** framework-core polish (error messages, Lucee 7 guard sweep, etc.)
- **P2** mixin collision detection
- **P3** package-creation guide
- **P4** distribution story for packages
- **P5** PackageLoader tests
- **P6–P10** packages polish
- **T2** `sendfile` directory test unskip
- **T3** Adobe CF in PR gate
- **T4** browser-test fixture root cause (per-spec route scoping)
- **T5, T8, T9, T10** test coverage gaps
- **A2, A3** `.env.example` + production `.env` guard
- **A5** framework repo's own `wheels-dev` reload password + CLI `config:check` catching it
- **U3, U4** engine version claims honesty (README + minimum version)
- **U5** `wheels.Test` runtime deprecation warning

### Bucket D — v5.0 candidates

- `plugins/` folder removal (paired with P8/U11 "removed in 5.0" sunset message)
- `wheels.Test` class removal
- `vendor/wheels/public/mcp/` directory removal (after v4.1 migration grace period)
- `rocketunit_tests/` deletion (T7)
- Legacy `cli/src/` CommandBox CLI removal (paired with C1 decision)
- `deleteAll`/`deleteOne`/`deleteByKey` naming unification (U8)

### Bucket E — won't-fix / out of scope

- Agent-flagged "blockers" that were miscategorized:
  - CLI Finding 4 (`deploy server exec` shell injection) — that command's *purpose* is to run arbitrary shell via SSH, same as `ssh host cmd`. Not a bug.
  - CLI Finding 15 (test URL injection) — localhost-only, user-controlled input on user's own machine.
  - CLI Finding 9 (console password in JSON body) — dev-only, localhost, password already known by user.
  - Most "path traversal" findings in deploy — user-provided paths on user's own machine, not untrusted input.

---

## Scope decision: v4.1 vs v5.0 for Bucket C

Bucket C is ~30 items. Most are polish, docs, or additive features. None requires breaking API changes. Recommend shipping Bucket C items as they're ready into **v4.1** and reserving **v5.0** for:
- Actual public-API breaking changes (plugins/ removal, wheels.Test removal, legacy CLI removal, `deleteOne`→`deleteByKey` renames)
- Anything requiring a migration script more involved than "delete a directory"

This gives us a healthy 4.0 → 4.1 → 5.0 cadence rather than stuffing a kitchen-sink 5.0.

---

## Open questions for user triage

1. **C1 / legacy `cli/src/` CLI** — kill it, update its default to 4.0 template, or leave for grace period with clear deprecation in docs?
2. **F1 / `Public.cfc` exposure** — is `/wheels/public/*` routing prod-gated today? (I can verify once triage starts.)
3. **T1 / browser-test CI gate** — fix the 3 fixture issues (memory lists: route re-load, `createDynamicProxy` under LuCLI Express, reload-password mismatch) before GA, or document-and-defer to v4.1?
4. **Bucket B** — OK with verifying C3 and C4 before committing them to Bucket A?
5. **Agent-flagged deploy security findings** — my triage calls them "won't-fix, designed behavior" but worth getting your read. Wheels may want to ship with a defensive posture regardless.

---

## Next steps after triage

1. File GitHub issues for finalized Bucket A items (one issue per item, phase labels `phase:1-stabilize` where appropriate).
2. For each blocker: fix in a branch, run local test suite, push PR against `develop`, wait for CI green, merge (trivia tier vs code tier per `CLAUDE.local.md` rules).
3. Loop until Bucket A is empty.
4. Tag 4.0.0. Move `[Unreleased]` → `[4.0.0]` with GA date.
5. File Bucket C items as issues tagged for v4.1 milestone.
6. Bucket D items become v5.0 planning inputs.
