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

## Model Quick Reference

```cfm
component extends="Model" {
    function config() {
        // Table/key (only if non-conventional)
        table("tbl_users");        // setter is table(); tableName() is a getter — tableName("x") throws Wheels.InvalidArgument in dev/testing, no-op in production (#3079)
        setPrimaryKey("userId");

        // Associations — all named params when using options
        hasMany(name="orders", dependent="delete");
        belongsTo(name="role");

        // Validations
        validatesPresenceOf("firstName,lastName,email");
        validatesUniquenessOf(property="email");
        validatesFormatOf(property="email", regEx="^[\w\.-]+@[\w\.-]+\.\w+$");

        // Callbacks
        beforeSave("sanitizeInput");

        // Calculated SQL properties — select=false keeps them off the default SELECT (hot path)
        property(name="fullName", sql="firstName || ' ' || lastName", select=false);

        // Query scopes — reusable, composable query fragments
        scope(name="active", where="status = 'active'");
        scope(name="recent", order="createdAt DESC");
        scope(name="byRole", handler="scopeByRole");  // dynamic scope

        // Enums — named values with auto-generated checkers and scopes
        enum(property="status", values="draft,published,archived");
        enum(property="priority", values={low: 0, medium: 1, high: 2});
    }

    private struct function scopeByRole(required string role) {
        return {where: "role = '#arguments.role#'"};
    }
}
```

Finders: `model("User").findAll()`, `findOne(where="...")`, `findByKey(params.key)`.
Create: `model("User").new(params.user).save()`, or `model("User").create(params.user)`.
Include associations: `findAll(include="role,orders")`. Pagination: `findAll(page=params.page, perPage=25)`.
Opt a `select=false` calculated property into one call (additive): `findAll(includeCalculated="fullName")`. Unknown names throw `Wheels.CalculatedPropertyNotFound` in dev/testing.

### Scopes / Enums / Builder / Batch

```cfm
// Scopes — chain composably
model("User").active().recent().findAll();
model("User").byRole("admin").findAll(page=1, perPage=25);

// Enums — auto-generated checkers and scopes
user.isDraft();                    // true/false
model("User").draft().findAll();

// Chainable query builder (2-/3-arg where is injection-safe; 1-arg is raw SQL)
model("User")
    .where("status", "active")
    .where("age", ">", 18)
    .whereNotNull("emailVerifiedAt")
    .orderBy("name", "ASC")
    .limit(25)
    .get();
// Methods: where, orWhere, whereNull, whereNotNull, whereBetween, whereIn, whereNotIn, orderBy,
// limit, offset, select, include, group, distinct, forUpdate, get
// Any of these (not just where) can START the chain on the model, e.g. model("User").select("id,name").get()

// Batch processing — memory-efficient
model("User").findEach(batchSize=1000, callback=function(user) {
    user.sendReminderEmail();
});
model("User").findInBatches(batchSize=500, callback=function(users) {
    processUserBatch(users);
});
```

## Routing Quick Reference

```cfm
mapper()
    .resources("users")
    .resources("products", except="delete")
    .resources(name="posts", callback=function(map) {
        map.resources("comments");
    })
    .get(name="login", to="sessions##new")
    .post(name="authenticate", to="sessions##create")
    .root(to="home##index", method="get")
    .wildcard()                                       // keep last!
.end();
```

Helpers: `linkTo(route="user", key=user.id)`, `urlFor(route="users")`, `redirectTo(route="user", key=user.id)`, `startFormTag(route="user", method="put", key=user.id)`.

`params.controller` / `params.action` come from the matched route. Query string, form, and JSON body cannot retarget them. Wildcard `[controller]` / `[action]` still take those names from the path. `form._method` is honored only on POST and only for `PUT` / `PATCH` / `DELETE`. A before filter that returns `false` skips the action (same as `redirectTo()` / `renderText()`). Filter `type` is case-insensitive. `caches(appendToKey=)` throws `Wheels.KeyNotFound` if a listed path is missing. `X-Rewrite-URL` / `X-Original-URL` follow `set(trustProxyHeaders=true)` like `X-Forwarded-*`.

### Route Model Binding

Resolves `params.key` into a model instance before the action runs. Lands in `params.<singularModelName>`. Throws `Wheels.RecordNotFound` (404) if missing; silently skips if the model class doesn't exist.

```cfm
.resources(name="users", binding=true)                // params.user
.resources(name="posts", binding="BlogPost")          // params.blogPost
.resources(name="posts", binding=true, bindBy="slug") // params.post via findOneBySlug(value=key)
.scope(path="/api", binding=true, callback=function(map) {  // all nested resources bound
    map.resources("users");
})
set(routeModelBinding=true);                          // global, in config/settings.cfm
```

`bindBy="slug"` resolves the `:key` segment through the parameterized dynamic finder (`findOneBySlug(value=key)`) instead of `findByKey()`, so URLs can carry slugs or usernames rather than primary keys. It's ignored unless binding is enabled.

## Pagination View Helpers

Requires a paginated query: `findAll(page=params.page, perPage=25)`. Recommended all-in-one helper: `paginationNav()`.

```cfm
// All-in-one nav
#paginationNav()#
#paginationNav(showInfo=true, showFirst="never", showLast="never", navClass="my-pagination")#
#paginationNav(windowSize=3)#

// Declarative presets — Bootstrap 4/5 and Tailwind
#paginationNav(viewStyle="bootstrap5")#
#paginationNav(viewStyle="bootstrap4")#
#paginationNav(viewStyle="tailwind")#

// Manual composition (like-for-like swap for legacy paginationLinks)
#paginationNav(
    navClass="",
    prepend='<ul class="pagination">',
    append="</ul>",
    prependToPage='<li class="page-item">',
    appendToPage="</li>",
    class="page-link",
    classForCurrent="active",
    addActiveClassToPrependedParent=true
)#

// Individual helpers
#paginationInfo()#       #firstPageLink()#       #previousPageLink()#
#pageNumberLinks()#      #nextPageLink()#        #lastPageLink()#
```

`showFirst` / `showLast` / `showPrevious` / `showNext` accept `"auto"` (default), `"always"`, or `"never"`. Under `"auto"` the first/last anchors are hidden when the window already reaches the boundary; previous/next render disabled `<span>` at boundaries to preserve position. Booleans coerce (`true`→`"always"`, `false`→`"never"`).

`viewStyle` accepts `"plain"` (default), `"bootstrap5"`, `"bootstrap4"`, `"tailwind"`. Bootstrap presets emit `<li class="page-item active" aria-current="page"><span class="page-link">N</span></li>`. Non-plain presets ignore manual-composition args.

In development, `paginationNav()` throws `Wheels.PaginationNav.InvalidArgument` for unknown sub-helper args. `windowSize` is consumed by `paginationNav` itself (not forwarded). Accepted pass-through: `format, text, name, class, disabledClass, showDisabled, pageNumberAsParam, classForCurrent, linkToCurrentPage, prependToPage, appendToPage, addActiveClassToPrependedParent, route, controller, action, key, anchor, onlyPath, host, protocol, port, params`. Named route segment variables are auto-exempted from the check.

## Middleware Quick Reference

Middleware runs at the dispatch level, before controller instantiation. Each implements `handle(request, next)`.

```cfm
// config/settings.cfm — global middleware
set(middleware = [
    new wheels.middleware.RequestId(),
    new wheels.middleware.SecurityHeaders(),
    new wheels.middleware.Cors(allowOrigins="https://myapp.com")
]);

// config/routes.cfm — route-scoped
mapper()
    .scope(path="/api", middleware=["app.middleware.ApiAuth"], callback=function(map) {
        map.resources("users");
    })
.end();
```

Built-in: `wheels.middleware.RequestId`, `wheels.middleware.Cors`, `wheels.middleware.SecurityHeaders`, `wheels.middleware.RateLimiter`, `wheels.middleware.AuthMiddleware` (authenticate + attach the result; `genericErrors=true` emits a generic `Unauthorized` JSON body instead of `authResult.error`), `wheels.middleware.TenantResolver` (resolve the active tenant; `failClosed=true` 403s unmatched tenants instead of proceeding on the default datasource). Custom: implement `wheels.middleware.MiddlewareInterface`, place in `app/middleware/`.

**Singleton lifecycle contract**: both global and route-scoped middleware (including string-path entries) are resolved once and cached for the application lifetime. The same instance handles every matching request — stateful middleware (e.g. in-memory `RateLimiter` on a `.scope()`) accumulates state across requests as intended. Implication: every middleware component must be safe to share across concurrent requests (use CFML locks for any mutable state).

### Rate Limiting

```cfm
new wheels.middleware.RateLimiter()                                            // fixed window, 60 req / 60s
new wheels.middleware.RateLimiter(maxRequests=100, windowSeconds=120, strategy="slidingWindow")
new wheels.middleware.RateLimiter(maxRequests=50, windowSeconds=60, strategy="tokenBucket")
new wheels.middleware.RateLimiter(storage="database")                          // auto-creates wheels_rate_limits
// rate-limit per API key — hoist the closure first: an inline function literal
// as a constructor named arg crashes Adobe CF (Cross-Engine Invariant 5)
var apiKeyFn = function(req) {
    var apiKey = req.cgi.http_x_api_key ?: "";
    return Len(apiKey) ? apiKey : "anonymous";
};
new wheels.middleware.RateLimiter(keyFunction=apiKeyFn)
```

The `keyFunction` receives the dispatch middleware context `{params, route, pathInfo, method, cgi}`. The `cgi` member is the sanitized `request.cgi` copy overlaid on every inbound HTTP header under its CGI-style `http_*` name (built by `Dispatch.$buildMiddlewareCgiScope()`), so arbitrary headers like `X-Api-Key` resolve per client ([#3074](https://github.com/wheels-dev/wheels/issues/3074) — before 4.0.4 the context had **no `cgi` key** and `req.cgi.*` silently collapsed every client into one bucket). Keep the `Len()` guard: an empty-valued header reads as empty string, and on pre-fix versions a missing header does too.

Strategies: `fixedWindow` (default), `slidingWindow`, `tokenBucket`. Storage: `memory` or `database`. Emits `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`. Returns `429` with `Retry-After` when exceeded.

`windowSeconds` must be > 0; `maxRequests` must be >= 0. Invalid values throw `Wheels.RateLimiter.InvalidConfiguration` at construction. `maxRequests = 0` is a valid kill-switch.

## DI Container Quick Reference

Register services in `config/services.cfm` (loaded at app start; environment overrides supported):

```cfm
local.di = injector();
local.di.map("emailService").to("app.lib.EmailService").asSingleton();
local.di.map("currentUser").to("app.lib.CurrentUserResolver").asRequestScoped();
local.di.bind("INotifier").to("app.lib.SlackNotifier").asSingleton();
```

Resolve with `service("emailService")` anywhere, or `inject("emailService, currentUser")` in controller `config()`. Scopes: transient (default), `.asSingleton()`, `.asRequestScoped()`. Auto-wiring: `init()` params matching registered names are auto-resolved when no `initArguments` passed.

Construction that needs logic uses `.toFactory()` — bind a name to a closure that builds the instance (receives the `Injector`) and honors the chained lifecycle flag:

```cfm
local.di.map("jwtStrategy").toFactory(function(container) {
    return new wheels.auth.JwtStrategy(jwtService = new wheels.auth.JwtService(secretKey = env("JWT_SECRET")));
}).asSingleton();
// service("jwtStrategy") returns the factory's result — no .build() indirection
```

## Authentication & Authorization

One-command scaffold (4.0.6+): `wheels generate auth` emits a `User` model (PBKDF2 hashing via the `passwordHasher` service), `Sessions`/`Passwords`/`Registrations` controllers + views, a create-users migration, and wiring. Flags: `--model=<Name>` (default `User`), `--strategy=session|token|jwt`, `--registration`/`--no-registration`, `--force`.

Built-in strategies under `wheels.auth.*`: `Authenticator` (registry that tries strategies in order), `SessionStrategy`, `TokenStrategy`, `JwtStrategy`. Wire by hand in `config/services.cfm`, or collapse session wiring to one line:

```cfm
// config/services.cfm — registers + wires SessionStrategy (idempotent)
enableSession(sessionKey = "wheels.auth");
```

Password hashing: `wheels.auth.PasswordHasher` (PBKDF2-SHA256, 600k iterations; `hash()` / `verify()` / `needsRehash()`), and global pure-CFML bcrypt helpers (OpenBSD/jBCrypt-compatible):

```cfm
hash = bcryptHash(plaintext);                // cost defaults to 10
ok = bcryptVerify(plaintext, hash);          // constant-time
if (bcryptNeedsRehash(hash)) { /* rehash + save */ }
```

Authorization policies (4.0.6+): `wheels.Policy` base class + `app/policies/<Model>Policy.cfc`, generated with `wheels generate policy <Model>`. Helpers: `authorize(model)` (throws `Wheels.NotAuthorized` → 403 on deny, returns the record on allow), `can("action", model)` (boolean), `policyScope(model("Post"))` (no-rows scope on deny). Default-deny: every action denies unless the policy defines it.

## Storage

Named disks behind one interface — `put` / `get` / `exists` / `delete` / `url` / `signedUrl` — resolved through `wheels.storage.StorageManager`. Drivers: `local` (filesystem + URL prefix) and `s3` (from-scratch SigV4 over `cfhttp`, no AWS SDK).

```cfm
// config/settings.cfm
set(storage = {
    default = "local",
    disks = {
        local = { driver="local", root=ExpandPath("../storage/uploads"), urlPrefix="/uploads", signingKey=env("STORAGE_SIGNING_KEY") },
        s3 = { driver="s3", bucket="my-bucket", region="us-east-1", accessKeyId=env("S3_KEY"), secretAccessKey=env("S3_SECRET") }
    }
});

// config/services.cfm
local.di.map("storage").toFactory(function() {
    return new wheels.storage.StorageManager(config = get("storage"));
});
```

```cfm
service("storage").disk().put("avatars/42.png", bytes, contentType="image/png", visibility="public");
bytes = service("storage").disk().get("avatars/42.png");
url = service("storage").disk("s3").signedUrl(key="reports/q3.pdf", expiresIn=900);
```

`disk()` returns the default disk; `disk("name")` a named one. `get()` returns binary; `put()` round-trips bytes exactly. Errors: `Wheels.Storage.NotFound`, `.UnknownDisk`, `.UnknownDriver`, `.InvalidKey`, `.InvalidExpiresIn` (`expiresIn` must be `1..604800`), `.MissingSigningKey` (local `signedUrl()` without a `signingKey`).

## Package System

Optional first-party modules distributed as standalone repos and installed into `vendor/<name>/`. Auto-discovered from `vendor/*/package.json` on startup via `PackageLoader.cfc` with per-package error isolation.

```
vendor/                # Runtime: framework core + installed packages
  wheels/              #   Framework core (excluded from package discovery)
  wheels-sentry/       #   Installed package
plugins/               # DEPRECATED: legacy plugins still work with warning
```

First-party packages live in standalone repos under `wheels-dev/`, indexed by `wheels-dev/wheels-packages`:
- `wheels-sentry` — error tracking
- `wheels-hotwire` — Turbo/Stimulus
- `wheels-basecoat` — UI components
- `wheels-legacy-adapter` — 3.x → 4.x compatibility shims
- `wheels-i18n` — internationalization
- `wheels-seo-suite` — SEO tooling

### package.json Manifest

```json
{
    "name": "wheels-sentry",
    "version": "1.0.0",
    "wheelsVersion": ">=3.0",
    "mappings": {"plugins.sentry": "."},
    "provides": {"mixins": "controller", "services": [], "middleware": []},
    "requires": {}, "replaces": {}, "suggests": {}
}
```

- **`mapping`** (singular): CFML-identifier-safe alias registered as a CFML mapping. Defaults to lower-camel-case of `name`. Lets package CFCs use `new wheelsSentry.SentryClient()`.
- **`mappings`** (plural): struct of dotted aliases beyond the singular. Use for legacy compatibility paths (e.g., `plugins.sentry` keeps old call sites resolving). See [#2705](https://github.com/wheels-dev/wheels/pull/2705).
- **`provides.mixins`**: comma-delimited from `application,dispatch,controller,mapper,model,base,sqlserver,mysql,postgresql,h2,test`, plus `global` or `none`. Default `none`. View helpers belong in `controller` mixins (views execute in controller's `variables` scope).
- **`requires` / `replaces` / `suggests`**: package name → semver constraint. Loader uses these, NOT legacy `dependencies`.

### CLI

```bash
wheels packages list                  # browse registry
wheels packages search <query>
wheels packages show <name>
wheels packages add <name>            # latest compat version (canonical verb)
wheels packages add <name>@<ver>      # pin
wheels packages add <name> --force    # overwrite existing
wheels packages update <name> --yes
wheels packages update --all --yes
wheels packages remove <name>
wheels packages registry info         # registry source + cache age
wheels packages registry refresh      # bust 24h cache
```

Override registry with `WHEELS_PACKAGES_REGISTRY=<org>/<repo>` (default `wheels-dev/wheels-packages`). Restart or `wheels reload` after install. Each package loads in its own try/catch — a broken one is logged and skipped.

## Migrations & Seeding

### Shared Dev DB Reconciliation

`wheels_migrator_versions` can drift from on-disk files when several developers share a single dev database (peer applied a migration whose file isn't yet in your branch). Detected and surfaced automatically; reconciliation is explicit:

- `wheels migrate latest` — when a peer's tracked version sits above your latest local file, it now applies pending local migrations with a warning instead of silently no-op'ing on a "down" branch.
- `wheels migrate info` — orphan rows render as `[?] <version> <name> (applied <timestamp>)` when the enriched `wheels_migrator_versions.name` / `.applied_at` columns are populated, or `[?] <version> ********** NO FILE **********` (Rails-style) for legacy rows.
- `wheels migrate doctor` — single-command health report. Lists orphans + pending; pure read.
- `wheels migrate forget <version> --yes` — delete a stale tracking row (refuses if a matching local file exists, refuses if version not in table).
- `wheels migrate pretend <version> --yes` — record a version as applied without running `up()` (refuses if already applied or no matching file).

Tracking-table schema: `wheels_migrator_versions(version, core_level, name, applied_at)`. The `name` and `applied_at` columns are additive (NULL for legacy rows) and added automatically via `$ensureTrackingColumns()` on first migrator call after upgrade. Both columns are populated by `$setVersionAsMigrated(version, migrationName)` going forward; existing rows stay NULL and display version-only.

Both `forget` and `pretend` are dry-run by default; `--yes` is required to mutate. Helpers live on `Migrator.cfc`: `$getOrphanVersions()`, `$getOrphanVersionsWithMeta()`, `doctor()`, `forgetVersion()`, `pretendVersion()`, `$buildInfoOutput()`, `$ensureTrackingColumns()`. Deep reference: [.ai/wheels/troubleshooting/shared-dev-databases.md](.ai/wheels/troubleshooting/shared-dev-databases.md). User-facing guide: `web/sites/guides/src/content/docs/v4-0-0/basics/shared-development-databases.mdx`. Shipped across #2798, #2799, and the schema enrichment PR.

### Auto-Migration

Generate migrations from model/DB schema diffs. Rename detection via explicit hints (authoritative) + heuristic suggestions (normalized-token + Levenshtein).

```cfm
var am = CreateObject("component", "wheels.migrator.AutoMigrator");
var d = am.diff("User");
var d = am.diff("User", {renames: {"full_name": "fullName"}});
var d = am.diff("User", {heuristicThreshold: 0.85});
var all = am.diffAll({hints: {"User": {renames: {"full_name": "fullName"}}}, heuristicThreshold: 0.7});
am.writeMigration(d, "rename_name_field");
```

A CLI wrapper exists too: `wheels migrate diff` (alias `dbmigrate diff`) previews the same AutoMigrator diffs and, with `--write`, emits migration files. `--rename OLD:NEW` (repeatable; `Model.OLD:NEW` when diffing all models) supplies rename hints, `--hints` takes JSON, `--model` limits the diff to one model, and `--name` names the written migration.

Result struct: `{modelName, tableName, addColumns, removeColumns, changeColumns, renameColumns, suggestedRenames}`. Limits: PK renames not detected; rename + type change requires separate migrations; calculated properties excluded. `writeMigration()` / `generateMigrationCFC()` honor `suggestedRenames` as `renameColumn` instead of destructive remove+add.

Announce-only `up()`/`down()` (the default "NOT IMPLEMENTED" stubs and the announce template) do not write `wheels_migrator_versions`. `announce()` plus ORM persist (`model().create()` / `save()` / `delete()` with no `$execute`) still marks or unmarks the version. `redoMigration()` fails closed when `allowMigrationDown` is false — the framework default stays `false` (development still opts in to `true`). Default FK names are `FK_<table>_<refTable>_<column>` so two FKs to the same reference table do not collide.

### Seeding

Convention-based, idempotent, CLI-supported.

```cfm
// app/db/seeds.cfm — shared (all environments)
seedOnce(modelName="Role", uniqueProperties="name", properties={
    name: "admin", description: "Administrator"
});

// app/db/seeds/development.cfm — dev-only (runs after seeds.cfm)
seedOnce(modelName="User", uniqueProperties="email", properties={
    firstName: "Dev", lastName: "User", email: "dev@example.com"
});
```

```bash
wheels seed                            # auto-detect env (canonical)
wheels seed --environment=production
wheels seed --generate                 # legacy: random test data
```

To scaffold seed templates, use: `wheels generate snippets seed-data` (writes `app/snippets/seeds*.cfm` — copy or move to `app/db/` to activate them). There is no `wheels generate seed` generator.

`seedOnce()`: idempotent — checks `uniqueProperties` via `findOne()`, creates only if not found. Execution: `seeds.cfm` → `seeds/<environment>.cfm`, wrapped in a transaction. Programmatic: `application.wheels.seeder.runSeeds()`. (Note: `wheels db:seed` is NOT a valid command — it errors. Use `wheels seed`.)

## Background Jobs Quick Reference

```cfm
// app/jobs/SendWelcomeEmailJob.cfc
component extends="wheels.Job" {
    function config() {
        super.config();
        this.queue = "mailers";
        this.maxRetries = 5;
    }
    public void function perform(struct data = {}) {
        sendEmail(to=data.email, subject="Welcome!", from="app@example.com");
    }
}

// Enqueue
job = new app.jobs.SendWelcomeEmailJob();
job.enqueue(data={email: user.email});
job.enqueueIn(seconds=300, data={email: "..."});
job.enqueueAt(runAt=scheduledDate, data={});

// Process
result = (new wheels.Job()).processQueue(queue="mailers", limit=10);
stats = (new wheels.Job()).queueStats();
```

Worker CLI (`cli/lucli/Module.cfc::jobs()` — thin wrapper over the `jobsProcessNext`/`jobsStatus` bridge commands in `vendor/wheels/public/views/cli.cfm`; requires a running server):
```bash
wheels jobs work --queue=mailers --interval=3   # long-lived worker loop; --max-jobs=N for one-shot batches, --quiet
wheels jobs status [--queue=mailers] [--format=json]
```
The `retry`/`purge`/`monitor` verbs are tracked follow-ups ([#3090](https://github.com/wheels-dev/wheels/issues/3090)) — invoking one errors with the programmatic equivalent (`(new wheels.Job()).retryFailed()` / `.purgeCompleted()`).

Backoff: `this.baseDelay = 2`, `this.maxDelay = 3600` in `config()`. Formula: `Min(baseDelay * 2^attempt, maxDelay)`. The `wheels_jobs` table is auto-created on first enqueue/processing — no migration needed.

## Server-Sent Events (SSE)

```cfm
function notifications() {
    var data = model("Notification").findAll(where="userId=#params.userId#");
    renderSSE(data=SerializeJSON(data), event="notifications", id=params.lastId);
}

function stream() {
    var writer = initSSEStream();
    for (var item in items) sendSSEEvent(writer=writer, data=SerializeJSON(item), event="update");
    closeSSEStream(writer=writer);
}

if (isSSERequest()) { renderSSE(data="..."); }
```

Client: `const es = new EventSource('/controller/notifications');`

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

- **App tests**: `/wheels/app/tests` — project-specific, in `tests/specs/`. Uses `tests/populate.cfm` and `tests/TestRunner.cfc`.
- **Core tests**: `/wheels/core/tests` — framework, in `vendor/wheels/tests/specs/`. Uses `vendor/wheels/tests/populate.cfm`. **This is what CI runs across all engines × DBs.**

**Isolated test application (#3374):** `Application.cfc` includes `vendor/wheels/events/testcontext.cfm` after `config/app.cfm` so runner URLs (and TestClient/browser requests that send `X-Wheels-Test-Context`) bind `<this.name>_wheelsTest` — a separate CFML application scope. The live `application.wheels` is not swapped. `$testClient(testContext=false)` addresses the live app. A request-scoped overlay cannot replace this (blockers B1–B9 on #3025). Existing apps without the include still use the #3373 named-lock swap on the live scope.

**Critical**: core tests use `directory="wheels.tests.specs"` which compiles EVERY CFC in the directory. One compilation error in any spec file crashes the entire suite for that engine. The "inline closure as constructor named arg" anti-pattern (#5 in Cross-Engine Invariants) is the classic example.

### Test-specific gotchas

- **Test infra scope**: Wheels internals (`$dbinfo`, `model()`, etc.) aren't available as bare calls in `.cfm` files included from plain CFCs like `TestRunner.cfc`. Use `application.wo.model()` or native CFML tags (`cfdbinfo`).
- **`#` escape**: HTML entities like `&#111;` contain `#` which CFML interprets as expression delimiter. In string literals, escape: `&##111;`. Comments (`//`) are fine. Unescaped `#` in strings crashes the **entire** test suite, not just that file.
- **`$clearRoutes()` in test specs**: NOT inherited from `wheels.WheelsTest`. Copy from `linksSpec.cfc` if your spec manipulates routes.

### Running tests locally

```bash
wheels test                      # run the app's tests/specs/ (TestBox)
wheels test tests/specs/models   # a subdirectory of specs
```

The CLI boots the app on an isolated port and runs the suite over HTTP,
mirroring CI. Browser-driven specs need Playwright installed once:
`wheels browser setup`.

## Where to go deeper

- Human guides: https://guides.wheels.dev (start-here, core-concepts, testing, deployment)
- Framework API reference: `/wheels/ai` endpoints on any running app
  — JSON docs optimized for AI consumption.
- MCP: add `wheels` to `.mcp.json` (`{"mcpServers":{"wheels":{"command":"wheels","args":["mcp","wheels"]}}}`)
  and prefer `mcp__wheels__*` tools over CLI commands.

