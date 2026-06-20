# Wheels 5 Roadmap

**Status:** Roadmap (decided direction, open items flagged explicitly)
**Date:** 2026-06-20
**Supersedes:** the earlier `wheels-5-roadmap-recommendations.md` draft, which is now folded into this single document.

This is the one document that describes what Wheels 5 is for, what it will and will not do, and why. It is written to be acted on, not just discussed. Where a decision is genuinely still open it is listed in [§11 Open decisions](#11-open-decisions) with a recommended default; everything else is a committed direction.

---

## 1. The honest starting point

Wheels 5 planning has to begin with two facts that earlier drafts assumed away.

**The CFML market is contracting, not growing.** CFML/ColdFusion is niche and maintenance-weighted: it is effectively absent from the Stack Overflow 2025 developer survey and the TIOBE top tier, the expert pool is shrinking (which is why CF salaries hold up — scarcity, not demand), and greenfield CFML projects are increasingly rare. Vendors themselves now position the language around "maintain mission-critical legacy systems."

The strategic consequence is blunt: **our competitor is not ColdBox. It is attrition** — developers leaving CFML entirely for Rails, Laravel, Node, or Go. Fighting ColdBox for a larger slice of CFML is fighting for a larger slice of a shrinking pie. ColdBox, backed by Ortus and now vertically integrated with the BoxLang runtime (ColdBox 8 ships native BoxLang integration; ~350k installs in 12 months; 720+ modules), will win any feature-for-feature, vendor-funded race. We should not enter that race.

**Wheels is a small, largely volunteer project.** The active maintainer group is a handful of people, and the community is an order of magnitude smaller than the Ortus/ColdBox ecosystem. Any roadmap that assumes the capacity to build a conformance program, a partnership track, a five-tier CI matrix, and a half-dozen new subsystems in one major version will overcommit and stall. Scope realism is a feature of this roadmap, not an afterthought.

These two facts set the objective function for Wheels 5:

> Maximize **retention** (keep existing Wheels apps and teams productive and confident) and minimize **onboarding friction**, while making exactly one credible **forward bet**. Do not chase market share against a vendor-funded competitor in a shrinking market.

---

## 2. Strategic position

Wheels remains the **elegant, convention-first, Rails-inspired, runtime-neutral full-stack framework for CFML** — small enough that a developer can hold the whole model in their head.

Three things define the lane, and they are chosen because they are defensible for a small team in a contracting market:

1. **Runtime neutrality.** Wheels runs on Lucee, Adobe CF, and BoxLang and is beholden to no single vendor. This is the direct, honest counter to ColdBox/BoxLang vertical integration. We cannot out-integrate a vendor that owns the runtime; we can be the framework that never locks you to one. Neutrality is the brand promise — backed by CI, not marketing copy.
2. **Lowest onboarding and migration friction in CFML.** A clean install path, scaffolding that works on a fresh machine, a believable upgrade story, and documentation that matches the code. For a shrinking talent pool, "easy to pick up and cheap to maintain" is worth more than any advanced feature.
3. **One forward bet: AI-legibility.** Niche-language code is increasingly written and maintained by AI agents (a working CFML engine, RustCFML, was authored almost entirely by Claude — the ecosystem is already there). The most defensible single differentiator for Wheels 5 is to be **the most AI-legible CFML framework**: machine-readable routing and request lifecycle, a stable MCP/introspection surface, and generators that emit one canonical idiom an agent can rely on. This is the only theme that simultaneously rides where development is going and lowers maintenance cost for the apps we want to retain.

What Wheels 5 explicitly is **not**: a ColdBox competitor on enterprise surface area, a BoxLang-first framework, or a platform with many named subsystems. See [§10](#10-what-wheels-5-will-not-do).

---

## 3. Wheels 4 baseline (what already ships)

This roadmap is a **coherence release**, so it must start from an accurate inventory. The following already exist in Wheels 4 as substantial, non-stub implementations. Wheels 5 work on them is **harden / document / contract**, never "add":

| Capability | Lives in |
|---|---|
| DI container | [`vendor/wheels/Injector.cfc`](../../vendor/wheels/Injector.cfc) |
| Background jobs | [`vendor/wheels/Job.cfc`](../../vendor/wheels/Job.cfc), [`vendor/wheels/JobWorker.cfc`](../../vendor/wheels/JobWorker.cfc) |
| Middleware pipeline + built-ins | [`vendor/wheels/middleware/`](../../vendor/wheels/middleware/) (Pipeline, Cors, RateLimiter, SecurityHeaders, RequestId, …) |
| Query builder + scopes | [`vendor/wheels/model/query/QueryBuilder.cfc`](../../vendor/wheels/model/query/QueryBuilder.cfc) |
| Package system | [`vendor/wheels/PackageLoader.cfc`](../../vendor/wheels/PackageLoader.cfc), `ModuleGraph.cfc` |
| Model mass-assignment protection | `accessibleProperties()` / `protectedProperties()` in [`vendor/wheels/model/properties.cfc`](../../vendor/wheels/model/properties.cfc) |
| CLI (`wheels`) incl. `doctor`, `routes --json` | [`cli/lucli/Module.cfc`](../../cli/lucli/Module.cfc) |
| Compatibility matrix CI | [`.github/workflows/compat-matrix.yml`](../../.github/workflows/compat-matrix.yml), [`.github/workflows/pr.yml`](../../.github/workflows/pr.yml) |

The risk Wheels 4 created is the one this release must answer: these capabilities are real but not yet a *coherent, well-documented, trustworthy whole*. **The first job of Wheels 5 is to make what already shipped cohere — not to pile on more.**

---

## 4. The Wheels 5 thesis

> The best Wheels 5 is not a bigger Wheels 4. It is a clearer Wheels.

Concretely, that means a small, decisive scope:

- **Make the v4 surface coherent and documented** (the consolidation half).
- **Ship two genuinely-missing safety ergonomics** — controller-level strong params and a response object.
- **Make the one forward bet** — AI-legibility.
- **Remove real legacy drag** — without fragmenting a small community's codebase.

Everything else that earlier drafts proposed (application modules, scheduler/async, config schema, DI discovery, OpenAPI generation, a strategic conformance program) is deferred to 5.1+ or dropped, and is listed in [§9](#9-deferred-to-51) and [§10](#10-what-wheels-5-will-not-do) so the boundary is explicit.

---

## 5. Scope: Wheels 5.0 core

These are the committed 5.0 deliverables. Each is small, additive where possible, and chosen against the retention / onboarding / forward-bet objective.

### 5.1 Controller-level strong params

**Gap (verified):** model-level protection exists (`accessibleProperties`/`protectedProperties`), but there is no filtering at the controller boundary where untrusted input actually enters. `params` is a bare, unguarded struct in `variables` with no accessor.

**Design — CFML-native, not a Rails transliteration.** Earlier drafts proposed making `params` a Rails-style object with `.require()`/`.permit()`/`.expect()` methods. We reject that for CFML: turning `params` into a CFC that must also behave like a struct invites cross-engine member-function collisions (the same class of bug as `obj.map()` resolving to the built-in struct member — see Cross-Engine Invariant #1 in `CLAUDE.md`). Instead:

- `params` **stays a plain struct** (zero behavior change, zero engine risk).
- Add controller **helper functions** that operate on it and return a filtered plain struct:

```cfm
// require a top-level key, permit a fixed set, return a plain struct
userParams = expectParams(params, user = ["name", "email", "timezone"]);
model("User").create(userParams);

// finer-grained building blocks
requireParam(params, "user");                       // 400-style error if missing
permitted = permit(params.user, "name,email");       // whitelist scalars
```

- These map missing/tampered input to a **400-style** response (not a 500), matching the intent behind Rails 8's `params.expect`.
- Generators emit this pattern; `wheels doctor` warns on raw `params` passed straight into `create()`/`update()`.

**Compatibility:** raw `params.user` access keeps working. Strict enforcement (reject unpermitted mass assignment) is opt-in via `set(strictParams = true)`, never default in 5.0.

### 5.2 Response object

**Gap (verified):** today's renderers (`renderView`, `renderWith`, `renderText`, `redirectTo`, `sendFile`) are imperative `void` side-effecting functions. There is no unified, testable response builder — which is most painful for the JSON/API and MCP endpoints that the forward bet depends on.

**Design:** an additive, chainable builder that does not remove any existing helper.

```cfm
return response().status(201).json(user)
                 .header("Location", urlFor(route = "user", key = user.id));

return response().status(422).json({ errors = user.allErrors() });
```

The value is concentrated where we need it: API controllers, tests (assert status/body/headers consistently), middleware, and a stable shape for AI-generated endpoints. Existing apps need not adopt it.

### 5.3 RequestContext — formalize, don't fork the idiom

**Gap (verified):** there is no `RequestContext.cfc`, but the `request.wheels.*` namespace is already rich (`params`, `currentRoute`, `cache`, `execution`, `tenant`, …) and dispatch already builds an ephemeral `{params, route, pathInfo, method, cgi}` context for middleware ([`Dispatch.cfc`](../../vendor/wheels/Dispatch.cfc)).

**Decision (committed):** formalize the *existing* namespace into a first-class `rc` object available at `variables.rc` and `request.wheels.rc`. `params` and `rc.params` reference the **same** underlying struct (no copies).

**Explicitly rejected for 5.0: action-argument injection.** Earlier drafts proposed letting actions declare `function show(params, rc)` and having dispatch inject them, and floated *three* coexisting controller styles. We reject this because:

1. It is the cross-engine-risky part. Actions are dispatched via `$invoke()` with the method name only; no named args are forwarded today. Making injection work consistently across Lucee 5/6/7, Adobe CF 2018–2025, and BoxLang is real, fragile engineering (see the invocation/`argumentCollection`/`attributeCollection` gotchas throughout `CLAUDE.md`).
2. It manufactures the "second competing API" problem. A small community cannot afford three controller idioms in its code, tutorials, and AI training context.

So there is **one taught idiom**: actions take no request arguments; read `params` (friendly) or `variables.rc` (full context) as needed. `rc` is additive; nothing is forced.

### 5.4 Legacy removal — decisive but non-fragmenting

Remove real drag, with a migration path, without breaking the long tail unnecessarily:

- **Legacy `plugins/` auto-loading** ([`Plugins.cfc`](../../vendor/wheels/Plugins.cfc), 1,131 lines): removed from core; offered as an opt-in `wheels-legacy-plugin-adapter` package for apps that still need it. The modern package system becomes the single extension story.
- **RocketUnit / `wheels.Test`** ([`vendor/wheels/Test.cfc`](../../vendor/wheels/Test.cfc)): still on disk and selectable today with no runtime warning. Add a deprecation warning in the next 4.x, remove from core in 5.0, leave as an external adapter if anyone needs it. `wheels.WheelsTest` is the only documented path.
- **CommandBox-era CLI docs**: removed; the installed `wheels` binary is the only supported surface.

### 5.5 Single CI matrix manifest

**Gap (verified):** the engine/DB matrix is hand-encoded and divergent across `compat-matrix.yml`, `pr.yml`, and `tools/test-matrix.sh`, with no shared source of truth.

**Deliverable:** one `tools/ci/matrix.yml` that declares engines, databases, support levels, and lanes, and feeds: the GitHub Actions matrix, the local runner, the published compatibility table, and `wheels doctor`. This makes the runtime-neutrality promise *executable* rather than aspirational — which is the whole point of neutrality being our brand.

### 5.6 The forward bet: AI-legibility

This is the one new theme, and it is deliberately built from pieces that are mostly small extensions of things that already exist:

- **Machine-readable routing.** `routes --json` already exists; add a stable, documented schema and let routes carry optional metadata (`description`, `tags`, `auth`). The route struct already tolerates extra keys via `argumentCollection` and exposes the matched route at `request.wheels.currentRoute` — we add a *consumer* and a documented contract, not a new mechanism.
- **Request lifecycle trace.** A `wheels trace <path>` / debug-panel timeline showing matched route, params, middleware, controller/action, and route-model-binding result. This is what lets both humans and agents understand a convention-driven framework.
- **Stable MCP / introspection surface.** Treat the `wheels mcp` stdio surface as a first-class, versioned contract so AI tooling can rely on it. Deprecate the legacy HTTP MCP endpoint.
- **Canonical generators.** Generators emit exactly one idiom (the §5.1/§5.3 patterns), so agent-generated Wheels code converges on what the framework actually wants.

OpenAPI generation, a full conformance suite, and route-level test generation are **not** in 5.0 (see §9).

---

## 6. Runtime and tooling dependencies (corrected)

Earlier drafts elevated two single-author projects to strategic pillars. That is the *same* single-vendor concentration risk we criticize in the ColdBox/BoxLang stack — just with different logos. Corrected posture:

- **BoxLang** — *first-class supported engine, not the primary optimization target.* BoxLang is real (Ortus, 1.0 GA May 2025) but its adoption is vendor-narrated, not measured. The hedge is sound, but it is not permanent: **re-evaluate quarterly.** If adoption inflects, "not primary" can age badly.
- **LuCLI** — *vendored, with an explicit continuity plan.* The `wheels` binary is already a branded fork of LuCLI in [`cli/lucli/`](../../cli/lucli/). LuCLI upstream is a self-declared **alpha (v0.4.0, "expect breaking changes"), single-maintainer** project. The continuity plan is the mitigation, not a relationship: **we own the vendored fork.** We contribute genuinely-generic improvements upstream where convenient, but Wheels' release cadence never blocks on upstream LuCLI, and we do not assume API stability we don't control.
- **RustCFML** — *monitor only; not a roadmap pillar.* It is public ([`github.com/pixl8/RustCFML`](https://github.com/pixl8/RustCFML), Alex Skinner), but it is a ~26-star, AI-authored, single-author experiment **with no ORM** — meaning it cannot run Wheels' model layer at all. It is interesting signal for "AI maintains CFML" (which informs §5.6), nothing more. It does not appear in support tables, gates, or positioning. (Earlier drafts both stated "no public project exists" — false — and made it "the strongest alternative to vertical integration" — unsupportable. Both are corrected here.)

There is no separate "partnership workstream," no RFC directory gate, and no strategic conformance program in 5.0. Coordination stays lightweight: GitHub issues, milestones, and labels.

---

## 7. Compatibility and deprecation

**Runtime compatibility stays high.** Existing controllers using `params`, existing views, model APIs, migrations, and modern-package-based extensions continue to work in 5.0.

**Strictness moves to tooling time, opt-in at runtime:**

- `wheels doctor` warns on deprecated APIs and risky patterns (raw `params` mass assignment, legacy test base, legacy plugins).
- Generators emit only the new idioms.
- Docs stop teaching removed/legacy patterns.
- `set(strictParams = true)` is the one strict mode shipped in 5.0. Other strict modes are deferred — five opt-in strict modes is configuration sprawl a small community will not adopt coherently.

**Deprecation policy:** deprecate in a 4.x minor with a runtime/doctor warning and a documented migration → remove in 5.0. Anything removed in 5.0 has a migration path, an upgrade-guide entry, and tests for the new path.

**Support levels** (rendered from `tools/ci/matrix.yml`):

- **Primary** — blocks PR/RC gates on failure (Lucee 7 + SQLite at minimum; the engines/DBs ratified in §11).
- **Supported** — tested nightly + RC; failures block release unless documented.
- **Compatibility** — expected to work; failures may be non-blocking for a limited, documented window.

---

## 8. Testing strategy (right-sized)

A small team needs **two** tiers plus a release gate — not five.

- **Tier 1 — PR fast lane (blocks merge, target < 10 min).** Lucee latest + SQLite: core WheelsTest, CLI tests, generated-app smoke, minimal browser smoke, `wheels doctor`. Seed already exists in [`pr.yml`](../../.github/workflows/pr.yml).
- **Tier 2 — Nightly full matrix.** All supported engine/DB combinations from the manifest; publishes a dashboard, uploads JUnit/JSON, opens/updates issues for persistent failures. Seed already exists in [`compat-matrix.yml`](../../.github/workflows/compat-matrix.yml).
- **Release gate.** Full matrix green-or-documented, generated-app lifecycle, upgrade tests from latest Wheels 4, **public distribution canaries** (Homebrew/Scoop/apt/yum installed on a clean system), browser tests, docs gate. A clean public install path is part of the trust story and is release-blocking.

Generated-app smoke testing (run the same `wheels` binary users install: `new` → `generate scaffold` → `dbmigrate latest` → `test` → `start`) catches template/CLI/docs drift that internal unit tests cannot, and is the cheapest high-value test we have.

---

## 9. Deferred to 5.1+

Valuable, but not worth the scope risk in 5.0. Each can ship in a minor once the core lands and capacity allows:

- **Application modules** (bounded `app/modules/<name>` mini-apps). Deferred deliberately: it introduces a *third* extension concept alongside packages and plugins while we are trying to contract, and "Module" is already overloaded (CLI `Module.cfc`, package `ModuleGraph`, TestBox `registerModule`) — naming and concept-count both need design before it ships.
- **Scheduler and lightweight async** on top of existing jobs.
- **Schema-driven configuration** (`wheels config list/get/explain/effective`).
- **Convention-based DI service discovery.**
- **OpenAPI generation** from route metadata.

---

## 10. What Wheels 5 will not do

Stated plainly so the boundary holds under pressure:

- **No ColdBox-style platform surface.** No HMVC request lifecycles, no broad AOP/interceptor system, no large named-subsystem taxonomy.
- **No BoxLang-first optimization.** Neutrality is the point.
- **No strategic conformance program.** A thin internal compatibility smoke set is fine; a multi-tier conformance suite sold as market positioning is not — users do not adopt frameworks because of conformance suites.
- **No RustCFML pillar.** Monitor only.
- **No contracts-first/RFC process gate.** Heavyweight process is delivery risk for a small team; keep coordination lightweight.
- **No action-argument injection** and **no three-idiom controllers** (see §5.3).
- **Not a major version for narrative's sake.** The only true breaking changes are the §5.4 removals. If, at beta, the breaking surface is too thin to justify a major, ship the additive work as 4.x minors and reserve "5.0" for when the removals and any idiom shifts actually warrant it. (See §11.)

---

## 11. Open decisions

These need maintainer ratification before implementation. Each has a recommended default.

1. **Engine minimums.** *Recommended:* require Lucee 6+ and Adobe 2023+ for 5.0 (drop Lucee 5 / Adobe 2018–2021 from primary), keeping the matrix small and modern. — *Decision needed.*
2. **BoxLang support level for 5.0.** *Recommended:* Supported (not Primary), re-evaluated quarterly. — *Decision needed.*
3. **Oracle release-blocking?** *Recommended:* Supported, soft-fail (as today), not release-blocking. — *Decision needed.*
4. **`strictParams` default.** *Recommended:* warn-only via doctor in 5.0; opt-in enforcement; stricter default no earlier than 6.0. — *Recommended, ratify.*
5. **Is this a 5.0 or 4.x minors?** *Recommended:* proceed as 5.0 contingent on the §5.4 removals landing; re-confirm at beta per §10. — *Decision needed at beta.*
6. **Legacy plugins / RocketUnit:** core removal + external adapter, as in §5.4. — *Recommended, ratify.*
7. **AI-legibility scope for 5.0:** which of {route metadata, lifecycle trace, MCP contract, canonical generators} are core vs. 5.1. *Recommended:* all four are core but minimal; OpenAPI is 5.1. — *Decision needed.*

---

## 12. Sequencing

Rough order, optimized for landing user-visible value early and de-risking the hard part:

1. **Coherence pass + matrix manifest (§3, §5.5).** Audit/document the v4 subsystems; unify the CI matrix. Low risk, immediate trust payoff.
2. **Strong params + response object (§5.1, §5.2).** Small, additive, the user-facing headline.
3. **RequestContext formalization (§5.3).** Additive `rc`; no injection.
4. **AI-legibility surface (§5.6).** Route metadata schema, lifecycle trace, MCP contract, canonical generators.
5. **Legacy removal + upgrade guide (§5.4).** The breaking work, once the new paths exist and are documented.

Each step is shippable and independently valuable, so the release can slip scope without collapsing.

---

## 13. Bottom line

Wheels 5 should preserve the framework's most valuable quality — a developer can understand it quickly and build useful applications without ceremony — and spend its effort making that simplicity *durable and trustworthy* in a shrinking market:

- Friendly `params`, backed by safer controller-boundary filtering.
- Simple controllers, backed by an additive request context — one idiom, not three.
- A coherent, documented v4 feature set instead of a bigger pile.
- Runtime neutrality, backed by an executable compatibility matrix.
- One real forward bet — AI-legibility — instead of partnership and conformance machinery.
- Decisive legacy removal, without fragmenting a small community.

The competitor is attrition, not ColdBox. The win condition is that fewer teams leave CFML because Wheels stayed clear, cheap to maintain, and easy for both people and agents to work in.
