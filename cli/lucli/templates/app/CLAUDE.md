# Wheels Framework — Application Developer Guide (AI)

This file is for developers BUILDING applications WITH the Wheels CFML
framework — not for framework maintainers. It ships in every distributed
artifact (`box install wheels`, the ForgeBox starter app, and new apps
scaffolded by `wheels new`) and is auto-loaded by AI coding assistants
(Claude Code, and via AGENTS.md by other tools).

Maintainer documentation (cross-engine invariants, test infrastructure,
release engineering) lives in the framework repository only and never
ships to consumers.

## Wheels Conventions

- **config()**: All model associations/validations/callbacks and controller filters/verifies go in `config()`.
- **Naming**: Models singular PascalCase (`User.cfc`), controllers plural PascalCase (`Users.cfc`), tables plural lowercase (`users`).
- **Parameters**: `params.key` for URL key, `params.user` for form struct, `params.user.firstName` for nested.
- **extends**: Models extend `"Model"`, controllers extend `"Controller"`, tests extend `"wheels.WheelsTest"`. (Legacy: `"wheels.Test"` was RocketUnit — never use for new tests.)
- **Validation property param**: `property` (singular) for single, `properties` (plural) for list: `validatesPresenceOf(properties="name,email")`.
- **Mass assignment**: open by default for compatibility. `set(massAssignmentStrict=true)` fail-closes it — a model with neither `accessibleProperties()` nor `protectedProperties()` then rejects unlisted posted properties. Define one of the two lists per model.

## Common Mistakes

- **Don't mix positional and named arguments** in one framework call: `hasMany("comments")` or `hasMany(name="comments", dependent="delete")`, never `hasMany("comments", dependent="delete")`.
- **Finders return queries, not arrays** — loop with `<cfloop query="users">`.
- **Nested resources use `callback=`**: `.resources(name="posts", callback=function(map) { map.resources("comments"); })`. `scope()`, `namespace()`, `package()` and `controller()` take `callback=` too.
- **Routes match first to last** — resources, then custom named routes, then root, then the wildcard last. Placeholder-free patterns (`/posts/featured`) win over `/posts/[key]` regardless of order.
- **Controller filters are `private`** — a public method is a routable action. Action names can't reuse framework helper names (`redirectTo`, `linkTo`, …).
- **`cfparam` every variable a view reads.**
- **Never name a parameter or local variable after a CFML scope** (`url`, `form`, `request`, `session`, `application`, …) — the scope can win over the argument.
- **Structs and arrays aren't booleans**: `!x` and `x ? a : b` throw on a struct or array ("Can't cast Complex Object Type Struct to a boolean value"). Test the shape you mean: `IsBoolean(x) && x`, `IsSimpleValue(x) && Len(x)`, `IsStruct(x) && !StructIsEmpty(x)`, `IsArray(x) && ArrayLen(x)`.
- **`timestamps()` adds `createdAt`, `updatedAt` and `deletedAt`**; migration seed data goes through `execute("…SQL…")` (no `parameters` argument), with `CURRENT_TIMESTAMP` rather than `NOW()`, which fails on SQLite and SQL Server.

## Topic Index

Open the file for a topic before working on it:

- Models (finders, associations, validations, scopes): `.ai/models.md`
- Routing and route model binding: `.ai/routing.md`
- Pagination, development error page: `.ai/views.md`
- Partial caching: `.ai/caching.md`
- Middleware, rate limiting: `.ai/middleware.md`
- DI container: `.ai/di.md`
- Auth: `.ai/auth.md`
- Storage: `.ai/storage.md`
- Packages: `.ai/packages.md`
- Migrations, seeding: `.ai/migrations.md`
- Background jobs: `.ai/jobs.md`
- Server-sent events: `.ai/sse.md`
- Changing settings in specs: `.ai/testing.md`
- Guides, `/wheels/ai`: `.ai/README.md`

## Testing Quick Reference

**All new tests use WheelsTest BDD syntax.** RocketUnit (`test_` prefix, `assert()`) is legacy only.

```cfm
// vendor/wheels/tests/specs/model/MyFeatureSpec.cfc (framework) or tests/specs/...(app)
component extends="wheels.WheelsTest" {
    function run() {
        describe("My Feature", () => {
            it("validates presence of name", () => {
                var user = model("User").new();
                expect(user.valid()).toBeFalse();
            });
        });
    }
}
```

### Two test suites

- **App tests**: `/wheels/app/tests` — project-specific, in `tests/specs/`. Uses `tests/populate.cfm` and `tests/runner.cfm`.
- **Core tests**: `/wheels/core/tests` — framework, in `vendor/wheels/tests/specs/`. Uses `vendor/wheels/tests/populate.cfm`. **This is what CI runs across all engines × DBs.**

**Isolated test application:** `public/Application.cfc` includes `vendor/wheels/events/testcontext.cfm` after `config/app.cfm`, so runner URLs (and browser requests that carry the per-process runner secret) bind `<this.name>_wheelsTest` — a separate CFML application scope; the live `application.wheels` is untouched. `$testClient(testContext=false)` addresses the live app. Apps whose `Application.cfc` lacks the include run tests against the live application scope under a named lock.

**`WHEELS_ENV` is required for isolation.** The isolated binding is honoured only when `WHEELS_ENV` is `development` or `testing` — the one environment signal readable before the app starts. `wheels new` sets `WHEELS_ENV=development` in `.env`; if yours doesn't, `wheels test` still runs but against the **live** application scope (a one-line "isolation is OFF" warning is logged and returned as the `X-Wheels-Test-Isolation: off` header). The runner path is matched against the request path, the `X-Wheels-Test-Context` header/cookie must equal the per-process runner secret from a loopback peer, the test runners refuse to run when the environment is `production`, and `/wheels/app/tests` now defaults to the `<datasource>_test` database — **refusing to run if it is absent** rather than silently using the primary datasource. Precedence: `useTestDB=true` always requires `<datasource>_test`; `useTestDB=false` (`wheels test --no-test-db`) runs against the primary datasource; and `set(allowTestsAgainstPrimaryDatasource=true)` in `config/settings.cfm` lets an **omitted** flag (e.g. an older CLI) run against the primary datasource with a warning instead of refusing. (A default `wheels new` SQLite app already has a `<name>_test` datasource, so this never triggers for it.)

The runner compiles every CFC under the spec directory, so one compilation error in any spec file fails the entire run, not just that file. The usual cause on Adobe CF is an inline closure passed as a constructor named argument — assign the closure to a variable first.

### Test-specific gotchas

- **Test infra scope**: Wheels internals (`$dbinfo`, `model()`, etc.) aren't available as bare calls in `.cfm` files the test runner includes, such as `tests/populate.cfm`. Use `application.wo.model()` or native CFML tags (`cfdbinfo`).
- **`#` escape**: HTML entities like `&#111;` contain `#` which CFML interprets as expression delimiter. In string literals, escape: `&##111;`. Comments (`//`) are fine. Unescaped `#` in strings crashes the **entire** test suite, not just that file.
- **Route-state save/restore in test specs**: `wheels.WheelsTest` provides `$snapshotRoutes()`, `$restoreRoutes(snapshot)`, and `$clearRoutes()`. A spec that redefines the route table MUST snapshot in `beforeEach` and restore in `afterEach`, or it leaks stale route state into later specs:
  `beforeEach(() => { variables._routes = $snapshotRoutes(); $clearRoutes(); g.mapper()...end(); g.$setNamedRoutePositions(); }); afterEach(() => $restoreRoutes(variables._routes));`

### Running tests locally

```bash
wheels test                      # run the app's tests/specs/ (WheelsTest)
wheels test tests.specs.models   # a subdirectory of specs
wheels test --filter=UserSpec    # one spec file, by name
```

The CLI boots the app on an isolated port and runs the suite over HTTP,
mirroring CI. Browser-driven specs need Playwright installed once:
`wheels browser setup`.

