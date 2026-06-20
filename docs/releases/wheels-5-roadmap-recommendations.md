# Wheels 5 Roadmap Recommendations

**Status:** Draft recommendation document  
**Date:** 2026-06-20  
**Scope:** Strategic and architectural recommendations for the next major version of Wheels after the 4.0 line.

This document consolidates a set of framework reviews and comparative analyses:

- Current Wheels 4 source and documentation.
- Rails, Laravel, and Django capability comparison.
- Framework One architectural review.
- ColdBox and BoxLang strategic review.
- Wheels testing and CI/CD review.
- Rails `params` evolution and its implications for Wheels.
- LuCLI and RustCFML collaboration implications.

The goal is not to clone any competing framework. The goal is to define a coherent Wheels 5 direction that protects what makes Wheels valuable, removes old drag, and gives the project a sharper story for the next decade of CFML and CFML-adjacent development.

---

## 1. Executive Summary

Wheels 4 is already a major modernization release. It adds a modern ORM surface, a query builder, jobs, middleware, rate limiting, packages, DI, browser testing, LuCLI-based CLI distribution, deploy tooling, MCP integration, and expanded engine/database support. Wheels 5 should not try to be another ColdBox. It should be a consolidation and clarity release.

The recommended strategic position for Wheels 5 is:

> Wheels is the elegant, convention-first, Rails-inspired full-stack framework for CFML applications, with first-class engine neutrality, a modern CLI, and open runtime/tooling partnerships.

That sentence matters. It gives the roadmap a filter:

- Prefer productivity over enterprise ceremony.
- Prefer explicit contracts under the hood, but keep the developer-facing API approachable.
- Support BoxLang, but do not become BoxLang-first.
- Adopt good ideas from ColdBox and Framework One only when they strengthen the Wheels identity.
- Keep `params`, but make it safer and give developers an explicit request context path.
- Keep the monorepo, because the framework, CLI, templates, packages, tests, and distribution are now tightly coupled.
- Make automated testing a first-class product feature of the framework, not merely a maintainer concern.
- Use strong relationships with LuCLI and RustCFML maintainers to turn Wheels into a reference framework for open CFML runtime and tooling conformance.

The highest-impact Wheels 5 themes are:

1. **Framework contraction:** remove deprecated legacy surfaces and reduce ambiguous runtime magic.
2. **Request context and safer params:** introduce `rc`, preserve `params`, and add Rails-like strong parameter APIs.
3. **First-class modules:** add bounded application modules inspired by FW/1 subsystems and ColdBox HMVC, but keep the API small.
4. **Response and route contracts:** add response builders, route metadata, route inspection, and generated API/MCP/OpenAPI context.
5. **Testing platform:** formalize a multi-tier test matrix across engines, databases, CLI, generated apps, browser tests, and distribution packages.
6. **Engine neutrality:** make ACF/Lucee/BoxLang compatibility an explicit release promise backed by CI.
7. **CLI as the contract:** use the LuCLI-based `wheels` binary as the unified local, CI, package, and release harness.
8. **Runtime and tooling partnerships:** make LuCLI and RustCFML collaboration first-class roadmap tracks, not side-channel conveniences.

---

## 2. Source Grounding

This document is grounded in the following local Wheels source areas:

- Core dispatch and request parameter handling:
  - [`vendor/wheels/Dispatch.cfc`](../../vendor/wheels/Dispatch.cfc)
  - [`vendor/wheels/Controller.cfc`](../../vendor/wheels/Controller.cfc)
  - [`vendor/wheels/controller/processing.cfc`](../../vendor/wheels/controller/processing.cfc)
  - [`vendor/wheels/Global.cfc`](../../vendor/wheels/Global.cfc)
- Current package/plugin architecture:
  - [`vendor/wheels/PackageLoader.cfc`](../../vendor/wheels/PackageLoader.cfc)
  - [`vendor/wheels/Plugins.cfc`](../../vendor/wheels/Plugins.cfc)
- DI, jobs, middleware, and query builder:
  - [`vendor/wheels/Injector.cfc`](../../vendor/wheels/Injector.cfc)
  - [`vendor/wheels/JobWorker.cfc`](../../vendor/wheels/JobWorker.cfc)
  - [`vendor/wheels/middleware/Pipeline.cfc`](../../vendor/wheels/middleware/Pipeline.cfc)
  - [`vendor/wheels/middleware/RateLimiter.cfc`](../../vendor/wheels/middleware/RateLimiter.cfc)
  - [`vendor/wheels/model/query/QueryBuilder.cfc`](../../vendor/wheels/model/query/QueryBuilder.cfc)
- CLI and distribution:
  - [`cli/CLAUDE.md`](../../cli/CLAUDE.md)
  - [`cli/lucli/ARCHITECTURE.md`](../../cli/lucli/ARCHITECTURE.md)
  - [`cli/lucli/Module.cfc`](../../cli/lucli/Module.cfc)
  - [`tools/distribution-drafts`](../../tools/distribution-drafts)
- Current test and CI infrastructure:
  - [`tests/README.md`](../../tests/README.md)
  - [`vendor/wheels/tests`](../../vendor/wheels/tests)
  - [`cli/lucli/tests`](../../cli/lucli/tests)
  - [`e2e`](../../e2e)
  - [`.github/workflows/pr.yml`](../../.github/workflows/pr.yml)
  - [`.github/workflows/compat-matrix.yml`](../../.github/workflows/compat-matrix.yml)
  - [`.github/actions/setup-wheels-test-env/action.yml`](../../.github/actions/setup-wheels-test-env/action.yml)

External framework references:

- Rails:
  - [Action Controller Overview](https://guides.rubyonrails.org/action_controller_overview.html)
  - [ActionController::Parameters API](https://api.rubyonrails.org/classes/ActionController/Parameters.html)
  - [Rails 4.0 release notes](https://guides.rubyonrails.org/4_0_release_notes.html)
  - [Rails 8.1 release notes](https://guides.rubyonrails.org/8_1_release_notes.html)
- Laravel:
  - [Laravel documentation](https://laravel.com/docs)
- Django:
  - [Django documentation](https://docs.djangoproject.com/)
- Framework One:
  - [FW/1 documentation](https://framework-one.github.io/documentation/)
  - [FW/1 developing applications](https://framework-one.github.io/documentation/4.2/developing-applications/)
  - [FW/1 subsystems](https://framework-one.github.io/documentation/4.2/using-subsystems/)
  - [DI/1 documentation](https://framework-one.github.io/documentation/4.2/using-di-one/)
- ColdBox and BoxLang:
  - [ColdBox site](https://www.coldbox.org/)
  - [ColdBox documentation](https://coldbox.ortusbooks.com/)
  - [BoxLang site](https://www.boxlang.io/)
- Runtime and tooling ecosystem:
  - [LuCLI GitHub repository](https://github.com/cybersonic/LuCLI)
  - RustCFML collaboration with Alex Skinner, treated here as an experimental engine/conformance partnership. No public project URL is assumed by this document.

---

## 3. Strategic Positioning

### 3.1 What Wheels Should Be

Wheels should remain the Rails-like framework in the CFML ecosystem:

- Convention-first.
- CRUD-friendly.
- ORM-centered.
- Controller/view helper friendly.
- Fast to start.
- Easy to explain.
- Small enough that a developer can hold the mental model in their head.

Wheels 4 has expanded the framework's capability surface substantially. The risk for Wheels 5 is that the framework starts to feel like a pile of features rather than a coherent system. The roadmap should counter that risk by making the framework more explicit internally while keeping the default developer experience simple.

The desired outcome:

> A new developer can build a useful CRUD app quickly, while an experienced maintainer can reason about routing, request context, params, services, packages, jobs, middleware, and tests through stable contracts.

### 3.2 What Wheels Should Not Be

Wheels should not chase ColdBox feature-for-feature.

ColdBox is a larger platform with HMVC modules, WireBox, CacheBox, LogBox, interceptors, scheduled tasks, async APIs, REST handlers, and a growing BoxLang-first optimization story. That is a legitimate strategy for Ortus, but it is not the best strategy for Wheels.

Wheels should also not try to match Laravel's ecosystem breadth, Django's built-in admin depth, or Rails' RubyGems ecosystem. Those are ecosystem-level advantages, not single-release feature gaps.

Instead, Wheels should compete on:

- CFML-native productivity.
- Engine neutrality.
- Simpler conventions.
- Built-in ORM ergonomics.
- Modern CLI and distribution.
- Strong automated compatibility testing.
- A smaller, clearer framework surface.

### 3.3 The ColdBox / BoxLang Lesson

ColdBox has become a vertically integrated platform play. ColdBox 8 runs on BoxLang, Lucee, and Adobe CF, but the direction is clearly optimized around BoxLang because Ortus controls both the language/runtime and framework.

That gives ColdBox real advantages:

- Runtime/framework co-design.
- Faster platform-level innovation.
- One organization controlling docs, CLI, runtime, modules, support, and release cadence.
- Stronger professional support loop.

It also creates a strategic opening for Wheels:

- Wheels can be the neutral CFML framework.
- Wheels can support BoxLang without being BoxLang-first.
- Wheels can make ACF/Lucee/BoxLang parity a brand promise.
- Wheels can appeal to teams that want modernization without moving into the full Ortus platform.
- Wheels can answer vertical integration with open ecosystem integration: LuCLI for tooling/runtime workflow, RustCFML for future engine pressure-testing, and a public conformance suite for all engines.

Recommendation:

> Treat BoxLang as a first-class supported engine, not the primary optimization target.

This should be backed by documentation and CI:

- Every major release should publish an engine compatibility table.
- The public test matrix should show ACF, Lucee, and BoxLang status.
- Engine-specific behavior should be isolated behind adapters, not scattered through core code.
- Experimental engines such as RustCFML should be used to expose assumptions and codify framework/runtime contracts before they are treated as production targets.

---

## 4. Current Wheels 4 Assessment

### 4.1 Strengths To Preserve

Wheels 4 has several important strengths that should remain central in Wheels 5.

#### Full-Stack Productivity

Wheels has the classic full-stack pieces:

- Routing.
- Controllers.
- Views and layouts.
- ORM.
- Migrations.
- Form helpers.
- URL helpers.
- Flash/session helpers.
- Tests.
- CLI generators.

The value is not only that these exist. The value is that they are integrated and convention-driven.

#### ORM Ergonomics

The Wheels ORM remains a major differentiator inside CFML:

- Active Record style.
- Associations.
- Validations.
- Callbacks.
- Scopes.
- Query builder.
- Enums.
- Bulk operations.
- Polymorphic associations.
- Multi-database support.

Wheels should continue to lead with the ORM story.

#### Multi-Engine and Multi-Database Support

Wheels supports a broad engine/database surface. That is expensive, but it is strategically important. The competition with ColdBox makes this more important, not less.

The framework should continue to support:

- Lucee.
- Adobe ColdFusion.
- BoxLang.
- SQLite.
- PostgreSQL.
- MySQL/MariaDB.
- SQL Server.
- Oracle.
- CockroachDB.
- H2 where practical for Lucee.

Not all combinations need to be equally important, but the supported combinations should be explicit.

#### LuCLI-Based CLI and Distribution

The move to LuCLI and distribution through Homebrew, Scoop, apt, and yum/dnf is a major shift. It means Wheels can now offer a clean install story without requiring developers to understand CommandBox first.

This is not just a CLI detail. It changes the testing and release strategy:

- The public `wheels` binary can become the canonical test harness.
- Generated app smoke tests can run from the same CLI users install.
- Package install tests can validate real distribution channels.
- CI and local development can use the same commands.

Because there is an active working relationship with Mark Drew, the creator of LuCLI, Wheels can do more than consume LuCLI. Wheels can help shape LuCLI capabilities upstream in ways that benefit both projects:

- Stable module APIs.
- Reliable server lifecycle primitives.
- Machine-readable output.
- Cross-platform wrapper behavior.
- Engine profile handling.
- CI/test primitives.
- Module install and update hooks.

This changes the Wheels 5 roadmap. CLI needs should not be implemented as Wheels-only hacks when they can become reusable LuCLI capabilities.

#### RustCFML As A Conformance Partner

RustCFML should not be treated as a primary production engine target for Wheels 5. It should be treated as an experimental conformance partner.

That is still strategically valuable. A newer engine implementation can reveal hidden assumptions in Wheels that Lucee, Adobe CF, and BoxLang may tolerate through legacy behavior. RustCFML can become a strict pressure test for:

- CFScript parsing.
- CFC construction.
- Method invocation.
- `argumentCollection`.
- Scope lookup.
- Struct/array/query behavior.
- Include semantics.
- JSON serialization.
- Request simulation.
- Controller dispatch.
- Eventually ORM and query behavior.

The relationship with Alex Skinner can help Wheels define clearer runtime contracts while giving RustCFML real framework-driven compatibility targets.

#### Built-In Testing Infrastructure

Wheels already has:

- Core WheelsTest specs.
- CLI module specs.
- Browser testing support.
- Playwright artifacts.
- HTTP test clients.
- Parallel test runner work.
- GitHub workflows for fast PR tests and broader compatibility matrix tests.

This is enough foundation to turn testing into a core framework advantage.

### 4.2 Weaknesses To Address

#### Too Much Runtime Magic

Wheels has historically leaned on component variables, included mixins, unscoped lookup, and dynamic invocation. That helped create a terse developer experience, but it makes the framework harder to reason about as it grows.

Examples:

- Controller actions currently access `params` through unscoped lookup from `variables.params`.
- Controller methods are invoked dynamically through `$invoke()`.
- Mixins are integrated into controller, view, model, and global scopes.
- Legacy plugins can still inject behavior dynamically.

Wheels 5 should not remove all magic. It should make the magic observable and optional.

#### Legacy Drag

Wheels 4 already marks some legacy surfaces as deprecated. Wheels 5 is the right time to remove or isolate them.

Candidates:

- Legacy `plugins/` behavior in favor of the modern package system.
- RocketUnit compatibility paths, after a clear migration window.
- Old TestBox naming aliases if retained only for 4.x compatibility.
- CommandBox-era CLI documentation and command references.
- Old asset pipeline paths if Vite and modern asset handling are the preferred direction.
- Deprecated MCP HTTP endpoints if stdio MCP is the supported path.

The goal is not to break apps for sport. The goal is to make Wheels 5 internally smaller and easier to test.

#### Documentation Drift

The codebase has moved faster than the docs. This showed up during the review in CLI notes, testing roadmap notes, and framework capability docs that still describe older directions.

Wheels 5 should not ship with a docs backlog. Documentation should be part of the release gate.

#### Compatibility Ambiguity

The README, version checks, CI matrix, and release docs should all agree on supported engines and versions.

During review, there were signs of drift in engine minimum checks and current support claims. Wheels 5 should make compatibility declarations executable:

- Configured in one place.
- Tested in CI.
- Rendered into docs.
- Used by CLI `wheels doctor`.

---

## 5. Roadmap Principles

These principles should guide Wheels 5 decisions.

### 5.1 Keep The Friendly API, Add Explicit Internals

Rails kept `params`. It did not force controller actions to accept request arguments. But Rails changed what `params` is: a safer parameter object with strong parameter behavior.

Wheels should follow that pattern.

Keep this:

```cfml
function show() {
  post = model("Post").findByKey(params.key);
}
```

Enable this:

```cfml
function show(required struct params, required any rc) {
  post = model("Post").findByKey(params.key);
}
```

And eventually encourage this for more explicit code:

```cfml
function show(required any rc) {
  post = model("Post").findByKey(rc.params.key);
}
```

The user-facing progression should be gentle:

1. Old code works unchanged.
2. New generators use the clearer style.
3. `wheels doctor` detects risky patterns.
4. Strict mode allows teams to opt out of legacy globals.

### 5.2 Prefer Contracts Over Conventions Where The Framework Boundary Is Crossed

Conventions are good inside an app. Contracts are better at framework boundaries.

Wheels 5 should define contracts for:

- Request context.
- Response object.
- Route metadata.
- Middleware.
- Package lifecycle.
- Service providers.
- Job handlers.
- Scheduler tasks.
- Test harness output.
- Engine adapters.
- Database adapters.

This does not mean every app developer must write more code. It means framework internals and extension points become predictable.

### 5.3 Treat Testing As Product Infrastructure

For a multi-engine, multi-database framework, testing is not a backend concern. It is part of the product.

Wheels should be able to say:

> Every release is tested against a published engine/database matrix, generated apps, CLI distribution packages, browser tests, and upgrade paths.

That claim would be a real differentiator in the CFML ecosystem.

### 5.4 Make Engine Neutrality Visible

Engine neutrality should not be merely aspirational.

Wheels 5 should publish:

- Supported engine versions.
- Supported database combinations.
- Known soft-fail combinations.
- Last successful matrix run.
- Engine-specific caveats.
- Upgrade guidance by engine.

The CLI should expose the same:

```bash
wheels doctor compatibility
wheels doctor matrix
```

### 5.5 Turn Partnerships Into Product Architecture

The relationships with Mark Drew and Alex Skinner should change how Wheels plans major versions.

Without those relationships, Wheels would mostly react to tooling and runtime behavior after it appears. With those relationships, Wheels can help shape upstream capabilities before they harden:

- LuCLI can gain generic features that Wheels needs, instead of Wheels carrying custom wrappers forever.
- RustCFML can use Wheels as a realistic compatibility target, instead of only testing isolated language features.
- Wheels can define conformance contracts that make every engine integration less ambiguous.
- The broader CFML ecosystem gets shared infrastructure instead of another framework-specific island.

This means the Wheels 5 roadmap should be structured around contracts first:

```text
define runtime/tooling contract
build conformance suite
implement framework feature against the contract
upstream missing LuCLI/RustCFML capability where possible
verify across supported engines and distributions
```

The key inversion:

```text
Old model: build v5 features, then test them across engines.
New model: define contracts, prove them in conformance tests, then build v5 features against those contracts.
```

This is the strongest open alternative to the ColdBox/BoxLang vertical integration story.

---

## 6. Runtime And Tooling Partnerships

### 6.1 Partnership Strategy

Wheels 5 should formally recognize LuCLI and RustCFML as strategic ecosystem partners.

This does not mean Wheels becomes dependent on either project in a fragile way. It means the roadmap should deliberately identify work that belongs upstream, work that belongs in Wheels, and work that should be captured as shared conformance tests.

Recommended partnership posture:

- **LuCLI:** official platform layer for the installed `wheels` developer experience.
- **RustCFML:** experimental runtime/conformance partner.
- **Lucee, Adobe CF, BoxLang:** supported runtime targets with release-gate visibility.
- **Wheels:** reference framework and conformance driver.

This gives Wheels a credible strategic answer to vertically integrated stacks:

- ColdBox/BoxLang: one vendor optimizes the whole stack.
- Wheels/LuCLI/RustCFML/Lucee/Adobe/BoxLang: open ecosystem compatibility driven by public contracts and tests.

The Wheels 5 roadmap should therefore be tracked in four parallel workstreams:

1. **Framework Core:** RequestContext, params, response objects, modules, packages, routing, configuration, DI, jobs, and deprecations.
2. **Platform / LuCLI:** CLI command contracts, server lifecycle, generated app workflows, distribution install paths, machine-readable output, and `wheels ci run`.
3. **Engine Compatibility / Conformance:** Lucee, Adobe CF, BoxLang, RustCFML experimental support, engine adapters, and shared conformance tests.
4. **Release Infrastructure:** GitHub Actions, Proxmox/self-hosted runners, nightly matrix, RC gates, package canaries, dashboards, and docs gates.

Each Wheels 5 feature should declare which workstream owns it and which other workstreams it depends on. For example, RequestContext is Framework Core, but it depends on Engine Compatibility because action argument injection must behave consistently across engines.

### 6.2 LuCLI As The Wheels Platform Layer

LuCLI should be treated as the official substrate for the `wheels` CLI, local dev server, generated app workflows, and CI entry points.

Wheels should continue to own:

- User-facing `wheels` command design.
- Framework generators.
- Project templates.
- Wheels-specific test commands.
- Wheels-specific deploy commands.
- Release packaging.
- Documentation.

LuCLI should own or grow generic capabilities:

- Module discovery and execution.
- Server lifecycle APIs.
- Stable process and exit-code behavior.
- Engine profile selection.
- URL rewriting support.
- Machine-readable command output.
- Cross-platform binary behavior.
- Module installation/update primitives.
- Script execution and embedded runtime behavior.

Wheels should contribute upstream where the capability is generic. Examples:

```text
Need: reliable server start/stop/status for Wheels CI.
Best home: LuCLI server lifecycle API.

Need: JSON output for command automation.
Best home: LuCLI output mode conventions plus Wheels command implementations.

Need: stable module install/update hooks.
Best home: LuCLI module system.

Need: cross-platform wrapper parity.
Best home: LuCLI and Wheels distribution scripts together.
```

This reduces long-term Wheels-specific glue and makes LuCLI stronger for other CFML projects.

### 6.3 RustCFML As A Strict Experimental Engine

RustCFML should be treated as an experimental engine target for Wheels 5, not as a production support promise.

Its value is different:

- It can expose hidden assumptions in Wheels.
- It can reveal places where Wheels depends on Lucee/ACF quirks.
- It can help define minimal CFML semantics needed by modern framework code.
- It can become a fast future runtime or tooling target if it matures.

Initial RustCFML goals should be modest and explicit:

1. Parse the CFScript style used in Wheels core.
2. Construct CFCs used by simple controllers/models/services.
3. Support method invocation and `argumentCollection`.
4. Support struct/array operations used by dispatch and params handling.
5. Support includes enough for generated app templates.
6. Support JSON serialization/deserialization.
7. Run a small no-database controller/request conformance suite.
8. Later, run selected ORM/query conformance tests.

RustCFML should appear in the compatibility matrix as:

```yaml
rustcfml:
  support: experimental
  purpose: conformance
  releaseBlocking: false
```

That status should stay honest. Experimental means useful signal, not a promise to users.

### 6.4 Wheels Conformance Suite

The most important partnership artifact should be a Wheels conformance suite.

This should be separate from the full application test suite. The conformance suite defines minimum framework/runtime/tooling contracts.

Proposed layout:

```text
tests/conformance/
  language/
    cfscript-basics/
    closures/
    scopes/
    structs-arrays/
    json/
  cfc/
    construction/
    inheritance/
    mixins/
    invoke/
    argument-collection/
    on-missing-method/
  request/
    params-merge/
    request-context/
    headers/
    cookies/
    method-override/
  controller/
    action-invocation/
    filters/
    render-response/
    redirects/
  routing/
    matching/
    constraints/
    route-model-binding/
  orm/
    query-generation/
    basic-crud/
    associations/
  cli/
    exit-codes/
    json-output/
    server-lifecycle/
  generated-app/
    scaffold-smoke/
    migration-smoke/
```

The conformance suite should answer questions like:

- What CFML behavior does Wheels require?
- What method invocation semantics must an engine support?
- How does Wheels expect `argumentCollection` to behave?
- What request/CGI/session/cookie scopes must exist?
- What params merging behavior is required?
- What CLI exit codes and JSON shapes does automation rely on?

### 6.5 Contract Artifacts

Every major Wheels 5 architectural feature should produce a contract artifact:

- `RequestContext` contract.
- Params object contract.
- Response object contract.
- Module lifecycle contract.
- Package lifecycle contract.
- CLI command output contract.
- Engine adapter contract.
- Database adapter contract.
- Test result JSON/JUnit contract.

These contracts can live under:

```text
docs/contracts/
```

Suggested files:

```text
docs/contracts/request-context.md
docs/contracts/params.md
docs/contracts/response.md
docs/contracts/modules.md
docs/contracts/packages.md
docs/contracts/cli-output.md
docs/contracts/engine-adapters.md
docs/contracts/test-results.md
```

This is where Wheels can become valuable beyond its own codebase. LuCLI, RustCFML, and other tooling can implement against these contracts.

### 6.6 Upstream-First Policy

Adopt an upstream-first policy for generic tooling/runtime needs.

When a missing capability is found:

1. Decide whether it is Wheels-specific or generally useful.
2. If generally useful, open/design it upstream in LuCLI or RustCFML.
3. Add a conformance test in Wheels.
4. Consume the upstream capability once available.
5. Keep temporary Wheels shims small and documented.

Examples:

- Server lifecycle reliability belongs in LuCLI.
- Binary wrapper behavior may span LuCLI and distribution scripts.
- RequestContext is Wheels-specific.
- `argumentCollection` semantics belong in engine conformance.
- Strong params belongs in Wheels.
- CLI JSON output shape spans LuCLI conventions and Wheels command output.

### 6.7 Governance And Coordination

Keep governance lightweight but explicit.

Recommended mechanisms:

- Add `upstream-lucli`, `upstream-rustcfml`, and `engine-contract` labels.
- Track cross-repo work through GitHub issues and milestones.
- Use short RFCs for shared contracts.
- Link upstream PRs from Wheels issues.
- Add a quarterly compatibility review before major release milestones.

Suggested RFC path:

```text
docs/rfcs/
  0001-request-context.md
  0002-cli-json-output.md
  0003-engine-conformance-suite.md
```

The process should stay practical. The goal is not bureaucracy. The goal is to prevent critical upstream assumptions from living only in chat threads or maintainer memory.

---

## 7. Major Recommendations

## 7.1 Introduce RequestContext While Preserving `params`

### Problem

Wheels currently exposes request data through a plain-ish `params` struct stored on the controller instance. This is ergonomic, but it conflates several concepts:

- Query string params.
- Form params.
- JSON body params.
- Route params.
- Framework routing metadata.
- Potentially resolved route model bindings.

It also relies on unscoped CFML variable resolution. That makes code pleasant to write, but harder to reason about and test.

### Rails Lesson

Rails started with a merged `params` hash. In Rails 2.3 it was documented as `HashWithIndifferentAccess`, merging query string, POST data, and route params. Modern Rails still exposes `params`, but it is now `ActionController::Parameters`, not a plain hash. Rails 4 introduced Strong Parameters so raw params cannot be mass-assigned into models without explicit permission.

Rails did not remove `params`. It made `params` safer.

### Recommendation

Add a first-class `RequestContext` object or struct-like component. It should be created during dispatch and attached to the request and controller.

Initial shape:

```cfml
rc = {
  params = params,
  route = routeInfo,
  controller = params.controller,
  action = params.action,
  method = request.cgi.request_method,
  format = params.format ?: "html",
  requestId = "...",
  headers = requestHeaders,
  cookies = cookie,
  session = session,
  flash = flashScope,
  env = environmentInfo
}
```

Controller initialization should set:

```cfml
variables.rc = requestContext;
variables.params = variables.rc.params;
request.wheels.rc = requestContext;
request.wheels.params = variables.rc.params;
```

Action invocation should support compatibility injection:

```cfml
$invoke(
  method = arguments.action,
  invokeArgs = {
    rc = variables.rc,
    params = variables.rc.params
  }
);
```

Important rule:

> `params`, `rc.params`, `variables.params`, and `request.wheels.params` should initially reference the same underlying object.

Do not copy the params struct in normal request flow. Copies create synchronization bugs.

### Engine Caveat

Before implementation, verify behavior across Lucee, Adobe CF, and BoxLang:

- Does each engine ignore extra named arguments passed to a method that declares no arguments?
- Does each engine allow an action declaring `params` and/or `rc` to receive those values consistently?
- Does `onMissingMethod` receive these arguments safely?

If any supported engine rejects undeclared named args, use metadata introspection:

- Pass `params` only when the action declares `params`.
- Pass `rc` only when the action declares `rc`.
- Keep `variables.params` and `variables.rc` always available.

### Developer Experience

Existing code remains valid:

```cfml
function update() {
  user = model("User").findByKey(params.key);
  user.update(params.user);
}
```

New generated code can use explicit args:

```cfml
function update(required struct params, required any rc) {
  user = model("User").findByKey(params.key);
  user.update(userParams(params));
}
```

Or:

```cfml
function update(required any rc) {
  user = model("User").findByKey(rc.params.key);
  user.update(userParams(rc.params));
}
```

### Why This Matters

This gives Wheels a bridge:

- Old apps stay easy.
- New apps become clearer.
- Tests can construct request contexts directly.
- Middleware can work against a stable request object.
- Packages can inspect request metadata without depending on global scopes.
- Future strict mode becomes realistic.

---

## 7.2 Add Strong Params / Parameter Contracts

### Problem

Wheels has model-level mass assignment protections through accessible/protected properties, but controller-level parameter intent is not as strong or expressive as modern Rails Strong Parameters.

The risky pattern is:

```cfml
user.update(params.user);
```

That is convenient, but the controller does not explicitly declare which submitted keys are expected.

### Recommendation

Create a Wheels parameter object with safe filtering and shape validation.

The object should remain easy to use like a struct where practical, but it should offer explicit APIs:

```cfml
params.require("user");
params.permit("name,email,timezone");
params.expect(user = ["name", "email", "timezone"]);
params.toStruct();
```

Recommended APIs:

```cfml
params.require("user")
```

Requires a top-level key. Raises a 400-style exception when missing.

```cfml
params.permit("name,email,timezone")
```

Returns only permitted scalar keys from the current params object.

```cfml
params.expect(user = ["name", "email", "timezone"])
```

Requires `user`, ensures it has the expected shape, and returns permitted values.

```cfml
params.expectArray("ids")
```

Requires an array-like param and normalizes it.

```cfml
params.unpermittedKeys()
```

Returns submitted keys that were not permitted.

```cfml
params.permitted()
```

Returns true when this parameter object has passed through a permit/expect call.

```cfml
params.toStruct()
```

Returns a plain struct only when permitted, unless strict mode is disabled.

### Suggested Controller Pattern

```cfml
function create(required struct params) {
  user = model("User").create(userParams(params));

  if (user.hasErrors()) {
    renderView(action = "new");
    return;
  }

  redirectTo(route = "user", key = user.id);
}

private struct function userParams(required any params) {
  return params.expect(user = ["name", "email", "timezone"]);
}
```

### Compatibility

Do not break direct struct access in Wheels 5.

The transition should be:

1. Wheels 5 introduces parameter contracts.
2. Generators use parameter contracts.
3. `wheels doctor` warns on direct mass assignment from raw `params`.
4. Strict mode can reject raw params passed to model mutation methods.
5. A later major version can consider stricter defaults.

### Why This Matters

This is the most Rails-aligned improvement Wheels can make to `params`. It preserves the friendly controller API while moving security and intent to the boundary where user input enters the application.

---

## 7.3 Add First-Class Application Modules

### Problem

Wheels has plugins and packages, but it does not yet have a first-class concept for bounded application modules. A plugin/package is a reusable extension mechanism. A module is an application boundary.

Examples:

- Admin.
- Billing.
- API.
- Reporting.
- Tenant management.
- Support portal.

These parts often need local routes, controllers, views, services, jobs, tests, and assets.

### Lessons From FW/1 and ColdBox

FW/1 has subsystems. They allow a larger app to be split into smaller convention-based mini-apps with their own controllers, views, layouts, and model/service conventions.

ColdBox has HMVC modules. Its module system is much broader and more enterprise-oriented. Wheels should not copy the entire ColdBox model, but the idea of a bounded app module is valuable.

### Recommendation

Add first-class Wheels modules with a small convention:

```text
app/modules/admin/
  Module.cfc
  config/routes.cfm
  controllers/
  models/
  services/
  views/
  jobs/
  tests/
```

The top-level app remains the main app. Modules are mounted into it.

Example route:

```cfml
mapper()
  .module("admin", path = "/admin")
  .module("api", path = "/api");
```

Or:

```cfml
mapper().scope(path = "/admin", module = "admin", function() {
  resources("users");
});
```

### Module Lifecycle

Each module should support a minimal lifecycle:

```cfml
component {
  function register() {}
  function routes(mapper) {}
  function boot() {}
}
```

Where:

- `register()` registers services, settings, jobs, middleware.
- `routes(mapper)` contributes routes.
- `boot()` runs after the app and module graph are loaded.

### What Modules Should Not Do

Avoid building a full ColdBox HMVC clone.

For Wheels 5, modules do not need:

- Independent request lifecycles.
- Complex parent/child event bubbling.
- Broad AOP features.
- Deep per-module interceptors.
- Separate dependency injection containers by default.

Keep modules as a simple app organization boundary first.

### CLI Support

```bash
wheels generate module admin
wheels generate module api --api
wheels routes --module=admin
wheels test run --module=admin
```

### Why This Matters

Modules give larger Wheels apps a growth path without abandoning the framework's simplicity. They also create a natural place for future package extraction:

- Start as app module.
- Stabilize API.
- Extract into package if reusable.

---

## 7.4 Consolidate Packages And Remove Legacy Plugin Drag

### Problem

Wheels currently has a modern package system and legacy plugin compatibility. The legacy path is useful for migration, but it increases startup complexity, loader complexity, documentation complexity, and test surface.

### Recommendation

Make Wheels 5 the removal point for legacy plugin behavior, with a compatibility package if needed.

Recommended path:

1. Wheels 4.x continues to warn when legacy plugins load.
2. Wheels 4.x ships `wheels plugin migrate` or `wheels package migrate`.
3. Wheels 5 removes automatic legacy plugin loading from core.
4. Wheels 5 optionally provides `wheels-legacy-plugin-adapter` as a package.

### Package System Direction

The modern package system should become the only extension story:

- `package.json` manifest.
- Declared mixin targets.
- Service providers.
- Dependencies.
- Replaces/suggests.
- Lazy loading.
- Version compatibility.
- Explicit lifecycle.

### Needed Improvements

Add stronger validation:

```bash
wheels package validate
wheels package doctor
wheels package graph
```

Add better docs:

- How to build a package.
- How package lifecycle works.
- How package mixins are resolved.
- How conflicts are handled.
- How packages differ from app modules.

### Module vs Package Rule

Document this clearly:

- A **module** is part of one app.
- A **package** is reusable across apps.
- A package can provide a module.
- An app module can later be extracted into a package.

---

## 7.5 Add A Fluent Response Object

### Problem

Wheels has many rendering and redirection helpers, but controller response intent can be scattered:

- `renderText`.
- `renderWith`.
- `renderView`.
- `redirectTo`.
- `sendFile`.
- Status/header manipulation.

For APIs, jobs dashboards, MCP, and generated JSON endpoints, a unified response builder would clarify intent.

### Lessons From FW/1 and Modern Frameworks

FW/1 has `renderData().data(...).type(...).statusCode(...).header(...)`. Laravel has response helpers. Rails has `render` and `redirect_to` with structured options.

Wheels can add a fluent API without removing existing helpers.

### Recommendation

Add:

```cfml
response()
  .status(201)
  .json(user)
  .header("Location", urlFor(route = "user", key = user.id));
```

Examples:

```cfml
return response().json({ok = true});
```

```cfml
return response()
  .status(422)
  .json({
    errors = user.allErrors()
  });
```

```cfml
return response()
  .redirectTo(route = "posts")
  .flash("success", "Post created");
```

```cfml
return response()
  .file(path = local.path, disposition = "attachment");
```

### Compatibility

Existing helpers should remain:

```cfml
renderWith(user);
redirectTo(route = "posts");
```

The response object should be additive in Wheels 5.

### Why This Matters

A response object helps:

- API generators.
- Tests.
- Middleware.
- Route docs.
- MCP tools.
- Strict controller contracts.
- Future async or streaming responses.

---

## 7.6 Add Route Metadata, Route Inspection, And API Documentation Hooks

### Problem

Routes are executable configuration, but not enough of their intent is machine-readable.

For modern tooling, routes should expose:

- Description.
- Tags.
- Auth requirements.
- Rate limits.
- Request schema.
- Response type.
- Deprecation state.
- Feature/module ownership.

### Recommendation

Extend route declarations with optional metadata:

```cfml
post(
  name = "apiUsersCreate",
  pattern = "/api/users",
  to = "api.users##create",
  description = "Create a user",
  tags = "api,users",
  auth = "admin",
  rateLimit = "apiWrite",
  request = "CreateUserRequest",
  response = "UserResponse"
);
```

For resources:

```cfml
resources(
  "users",
  module = "admin",
  auth = "admin",
  tags = "admin,users"
);
```

### Tooling

Add:

```bash
wheels routes
wheels routes --json
wheels routes --openapi
wheels routes --module=admin
wheels routes --deprecated
wheels doctor routes
```

### Debug Panel

Add a route trace view:

- Matched route.
- Params extracted.
- Middleware applied.
- Controller/action.
- Format negotiation.
- Route model binding result.
- Auth/rate-limit metadata.

### Why This Matters

Route metadata becomes a foundation for:

- API docs.
- MCP context.
- Test generation.
- Security review.
- Dead route detection.
- Route-level deprecation.
- Better developer debugging.

---

## 7.7 Make Lifecycle Hooks Explicit And Traceable

### Problem

Wheels has a request lifecycle, but it is not exposed as clearly as it could be. As the framework gains middleware, modules, packages, DI, route model binding, and response objects, developers need to understand what ran and in what order.

### FW/1 Lesson

FW/1 is good at lifecycle clarity:

- App setup.
- Controller before.
- Action.
- Controller after.
- View setup.
- Response setup.

Wheels should not copy FW/1 directly, but it should expose a clear lifecycle trace.

### Recommendation

Document and instrument the lifecycle:

```text
request start
  parse params
  build request context
  match route
  route model binding
  middleware before
  controller init
  service injection
  verification
  before filters
  action
  render/response
  after filters
  middleware after
request end
```

Add debug tooling:

```bash
wheels trace /posts/1
wheels routes match GET /posts/1
```

And in the debug panel:

- Timeline.
- Hooks.
- Filters.
- Middleware.
- SQL queries.
- DI resolutions.
- Package/module contributions.

### Why This Matters

This gives developers confidence in a framework that still uses conventions. It also makes AI coding tools more effective because they can inspect the framework's actual behavior.

---

## 7.8 Strengthen DI Without Making It The Center Of The Framework

### Problem

Wheels now has a real DI container. That is valuable, but Rails-style frameworks should not make DI ceremony mandatory for basic work.

### Laravel Lesson

Laravel's service container is a major strength, but it is also part of Laravel's larger platform complexity. Wheels should adopt the useful parts without making every controller feel enterprise-heavy.

### FW/1 DI/1 Lesson

DI/1's convention-based service discovery is approachable:

- `model/services` as services.
- `model/beans` as transient beans.
- Property injection by convention.

Wheels can use a similar optional discovery model.

### Recommendation

Keep explicit DI registration:

```cfml
map("mailer").to("app.services.Mailer").asSingleton();
bind("PaymentGateway").to("StripeGateway");
```

Add optional service discovery:

```text
app/services/
app/repositories/
app/policies/
app/actions/
```

With conventions:

- Services default to singleton unless marked otherwise.
- Actions default to transient.
- Repositories default to singleton/request-scoped depending on datasource use.
- Policies default to singleton.

Add CLI inspection:

```bash
wheels services
wheels services graph
wheels services doctor
```

### Controller Usage

Keep simple helper access:

```cfml
mailer = service("mailer");
```

Allow declarative injection:

```cfml
function config() {
  inject("userService");
}
```

Avoid requiring constructor injection for standard controller actions in Wheels 5.

---

## 7.9 Add Scheduler And Lightweight Async On Top Of Jobs

### Problem

Wheels 4 has database-backed jobs. That is a strong zero-dependency foundation. But modern frameworks also expose scheduled tasks and async execution patterns.

ColdBox has scheduled tasks and async/futures. Laravel has scheduler and queues. Rails has Active Job and now richer job continuation support.

### Recommendation

Build on Wheels jobs rather than adding a separate system.

Add scheduler definitions:

```cfml
// config/schedule.cfm
schedule()
  .job("SendDailyDigest")
  .dailyAt("08:00");

schedule()
  .task("cleanupTmp")
  .everyMinutes(30);
```

Add CLI:

```bash
wheels schedule list
wheels schedule run
wheels schedule work
wheels jobs work
```

Add minimal async:

```cfml
future = async(function() {
  return expensiveOperation();
});

result = future.await(timeout = 30);
```

Keep this small. Do not clone the full ColdBox async surface.

### Priority

This is a second-wave Wheels 5 feature, not a prerequisite for the first alpha.

---

## 7.10 Make Configuration Schema-Driven

### Problem

As Wheels adds more settings, config drift becomes harder to debug. Settings should be discoverable, typed, validated, and explainable.

### Recommendation

Add a configuration schema:

```cfml
setting(
  name = "routeModelBinding",
  type = "boolean",
  default = false,
  environment = "all",
  description = "Enables automatic route model binding"
);
```

Then expose:

```bash
wheels config list
wheels config get routeModelBinding
wheels config doctor
wheels config explain routeModelBinding
```

### Environment Layering

Adopt explicit layering:

```text
framework defaults
app defaults
environment config
host/tenant overrides
runtime env vars
```

Show final resolved config:

```bash
wheels config effective --environment=production
```

### FW/1 Lesson

FW/1's `variables.framework` config and environment override model is simple and understandable. Wheels can take the clarity without adopting the same API.

---

## 7.11 Treat CLI And Distribution As Release-Critical

### Problem

The LuCLI-based CLI is now the public face of Wheels. It is how many developers will first experience the framework. It is also how CI, generated apps, and distribution can be tested.

### Recommendation

Make this rule explicit:

> If a user can install Wheels through Homebrew, Scoop, apt, or yum/dnf, the release is not done until that install path has been tested on a clean system.

### Required Canaries

For every release candidate and final release:

```bash
wheels --version
wheels new smokeapp
cd smokeapp
wheels start
wheels generate scaffold Post title:string body:text
wheels dbmigrate latest
wheels test run
wheels routes
wheels doctor
```

Run these through:

- Homebrew on macOS.
- Scoop on Windows.
- apt on Ubuntu/Debian.
- yum/dnf on Rocky/RHEL.

### Why This Matters

The CLI is not just tooling. It is part of the framework's trust story. A clean public install path is worth more than another advanced feature.

---

## 7.12 Keep The Monorepo

### Recommendation

Keep the monorepo for Wheels 5.

### Rationale

The repo now contains tightly coupled components:

- Framework core.
- CLI module.
- Generated app templates.
- Test runner.
- Browser testing infrastructure.
- Build scripts.
- Package definitions.
- Distribution drafts.
- Release workflows.
- Compatibility matrix.

Splitting these into separate repos would create version skew:

- CLI expects a framework template version.
- Framework tests expect CLI endpoints.
- Generated apps depend on template and core alignment.
- Distribution packages need framework and CLI artifacts together.
- Release canaries must test the combined product.

### What Can Stay Separate

Separate repos still make sense for:

- Homebrew tap.
- Scoop bucket.
- apt repository metadata.
- yum/dnf repository metadata.
- Public docs site deployment, if operationally cleaner.
- Truly independent packages once their APIs stabilize.

### Monorepo Improvements

Use path filters and clear ownership areas:

```text
vendor/wheels/       framework core
cli/lucli/           CLI module
tests/               generated app testing
vendor/wheels/tests/ framework core tests
cli/lucli/tests/     CLI tests
tools/ci/            CI harness
tools/build/         build/release
tools/distribution-drafts/
docs/
```

Add a top-level `CONTRIBUTING` section for which tests to run based on touched paths.

---

## 8. Automated Testing Strategy

Testing needs a full design, because Wheels has a broader compatibility target than most frameworks.

### 8.1 Test Tiers

Use tiers with clear purpose.

#### Tier 0: Static And Metadata Checks

Runs on every PR.

Includes:

- Commit/PR title lint.
- JSON/YAML validation.
- Manifest validation.
- API docs generation validation.
- Route/config metadata validation if added.
- Basic formatting or syntax checks where available.

Goal: under 2 minutes.

#### Tier 1: Fast PR Gate

Runs on every PR and blocks merge.

Current seed exists in [`.github/workflows/pr.yml`](../../.github/workflows/pr.yml): Lucee 7 + SQLite through LuCLI.

Recommended contents:

- Lucee latest + SQLite.
- Core WheelsTest.
- CLI module tests.
- Generated app smoke.
- Minimal browser smoke.
- `wheels doctor`.

Target: 5 to 10 minutes.

Example:

```bash
wheels ci run --engine=lucee7 --db=sqlite --suite=core,cli,generated,browser-smoke
```

#### Tier 2: Conditional PR Matrix

Runs based on changed paths or labels.

Examples:

- ORM/query/migration changes:
  - PostgreSQL.
  - MySQL.
  - SQLite.
- SQL Server adapter changes:
  - SQL Server lane.
- Oracle adapter changes:
  - Oracle lane.
- Engine adapter changes:
  - Lucee + Adobe + BoxLang SQLite smoke.
- CLI/distribution changes:
  - Linux package smoke.
  - macOS Homebrew smoke if available.
  - Windows Scoop smoke if available.
- Browser testing changes:
  - Full browser specs.

This keeps PR feedback relevant without running the entire universe every time.

#### Tier 3: Nightly Compatibility Matrix

Runs on schedule and manual dispatch.

Current seed exists in [`.github/workflows/compat-matrix.yml`](../../.github/workflows/compat-matrix.yml).

Recommended matrix:

Engines:

- Lucee 6.
- Lucee 7.
- Adobe 2023.
- Adobe 2025.
- BoxLang.

Databases:

- SQLite.
- PostgreSQL.
- MySQL/MariaDB.
- SQL Server.
- CockroachDB.
- Oracle.
- H2 where relevant.

Nightly should:

- Run all combinations that are supported.
- Publish a dashboard summary.
- Upload JUnit and JSON artifacts.
- Create or update GitHub issues for persistent failures.
- Avoid noisy Slack unless a previously green lane turns red.

#### Tier 4: Release Candidate Gate

Runs on RC branches and blocks release.

Includes:

- Full engine/database matrix.
- Generated app lifecycle tests.
- Upgrade tests from previous supported version.
- Package install tests using built artifacts.
- Browser tests.
- CLI smoke tests.
- Distribution canaries.
- Docs validation.

RC should not tolerate hidden soft failures. If a lane is soft-fail, it must be named, documented, and linked to an issue.

#### Tier 5: Post-Release Canaries

Runs after release assets and package repositories publish.

Tests public install paths:

- Homebrew.
- Scoop.
- apt.
- yum/dnf.

This catches the failure class that normal CI cannot catch: real users installing real artifacts through public channels.

### 8.2 One Test Command Contract

Add a first-class CI command:

```bash
wheels ci run
```

Example options:

```bash
wheels ci run --engine=lucee7 --db=sqlite --suite=core
wheels ci run --engine=adobe2025 --db=postgres --suite=core
wheels ci run --suite=cli,generated,browser
wheels ci run --matrix=nightly
wheels ci run --matrix=release
```

This command should be the shared contract for:

- GitHub Actions.
- Local maintainers.
- Proxmox runners.
- Release workflows.
- Future dashboards.

### 8.3 Matrix Manifest

Create one source of truth:

```text
tools/ci/matrix.yml
```

Example:

```yaml
engines:
  lucee7:
    version: "7"
    port: 60007
    support: primary
  adobe2025:
    version: "2025"
    port: 62025
    support: primary
  boxlang:
    version: "1"
    port: 60001
    support: compatibility
  rustcfml:
    version: "experimental"
    support: experimental
    purpose: conformance
    releaseBlocking: false

databases:
  sqlite:
    support: primary
  postgres:
    support: primary
  mysql:
    support: primary
  sqlserver:
    support: primary
  oracle:
    support: supported
  cockroachdb:
    support: supported

lanes:
  pr-fast:
    - engine: lucee7
      db: sqlite
      suites: [core, cli, generated, browser-smoke]
  nightly:
    include: all-supported
  release:
    include: all-supported
    blocking: true
```

Use this manifest to generate:

- GitHub Actions matrix.
- Local `wheels ci run --matrix`.
- Docs compatibility table.
- `wheels doctor compatibility`.
- Experimental conformance lanes for RustCFML and future engines.

### 8.4 GitHub Actions vs Proxmox

Use both.

GitHub-hosted runners are best for:

- Fast PR checks.
- Linux Lucee/SQLite.
- Docs validation.
- Basic packaging checks.
- Public OSS transparency.

Proxmox/self-hosted runners are best for:

- Heavy Adobe CF lanes.
- Oracle and SQL Server.
- Long-running browser suites.
- Fresh OS package canaries.
- Release candidate full gates.
- Ephemeral VM clean-room testing.

Recommended progression:

1. Start with a small static self-hosted runner pool.
2. Stabilize heavy lanes.
3. Move to ephemeral clone-per-job VMs for release canaries.
4. Publish results back to GitHub checks.

### 8.5 Generated App Testing

Every major feature should be tested in a generated app, not only in framework internals.

Generated app smoke:

```bash
wheels new smokeapp
cd smokeapp
wheels generate scaffold Post title:string body:text
wheels dbmigrate latest
wheels test run
wheels start
curl /posts
```

Why this matters:

- Catches template drift.
- Catches CLI/framework version skew.
- Catches distribution issues.
- Catches docs examples that no longer work.

### 8.6 Upgrade Testing

Wheels 5 should test upgrades from:

- Latest Wheels 4 stable.
- Last supported Wheels 3 version if a migration path remains.

Upgrade test flow:

```bash
wheels new app --version=4.x
apply fixture app changes
wheels upgrade --to=5
wheels dbmigrate latest
wheels test run
```

Include fixtures for:

- Legacy plugins.
- Packages.
- Route model binding.
- Raw `params` usage.
- Generated scaffold.
- Migrations.
- Jobs.
- Middleware.

### 8.7 Conformance Testing

Conformance testing should become a separate tier from full framework testing.

Full framework tests answer:

> Does Wheels work?

Conformance tests answer:

> Does this engine/tool/runtime satisfy the contracts Wheels requires?

This distinction is important for RustCFML, LuCLI, and future engine/tooling integrations. A new runtime should not need to pass the full Wheels application suite before it can produce useful signal. It should be able to start with focused conformance lanes.

Recommended conformance tiers:

- **Language conformance:** syntax, scopes, structs, arrays, closures, JSON.
- **CFC conformance:** construction, inheritance, mixins, dynamic invocation, `argumentCollection`, `onMissingMethod`.
- **Request conformance:** CGI/request/session/cookie scope simulation, method override, headers, params merge.
- **Controller conformance:** action invocation, filters, rendering, redirecting, response object.
- **CLI conformance:** exit codes, JSON output, server lifecycle, module dispatch.
- **Generated app conformance:** minimal scaffold lifecycle.

RustCFML should start with language/CFC/request/controller conformance. LuCLI should focus on CLI/server/module conformance. Lucee, Adobe CF, and BoxLang should run both conformance and full framework tests.

The release dashboard should distinguish:

```text
Engine      Conformance      Full Suite      Support
Lucee 7     pass             pass            primary
Adobe 2025  pass             pass            primary
BoxLang     pass             partial/pass    supported
RustCFML    partial          not-applicable  experimental
```

---

## 9. Compatibility And Deprecation Plan

### 9.1 Compatibility Defaults

Wheels 5 should be conservative at runtime:

- Existing controllers using unscoped `params` should work.
- Existing views should work.
- Existing model APIs should work unless explicitly deprecated.
- Existing migrations should work.
- Existing packages should work if they use the modern package system.

But Wheels 5 should be stricter at tooling time:

- `wheels doctor` should warn about deprecated APIs.
- Generators should use new idioms.
- Docs should stop teaching legacy patterns.
- CI should enforce new package/test/docs contracts.

### 9.2 Candidate Removals

Remove from core in Wheels 5:

- Legacy `plugins/` automatic loading, or move to a compatibility package.
- RocketUnit as a first-class test style.
- Old `wheels.Test` alias if the deprecation period is complete.
- CommandBox-era CLI documentation and commands.
- Deprecated package/plugin formats.
- Deprecated HTTP MCP endpoint if stdio MCP is the supported path.
- Any legacy asset helpers superseded by the modern asset/Vite story.

### 9.3 Candidate Strict Modes

Add opt-in strict modes:

```cfml
set(strictParams = true);
set(strictControllers = true);
set(strictRoutes = true);
set(strictPackages = true);
set(strictConfig = true);
```

Behavior examples:

- `strictParams`: model mass assignment from raw params errors unless permitted.
- `strictControllers`: action names must not collide with framework methods; undeclared globals warn/error.
- `strictRoutes`: route metadata and constraints required for API routes.
- `strictPackages`: invalid package manifests fail startup.
- `strictConfig`: unknown settings fail startup.

Default these carefully. Strict mode should be easy to adopt but not forced on legacy apps immediately.

---

## 10. Framework Comparison Implications

### 10.1 Rails

Rails remains the closest philosophical comparison.

Key Rails lessons:

- Keep conventions simple.
- Keep controller actions simple.
- Keep `params`.
- Make `params` safer.
- Put mass-assignment safety at the controller boundary.
- Use generators to teach preferred style.
- Let the framework stay pleasant for common CRUD.

Wheels should follow Rails here.

Do:

- Keep `params`.
- Add strong params.
- Add request context as optional explicit API.
- Improve route/controller introspection.

Do not:

- Force every action into explicit argument style immediately.
- Turn controller code into dependency-heavy ceremony.

### 10.2 Laravel

Laravel is the strongest DX competitor among modern frameworks.

Useful lessons:

- CLI polish matters.
- Service container matters.
- Queues and scheduler matter.
- Middleware and route groups matter.
- First-party docs and examples matter.

What Wheels should adopt:

- CLI-centered workflows.
- Route groups/modules.
- Scheduler.
- Stronger DI tooling.
- Better generated app experience.

What Wheels should avoid:

- Too much magic behind facades.
- Large platform surface without enough docs/testing.

### 10.3 Django

Django's main strengths are stability, admin, forms, security defaults, and documentation.

Useful lessons:

- Mature docs are a feature.
- Admin/productivity tooling can define a framework.
- Security defaults should be boring and consistent.
- Backward compatibility policy matters.

What Wheels should adopt:

- Strong docs gate for releases.
- Better admin generator.
- Clear security defaults.
- Compatibility policy.

What Wheels probably should not chase immediately:

- A full Django-style admin app.
- A full Django forms system.

Those could be packages later.

### 10.4 FW/1

FW/1's value is simplicity and clarity.

Best ideas to adopt:

- Subsystems as simple app modules.
- Explicit request context.
- Clear lifecycle hooks.
- Convention service discovery.
- Environment config layering.
- Response builder style.

Ideas not to adopt:

- `?action=section.item` as primary routing.
- Single-file framework architecture.
- Broad AOP as a headline feature.
- Direct view access to too much framework API.

### 10.5 ColdBox

ColdBox is stronger as an enterprise platform. Wheels should not chase it feature-for-feature.

Best ideas to selectively adopt:

- First-class modules.
- Explicit request context.
- Route visualizer.
- REST response object.
- Scheduler.
- Interceptor-like lifecycle events only where needed.

Ideas to avoid:

- Turning Wheels into a large platform with many named subsystems.
- Making BoxLang the primary optimization target.
- Requiring enterprise ceremony for normal CRUD apps.

---

## 11. Proposed Wheels 5 Feature Groups

### Group A: Required For Wheels 5 Alpha

These should be in the first Wheels 5 alpha because they define the architecture.

1. Runtime/tooling partnership track created.
2. Initial contract documents for RequestContext, params, response, CLI output, and engine adapter behavior.
3. Initial conformance suite skeleton.
4. LuCLI upstream capability list for Wheels 5.
5. RustCFML experimental conformance lane defined.
6. RequestContext internal object.
7. Compatibility action injection for `params` and `rc`.
8. Strong params initial API.
9. Response object initial API.
10. Module skeleton and route mounting.
11. Config schema foundation.
12. CI matrix manifest.
13. `wheels ci run` initial implementation.
14. Deprecation warnings for removals.
15. Docs explaining the new architecture.

### Group B: Required For Wheels 5 Beta

1. Route metadata.
2. Route inspection and route matching CLI.
3. Module tests and generators.
4. Package validation and migration tooling.
5. Generated app smoke tests.
6. Upgrade tests from Wheels 4.
7. Strict mode previews.
8. Compatibility dashboard.
9. Conformance dashboard.
10. LuCLI server lifecycle and JSON output contracts implemented or shimmed.
11. RustCFML can run at least language/CFC/request conformance tiers.

### Group C: Required For Wheels 5 Final

1. Full release candidate matrix.
2. Public distribution canaries.
3. Final deprecation/removal list.
4. Complete upgrade guide.
5. Docs examples updated to Wheels 5 idioms.
6. `wheels doctor` coverage for compatibility, config, routes, packages, and params.
7. Known incompatibilities documented.
8. Runtime/tooling contract docs published.
9. Experimental RustCFML status documented honestly.
10. LuCLI upstream dependencies either released or covered by documented temporary shims.

### Group D: Post-5.0 Candidates

These are valuable but should not block 5.0:

1. Scheduler.
2. Lightweight async/futures.
3. Full OpenAPI generator.
4. Advanced admin package.
5. Forms/request validation package.
6. Package registry UI.
7. Full module extraction tooling.
8. RustCFML full framework suite attempts.
9. Additional engine adapters driven by the conformance suite.

---

## 12. Proposed Implementation Slices

### Slice 0: Runtime And Tooling Contracts

Deliverables:

- Create `docs/contracts/`.
- Draft RequestContext, params, response, CLI output, engine adapter, and test result contracts.
- Create initial `tests/conformance/` layout.
- Define support labels for Lucee, Adobe CF, BoxLang, and RustCFML.
- Create LuCLI upstream issue list for Wheels 5 needs.
- Create RustCFML experimental conformance target list.

Success criteria:

- Every major Wheels 5 feature has a contract home.
- The CI matrix can distinguish conformance, full framework, and distribution lanes.
- LuCLI/RustCFML-dependent work is tracked as first-class roadmap work.
- Experimental support cannot be confused with production support.

### Slice 1: RequestContext Foundation

Deliverables:

- Add request context construction in dispatch.
- Attach `request.wheels.rc`.
- Attach `variables.rc`.
- Keep `variables.params`.
- Add action injection where engine-safe.
- Add tests across Lucee, Adobe, BoxLang.

Success criteria:

- Existing controller tests pass unchanged.
- New tests can declare `function show(params, rc)`.
- `params` and `rc.params` point to the same data.

### Slice 2: Strong Params

Deliverables:

- Parameter object/wrapper.
- `require`.
- `permit`.
- `expect`.
- Safe `toStruct`.
- Exceptions mapped to 400 responses.
- Generator examples.

Success criteria:

- Raw existing params access still works.
- Generated CRUD uses parameter contracts.
- Mass assignment from unpermitted params can warn in doctor/strict mode.

### Slice 3: Response Object

Deliverables:

- `response().json()`.
- `response().status()`.
- `response().header()`.
- `response().redirectTo()`.
- `response().file()`.
- Compatibility with existing render/redirect helpers.

Success criteria:

- API controllers can return a response object.
- Existing controllers still work.
- Tests can inspect response status/body/headers consistently.

### Slice 4: Modules

Deliverables:

- `app/modules/<name>` convention.
- `Module.cfc` lifecycle.
- Route mounting.
- Module service registration.
- Module tests.
- Generator.

Success criteria:

- `wheels generate module admin` creates a working module.
- Routes can be listed by module.
- Tests can run by module.
- Module views/layouts resolve predictably.

### Slice 5: LuCLI Platform Integration

Deliverables:

- Define `wheels ci run` command behavior.
- Define machine-readable output conventions for CI-oriented commands.
- Stabilize server lifecycle calls used by Wheels tests.
- Track upstream LuCLI PRs/issues for generic capabilities.
- Keep temporary Wheels shims documented and small.

Success criteria:

- Local, GitHub Actions, and Proxmox lanes can call the same `wheels ci run` contract.
- CLI commands used by automation have stable exit codes.
- JSON output can be consumed by dashboards and release workflows.
- Wheels-specific hacks are either removed or explicitly temporary.

### Slice 6: RustCFML Experimental Lane

Deliverables:

- Add RustCFML to the matrix manifest as experimental.
- Add language/CFC/request conformance suites that can run without a full database-backed app.
- Document unsupported features clearly.
- Track RustCFML upstream issues/PRs tied to conformance failures.

Success criteria:

- RustCFML produces useful pass/fail signal without being release-blocking.
- Wheels assumptions about CFML semantics are captured as tests.
- No user-facing documentation implies RustCFML production support.

### Slice 7: CI Harness

Deliverables:

- `tools/ci/matrix.yml`.
- `wheels ci run`.
- PR fast lane using the command.
- Nightly matrix using the manifest.
- Release matrix definition.
- Conformance matrix definition.

Success criteria:

- GitHub Actions no longer encode the matrix in only YAML.
- Maintainers can run the same lanes locally.
- Compatibility docs can be generated from the manifest.
- Conformance docs can be generated from the same result data.

### Slice 8: Cleanup And Removals

Deliverables:

- Remove or isolate legacy plugin loader.
- Remove old test aliases where appropriate.
- Remove old CLI docs/paths.
- Add compatibility package if needed.
- Upgrade guide.

Success criteria:

- Wheels 5 startup path is simpler.
- Legacy users get clear migration errors or adapter path.
- Docs no longer teach removed APIs.

---

## 13. Documentation Plan

Wheels 5 needs documentation written with the same care as code.

### Required Guides

1. What's New In Wheels 5.
2. Upgrading From Wheels 4.
3. Request Context And Params.
4. Strong Params.
5. Response Objects.
6. Application Modules.
7. Packages vs Modules.
8. Testing Wheels Applications.
9. CI And Compatibility Matrix.
10. Engine Compatibility.
11. Building APIs.
12. Strict Mode.
13. Runtime And Tooling Partnerships.
14. Wheels Conformance Suite.
15. LuCLI Platform Integration.
16. RustCFML Experimental Support.

### Generator-Driven Docs

Every generator should point to docs that match its output.

If `wheels generate scaffold` creates `userParams(params)`, the docs should explain that exact pattern.

### Docs Gate

For Wheels 5 final:

- No known stale CLI references.
- No CommandBox-era install instructions unless explicitly historical.
- Every new major feature has a guide.
- Every deprecation has an upgrade note.
- Compatibility matrix is published.
- Conformance status is published separately from full framework support.
- Experimental engine status is clearly labeled.

---

## 14. Risks And Tradeoffs

### Risk: Too Much Change In One Major

Mitigation:

- Keep runtime compatibility high.
- Make new patterns additive.
- Use strict mode opt-in.
- Split implementation into slices.

### Risk: RequestContext Becomes A Second API Competing With `params`

Mitigation:

- Document clear roles.
- `params` remains the friendly input API.
- `rc` is the full request context.
- Generators can include both initially, then settle on the best idiom after feedback.

### Risk: Modules Become Too Heavy

Mitigation:

- Start with simple mounted app modules.
- Avoid HMVC complexity in 5.0.
- No separate module DI container by default.
- No broad AOP/interceptor system as part of module v1.

### Risk: Strong Params Frustrates Existing Developers

Mitigation:

- Do not force it in compatibility mode.
- Teach through generators.
- Warn through doctor.
- Enforce only in strict mode at first.

### Risk: CI Matrix Is Too Expensive

Mitigation:

- Keep PR gate small.
- Use conditional lanes.
- Run full matrix nightly and on RC.
- Move heavy lanes to Proxmox/self-hosted.
- Publish status without blocking every PR.

### Risk: Engine Neutrality Slows Innovation

Mitigation:

- Use engine adapters.
- Define primary vs compatibility support levels.
- Allow experimental features behind capability checks.
- Make unsupported engine behavior explicit.

### Risk: Partnership Work Becomes Informal And Untrackable

Mitigation:

- Use labels for upstream LuCLI, upstream RustCFML, and engine contracts.
- Keep contract docs in the Wheels repo.
- Link upstream PRs/issues from Wheels roadmap issues.
- Treat temporary shims as technical debt with owners.

### Risk: RustCFML Experimental Support Is Misread As Production Support

Mitigation:

- Label RustCFML as experimental everywhere.
- Keep it non-release-blocking until explicitly promoted.
- Publish conformance status separately from full framework status.
- Avoid marketing language that implies production readiness.

### Risk: LuCLI Coupling Creates A Bottleneck

Mitigation:

- Keep Wheels-specific behavior in Wheels.
- Push generic behavior upstream.
- Maintain small documented shims when upstream timing does not match Wheels release timing.
- Version LuCLI expectations in the matrix manifest and `wheels doctor`.

---

## 15. Recommended Release Policy

### Support Levels

Define support levels for engine/database combinations:

- **Primary:** must pass PR or RC gates; failures block release.
- **Supported:** tested nightly and RC; failures block release unless documented.
- **Compatibility:** expected to work; tested regularly; failures may be non-blocking for a limited time.
- **Experimental:** no release guarantee.

Experimental targets such as RustCFML should be useful to maintainers without creating user confusion. Their purpose is conformance signal, not production support.

### Deprecation Policy

Recommended:

- Deprecate in one minor line.
- Warn at runtime or doctor time.
- Document migration.
- Remove in next major.

For 5.0, anything deprecated throughout 4.x can be removed if:

- There is a migration path.
- There is an upgrade guide.
- There are tests for the new path.

### Release Gate

Wheels 5 final should require:

- Fast PR lane green.
- Full RC matrix green or documented.
- Distribution canaries green.
- Upgrade tests green.
- Docs gate green.
- No unresolved P0/P1 issues.

---

## 16. Recommended Decision Log

These are proposed decisions to ratify.

### Decision 1: Do Not Chase ColdBox

Wheels 5 should not attempt to match ColdBox's full enterprise platform surface.

Adopt selectively:

- Modules.
- Request context.
- Route inspection.
- Response object.
- Scheduler later.

Reject for now:

- Full HMVC complexity.
- Broad interceptors/AOP.
- BoxLang-first optimization.
- Large subsystem taxonomy.

### Decision 2: Keep `params`

`params` remains part of the Wheels controller API.

Wheels should add:

- `rc.params`.
- Action argument injection.
- Strong params.
- Strict mode.

But old `params.key` code should continue to work in Wheels 5.

### Decision 3: Keep The Monorepo

Keep core, CLI, templates, tests, build, and docs together.

Use separate repos only for distribution metadata and truly independent packages.

### Decision 4: Make CLI The Test Contract

Prefer:

```bash
wheels ci run ...
```

over workflow-specific shell scripts as the long-term contract.

GitHub Actions, Proxmox runners, and local maintainers should all run the same command.

### Decision 5: Engine Neutrality Is A Feature

Wheels 5 should support BoxLang, but remain neutral across Lucee, Adobe CF, and BoxLang.

This should be visible in:

- CI.
- Docs.
- CLI doctor.
- Release notes.

### Decision 6: LuCLI Is A Strategic Platform Partner

The Wheels CLI should continue to be built on LuCLI, and generic CLI/runtime capabilities should be contributed upstream where practical.

Wheels owns:

- User-facing command design.
- Framework-specific generators.
- Framework-specific CI commands.
- Distribution and release packaging.

LuCLI should own or grow:

- Generic server lifecycle.
- Module execution.
- Cross-platform binary behavior.
- Engine profile behavior.
- Machine-readable output conventions where they are not Wheels-specific.

### Decision 7: RustCFML Is An Experimental Conformance Partner

RustCFML should be added to the roadmap as an experimental conformance target, not a production support promise.

Its value is to:

- Expose hidden engine assumptions.
- Clarify CFML semantics Wheels needs.
- Provide a future runtime/tooling path if it matures.
- Give RustCFML real framework-driven compatibility targets.

### Decision 8: Contracts Come Before Major New Architecture

For Wheels 5 architectural features, write or update the contract first:

- RequestContext.
- Params.
- Response.
- Modules.
- Packages.
- CLI output.
- Engine adapters.
- Test results.

Then implement against the contract and add conformance coverage.

---

## 17. Open Questions

These need maintainer decisions before implementation plans are written.

1. Should Wheels 5 support Adobe ColdFusion 2018 and 2021, or require Adobe 2023+?
2. Should Lucee 5 remain supported, or should Wheels 5 require Lucee 6+?
3. Should BoxLang be primary support, supported, compatibility, or experimental for 5.0?
4. Should Oracle be a release-blocking database for 5.0?
5. Should legacy `plugins/` be removed from core or moved behind a compatibility package?
6. Should RocketUnit compatibility be fully removed or left as an external adapter?
7. Should generated controllers use `function action(params, rc)` or `function action(rc)`?
8. Should strong params be warning-only by default in 5.0?
9. Should modules ship in 5.0 final or as a 5.1 feature after RequestContext lands?
10. Should Proxmox ephemeral runners be part of the first 5.0 release gate or added after static self-hosted runners stabilize?
11. Which LuCLI capabilities must be upstreamed before Wheels 5 beta?
12. What minimum conformance tier should RustCFML target before Wheels 5 final?
13. Should `tests/conformance/` live in the main Wheels repo or become a separate shared repo later?
14. Should contract docs be treated as release-blocking for architectural features?
15. Who owns the compatibility dashboard and cross-repo milestone hygiene?

---

## 18. Bottom Line

The best Wheels 5 is not a bigger Wheels 4. It is a clearer Wheels.

Wheels 5 should preserve the framework's most valuable quality: a developer can understand it quickly and build useful applications without ceremony. The work is to make that simplicity more durable:

- Friendly `params`, backed by safer parameter contracts.
- Simple controllers, backed by explicit request context.
- Convention-based apps, backed by modules and package contracts.
- Easy local development, backed by the LuCLI CLI.
- Broad compatibility, backed by a real automated matrix.
- Open runtime/tooling partnerships, backed by conformance contracts.
- Modern features, backed by stronger docs and stricter release gates.

That is a strong lane. It is different from ColdBox, still recognizable to Rails-minded developers, and valuable for the CFML community.
