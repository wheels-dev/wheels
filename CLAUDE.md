# Wheels Framework

CFML MVC framework with ActiveRecord ORM. Models in `app/models/`, controllers in `app/controllers/`, views in `app/views/`, migrations in `app/migrator/migrations/`, config in `config/`, tests in `tests/`.

## Directory Layout

```
app/controllers/    app/models/    app/views/    app/views/layout.cfm
app/migrator/migrations/    app/db/seeds.cfm    app/db/seeds/
app/events/    app/global/    app/lib/
app/mailers/    app/jobs/    app/plugins/    app/snippets/
config/settings.cfm    config/routes.cfm    config/environment.cfm
packages/    plugins/    public/    tests/    vendor/    .env (never commit)
```

## Development Tools

Prefer MCP tools when the Wheels MCP server is available (`mcp__wheels__*`). Fall back to CLI otherwise.

| Task | MCP | CLI |
|------|-----|-----|
| Generate | `wheels_generate(type, name, attributes)` | `wheels g model/controller/scaffold Name attrs` |
| Migrate | `wheels_migrate(action="latest\|up\|down\|info")` | `wheels dbmigrate latest\|up\|down\|info` |
| Test | `wheels_test()` | `wheels test run` |
| Reload | `wheels_reload()` | `?reload=true&password=...` |
| Server | `wheels_server(action="status")` | `wheels server start\|stop\|status` |
| Analyze | `wheels_analyze(target="all")` | — |
| Admin | — | `wheels g admin ModelName` |
| Seed | — | `wheels db:seed` |

## Critical Anti-Patterns (Top 10)

These are the most common mistakes when generating Wheels code. Check every time.

### 1. Mixed Argument Styles
Wheels functions cannot mix positional and named arguments. This is the #1 error source.
```cfm
// WRONG — mixed positional + named
hasMany("comments", dependent="delete");
validatesPresenceOf("name", message="Required");

// RIGHT — all named when using options
hasMany(name="comments", dependent="delete");
validatesPresenceOf(properties="name", message="Required");

// RIGHT — positional only (no options)
hasMany("comments");
validatesPresenceOf("name");
```

### 2. Query vs Array Confusion in Views
Model finders return query objects, not arrays. Loop accordingly.
```cfm
// WRONG
<cfloop array="#users#" index="user">

// RIGHT
<cfloop query="users">
    #users.firstName#
</cfloop>
```

### 3. Nested Resource Routes — Use Callback Syntax
Wheels supports nested resources via the `callback` parameter or `nested=true` with manual `end()`. Do NOT use Rails-style inline function blocks.
```cfm
// WRONG — Rails-style inline (not supported)
.resources("posts", function(r) { r.resources("comments"); })

// RIGHT — callback syntax (recommended)
.resources(name="posts", callback=function(map) {
    map.resources("comments");
})

// RIGHT — manual nested=true + end()
.resources(name="posts", nested=true)
    .resources("comments")
.end()

// RIGHT — flat separate declarations (no URL nesting)
.resources("posts")
.resources("comments")
```

### 4. HTML5 Form Helpers Available
Wheels provides dedicated HTML5 input helpers. Use them instead of manual type attributes.
```cfm
// Object-bound helpers
#emailField(objectName="user", property="email")#
#urlField(objectName="user", property="website")#
#numberField(objectName="product", property="quantity", min="1", max="100")#
#telField(objectName="user", property="phone")#
#dateField(objectName="event", property="startDate")#
#colorField(objectName="theme", property="primaryColor")#
#rangeField(objectName="settings", property="volume", min="0", max="100")#
#searchField(objectName="search", property="query")#

// Tag-based helpers
#emailFieldTag(name="email", value="")#
#numberFieldTag(name="qty", value="1", min="0", step="1")#
```

### 5. Migration Seed Data — Use Direct SQL
Parameter binding in `execute()` is unreliable. Use inline SQL for seed data.
```cfm
// WRONG
execute(sql="INSERT INTO roles (name) VALUES (?)", parameters=[{value="admin"}]);

// RIGHT
execute("INSERT INTO roles (name, createdAt, updatedAt) VALUES ('admin', NOW(), NOW())");
```

### 6. Route Order Matters
Routes are matched first-to-last. Wrong order = wrong matches.
```
Order: MCP routes → resources → custom named routes → root → wildcard (last!)
```

### 7. timestamps() Includes createdAt and updatedAt
Don't also add separate datetime columns for these.
```cfm
// WRONG — duplicates
t.timestamps();
t.datetime(columnNames="createdAt");

// RIGHT
t.timestamps();  // creates both createdAt and updatedAt
```

### 8. Database-Agnostic Dates in Migrations
Use `NOW()` — it works across MySQL, PostgreSQL, SQL Server, H2, SQLite.
```cfm
// WRONG — database-specific
execute("INSERT INTO users (name, createdAt) VALUES ('Admin', CURRENT_TIMESTAMP)");

// RIGHT
execute("INSERT INTO users (name, createdAt, updatedAt) VALUES ('Admin', NOW(), NOW())");
```

### 9. Controller Filters Must Be Private
Filter functions (authentication, data loading) must be declared `private`.
```cfm
// WRONG — public filter becomes a routable action
function authenticate() { ... }

// RIGHT
private function authenticate() { ... }
```

### 10. Always cfparam View Variables
Every variable passed from controller to view needs a cfparam declaration.
```cfm
// At top of every view file
<cfparam name="users" default="">
<cfparam name="user" default="">
```

## Wheels Conventions

- **config()**: All model associations/validations/callbacks and controller filters/verifies go in `config()`
- **Naming**: Models are singular PascalCase (`User.cfc`), controllers are plural PascalCase (`Users.cfc`), table names are plural lowercase (`users`)
- **Parameters**: `params.key` for URL key, `params.user` for form struct, `params.user.firstName` for nested
- **extends**: Models extend `"Model"`, controllers extend `"Controller"`, tests extend `"wheels.WheelsTest"` (legacy: `"wheels.Test"` for RocketUnit)
- **Associations**: All named params when using options: `hasMany(name="orders")`, `belongsTo(name="user")`, `hasOne(name="profile")`
- **Validations**: Property param is `property` (singular) for single, `properties` (plural) for list: `validatesPresenceOf(properties="name,email")`

## Model Quick Reference

```cfm
component extends="Model" {
    function config() {
        // Table/key (only if non-conventional)
        tableName("tbl_users");
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

        // Query scopes — reusable, composable query fragments
        scope(name="active", where="status = 'active'");
        scope(name="recent", order="createdAt DESC");
        scope(name="byRole", handler="scopeByRole");  // dynamic scope

        // Enums — named values with auto-generated checkers and scopes
        enum(property="status", values="draft,published,archived");
        enum(property="priority", values={low: 0, medium: 1, high: 2});
    }

    // Dynamic scope handler (must return struct with query keys)
    private struct function scopeByRole(required string role) {
        return {where: "role = '#arguments.role#'"};
    }
}
```

Finders: `model("User").findAll()`, `model("User").findOne(where="...")`, `model("User").findByKey(params.key)`.
Create: `model("User").new(params.user)` then `.save()`, or `model("User").create(params.user)`.
Include associations: `findAll(include="role,orders")`. Pagination: `findAll(page=params.page, perPage=25)`.

### Scopes (Composable Query Fragments)
```cfm
// Chain scopes together — each adds to the query
model("User").active().recent().findAll();
model("User").byRole("admin").findAll(page=1, perPage=25);
model("User").active().recent().count();
```

### Chainable Query Builder (Injection-Safe)
```cfm
// Fluent alternative to raw WHERE strings — values are auto-quoted
model("User")
    .where("status", "active")
    .where("age", ">", 18)
    .whereNotNull("emailVerifiedAt")
    .orderBy("name", "ASC")
    .limit(25)
    .get();

// Combine with scopes
model("User").active().where("role", "admin").get();

// Other builder methods: orWhere, whereNull, whereBetween, whereIn, whereNotIn
```

### Enums (Named Property Values)
```cfm
// Auto-generated boolean checkers
user.isDraft();       // true/false
user.isPublished();   // true/false

// Auto-generated scopes per value
model("User").draft().findAll();
model("User").published().findAll();
```

### Batch Processing (Memory-Efficient)
```cfm
// Process one record at a time (loads in batches internally)
model("User").findEach(batchSize=1000, callback=function(user) {
    user.sendReminderEmail();
});

// Process in batch groups (callback receives query/array)
model("User").findInBatches(batchSize=500, callback=function(users) {
    processUserBatch(users);
});

// Works with scopes and conditions
model("User").active().findEach(batchSize=500, callback=function(user) { /* ... */ });
```

## Middleware Quick Reference

Middleware runs at the dispatch level, before controller instantiation. Each implements `handle(request, next)`.

```cfm
// config/settings.cfm — global middleware (runs on every request)
set(middleware = [
    new wheels.middleware.RequestId(),
    new wheels.middleware.SecurityHeaders(),
    new wheels.middleware.Cors(allowOrigins="https://myapp.com")
]);
```

```cfm
// config/routes.cfm — route-scoped middleware
mapper()
    .scope(path="/api", middleware=["app.middleware.ApiAuth"])
        .resources("users")
    .end()
.end();
```

Built-in: `wheels.middleware.RequestId`, `wheels.middleware.Cors`, `wheels.middleware.SecurityHeaders`, `wheels.middleware.RateLimiter`. Custom middleware: implement `wheels.middleware.MiddlewareInterface`, place in `app/middleware/`.

## DI Container Quick Reference

Register services in `config/services.cfm` (loaded at app start, environment overrides supported):

```cfm
var di = injector();
di.map("emailService").to("app.lib.EmailService").asSingleton();
di.map("currentUser").to("app.lib.CurrentUserResolver").asRequestScoped();
di.bind("INotifier").to("app.lib.SlackNotifier").asSingleton();
```

Resolve with `service()` anywhere, or use `inject()` in controller `config()`:

```cfm
// In any controller/view
var svc = service("emailService");

// Declarative injection in controller config()
function config() {
    inject("emailService, currentUser");
}
function create() {
    this.emailService.send(to=user.email);  // resolved per-request
}
```

Scopes: transient (default, new each call), `.asSingleton()` (app lifetime), `.asRequestScoped()` (per-request via `request.$wheelsDICache`). Auto-wiring: `init()` params matching registered names are auto-resolved when no `initArguments` passed. `bind()` = semantic alias for `map()`.
### Rate Limiting

```cfm
// Fixed window (default) — 60 requests per 60 seconds
new wheels.middleware.RateLimiter()

// Sliding window — smoother enforcement
new wheels.middleware.RateLimiter(maxRequests=100, windowSeconds=120, strategy="slidingWindow")

// Token bucket — allows bursts up to capacity, refills steadily
new wheels.middleware.RateLimiter(maxRequests=50, windowSeconds=60, strategy="tokenBucket")

// Database-backed storage (auto-creates wheels_rate_limits table)
new wheels.middleware.RateLimiter(storage="database")

// Custom key function (rate limit per API key instead of IP)
new wheels.middleware.RateLimiter(keyFunction=function(req) {
    return req.cgi.http_x_api_key ?: "anonymous";
})
```

Strategies: `fixedWindow` (default), `slidingWindow`, `tokenBucket`. Storage: `memory` (default) or `database`. Adds `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset` headers. Returns `429 Too Many Requests` with `Retry-After` when limit exceeded.

## Package System

Optional first-party modules ship in `packages/` and are activated by copying to `vendor/`. The framework auto-discovers `vendor/*/package.json` on startup via `PackageLoader.cfc` with per-package error isolation.

```
packages/              # Source/staging (NOT auto-loaded)
  sentry/              #   wheels-sentry — error tracking
  hotwire/             #   wheels-hotwire — Turbo/Stimulus
  basecoat/            #   wheels-basecoat — UI components
vendor/                # Runtime: framework core + activated packages
  wheels/              #   Framework core (excluded from package discovery)
  sentry/              #   Activated package (copied from packages/)
plugins/               # DEPRECATED: legacy plugins still work with warning
```

### package.json Manifest

```json
{
    "name": "wheels-sentry",
    "version": "1.0.0",
    "author": "PAI Industries",
    "description": "Sentry error tracking",
    "wheelsVersion": ">=3.0",
    "provides": {
        "mixins": "controller",
        "services": [],
        "middleware": []
    },
    "dependencies": {}
}
```

**`provides.mixins`**: Comma-delimited targets — `controller`, `view`, `model`, `global`, `none`. Determines which framework components receive the package's public methods. Default: `none` (explicit opt-in, unlike legacy plugins which default to `global`).

### Activating a Package

```bash
cp -r packages/sentry vendor/sentry    # activate
rm -rf vendor/sentry                    # deactivate
```

Restart or reload the app after activation. Symlinks also work: `ln -s ../../packages/sentry vendor/sentry`.

### Error Isolation

Each package loads in its own try/catch. A broken package is logged and skipped — the app and other packages continue normally.

### Testing Packages

```bash
# Run a specific package's tests (package must be in vendor/)
curl "http://localhost:60007/wheels/core/tests?db=sqlite&format=json&directory=vendor.sentry.tests"
```

## Routing Quick Reference

```cfm
// config/routes.cfm
mapper()
    .resources("users")                              // standard CRUD
    .resources("products", except="delete")           // skip actions
    .resources(name="posts", callback=function(map) { // nested resources
        map.resources("comments");
        map.resources("tags");
    })
    .get(name="login", to="sessions##new")           // named route
    .post(name="authenticate", to="sessions##create")
    .root(to="home##index", method="get")            // homepage
    .wildcard()                                       // keep last!
.end();
```

Helpers: `linkTo(route="user", key=user.id, text="View")`, `urlFor(route="users")`, `redirectTo(route="user", key=user.id)`, `startFormTag(route="user", method="put", key=user.id)`.

### Route Model Binding

Automatically resolves `params.key` into a model instance before the controller action runs. The instance lands in `params.<singularModelName>` (e.g., `params.user`). Throws `Wheels.RecordNotFound` (404) if the record doesn't exist; silently skips if the model class doesn't exist.

```cfm
// Per-resource — convention: singularize controller name → model
.resources(name="users", binding=true)

// Explicit model name override
.resources(name="posts", binding="BlogPost")  // resolves BlogPost, stored in params.blogPost

// Scope-level — all nested resources inherit binding
.scope(path="/api", binding=true)
    .resources("users")     // params.user
    .resources("products")  // params.product
.end()

// Global — enable for all resource routes
set(routeModelBinding=true);  // in config/settings.cfm
```

In the controller, use the resolved instance directly:
```cfm
function show() {
    user = params.user;  // already a model object, no findByKey needed
}
```

## Pagination View Helpers

Requires a paginated query: `findAll(page=params.page, perPage=25)`. The recommended all-in-one helper is `paginationNav()`.

```cfm
// All-in-one nav (wraps first/prev/page-numbers/next/last in <nav>)
#paginationNav()#
#paginationNav(showInfo=true, showFirst=false, showLast=false, navClass="my-pagination")#

// Individual helpers for custom layouts
#paginationInfo()#            // "Showing 26-50 of 1,000 records"
#firstPageLink()#             // link to page 1
#previousPageLink()#          // link to previous page
#pageNumberLinks()#           // windowed page number links (default windowSize=2)
#nextPageLink()#              // link to next page
#lastPageLink()#              // link to last page
#pageNumberLinks(windowSize=5, classForCurrent="active")#
```

Disabled links render as `<span class="disabled">` by default. All helpers accept `handle` for named pagination queries.

## Testing Quick Reference

**All new tests use TestBox BDD syntax.** RocketUnit (`test_` prefix, `assert()`) is legacy only — never use it for new tests.

### Two test suites
- **App tests**: `/wheels/app/tests` — project-specific tests in `tests/specs/`. Uses `tests/populate.cfm` for test data and `tests/TestRunner.cfc` for setup.
- **Core tests**: `/wheels/core/tests` — framework tests in `vendor/wheels/tests/specs/`. Uses `vendor/wheels/tests/populate.cfm`. This is what CI runs across all engines × databases.

**Critical**: Core tests use `directory="wheels.tests.specs"` which compiles EVERY CFC in the directory. One compilation error in any spec file crashes the entire suite for that engine.

```cfm
// tests/specs/models/MyFeatureSpec.cfc
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

- **Specs**: `tests/specs/models/`, `tests/specs/controllers/`, `tests/specs/functional/`
- **Test models**: `tests/_assets/models/` (use `table()` to map to test tables)
- **Test data**: `tests/populate.cfm` (DROP + CREATE tables, seed data)
- **Runner URL**: `/wheels/app/tests?format=json&directory=tests.specs.models`
- **Force reload**: append `&reload=true` after adding new model CFCs
- **Closure gotcha**: CFML closures can't access outer `local` vars — use shared structs (`var result = {count: 0}`)
- **Scope gotcha in test infra**: Wheels internal functions (`$dbinfo`, `model()`, etc.) aren't available as bare calls in `.cfm` files included from plain CFCs like `TestRunner.cfc`. Use `application.wo.model()` or native CFML tags (`cfdbinfo`).
- **`#` escape gotcha**: HTML entities like `&#111;` contain `#` which CFML interprets as expression delimiters. In string literals, escape as `&##111;`. Comments (`//`) are fine since they aren't evaluated. Unescaped `#` in strings causes "Invalid Syntax Closing [#] not found" compilation errors that crash the **entire** test suite (not just that file).
- **`$clearRoutes()` in test specs**: Test CFCs that manipulate routes must define their own `$clearRoutes()` method — it is NOT inherited from `wheels.WheelsTest`. Copy from `linksSpec.cfc`.
- **`Left(str, 0)` crashes Lucee 7**: Use a ternary guard: `local.match.pos[1] > 1 ? Left(str, local.match.pos[1] - 1) : ""`
- Run with MCP `wheels_test()` or CLI `wheels test run`

## Running Tests Locally (Docker)

**IMPORTANT: Always run the test suite before pushing.** Do not rely on CI alone.

### Minimum: test both Lucee AND Adobe before pushing
Lucee and Adobe CF have different runtime behaviors (struct member functions,
application scope, closure scoping). Always test at least **two engines**:
```bash
cd /path/to/wheels/rig    # must be in the repo root with compose.yml

# Start both engines (SQLite is built-in on all engines, no external DB needed)
docker compose up -d lucee6 adobe2025

# Wait ~60s for startup, then run both:
curl -s -o /tmp/lucee6-results.json "http://localhost:60006/wheels/core/tests?db=sqlite&format=json"
curl -s -o /tmp/adobe2025-results.json "http://localhost:62025/wheels/core/tests?db=sqlite&format=json"

# Check results (HTTP 200=pass, 417=failures)
for f in /tmp/lucee6-results.json /tmp/adobe2025-results.json; do
  python3 -c "
import json
d = json.load(open('$f'))
engine = '$f'.split('/')[-1].replace('-results.json','')
print(f'{engine}: {d[\"totalPass\"]} pass, {d[\"totalFail\"]} fail, {d[\"totalError\"]} error')
for b in d.get('bundleStats',[]):
  for s in b.get('suiteStats',[]):
    for sp in s.get('specStats',[]):
      if sp.get('status') in ('Failed','Error'):
        print(f'  {sp[\"status\"]}: {sp[\"name\"]}: {sp.get(\"failMessage\",\"\")[:120]}')
"
done
```

### Engine ports
| Engine | Port |
|--------|------|
| lucee5 | 60005 |
| lucee6 | 60006 |
| lucee7 | 60007 |
| adobe2018 | 62018 |
| adobe2021 | 62021 |
| adobe2023 | 62023 |
| adobe2025 | 62025 |
| boxlang | 60001 |

### Test with a specific database
```bash
docker compose up -d lucee6 mysql
curl -sf "http://localhost:60006/wheels/core/tests?db=mysql&format=json" > /tmp/results.json
```

### Run a specific test directory
```bash
curl "http://localhost:60006/wheels/core/tests?db=sqlite&format=json&directory=tests.specs.controller"
```

### Known cross-engine gotchas

**Always verify Adobe CF fixes locally before pushing** — don't iterate via CI. Test against the local container directly:
```bash
curl -s "http://localhost:62023/wheels/core/tests?db=mysql&format=json" | \
  python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('totalPass',0),'pass',d.get('totalFail',0),'fail',d.get('totalError',0),'error')"
```

- **struct.map()**: Lucee/Adobe resolve `obj.map()` as the built-in struct member function, not the CFC method. Use `mapInstance()` on the Injector.
- **Application scope**: Adobe CF doesn't support function members on the `application` scope. Pass a plain struct context instead.
- **Closure this**: CFML closures capture `this` from the declaring scope. Use `var ctx = {ref: obj}` to share references across closures.
- **Bracket-notation function call**: `obj["key"]()` crashes Adobe CF 2021/2023 parser inside closures. Split into two statements: `var fn = obj["key"]; fn()`.
- **Array by-value in struct literals**: Adobe CF copies arrays by value in `{arr = myArray}`. Closures that append to the copy won't affect the original. Reference via parent struct instead: `{owner = parentStruct}` then `owner.arr`.
- **`private` mixin functions not integrated**: `$integrateComponents()` only copies `public` methods into model/controller objects. ALL helper functions in mixin CFCs (`vendor/wheels/model/*.cfc`, view helpers, etc.) MUST use `public` access. Use `$` prefix for internal scope instead of `private` keyword. BoxLang handles this differently, so `private` may pass BoxLang tests but fail Lucee/Adobe.

### CI soft-fail databases
CockroachDB is marked as soft-fail in `.github/workflows/tests.yml` — failures are logged as warnings but don't block the build. The `SOFT_FAIL_DBS` variable controls this. Remove a database from the list once its tests are fixed.

### Cleanup
```bash
docker compose down    # Stop all containers
```

## Database Seeding Quick Reference

Convention-based, idempotent seeding with CLI support.

```cfm
// app/db/seeds.cfm — Shared seeds (runs in all environments)
seedOnce(modelName="Role", uniqueProperties="name", properties={
    name: "admin", description: "Administrator"
});
seedOnce(modelName="Role", uniqueProperties="name", properties={
    name: "member", description: "Regular member"
});

// app/db/seeds/development.cfm — Dev-only seeds (runs after seeds.cfm)
seedOnce(modelName="User", uniqueProperties="email", properties={
    firstName: "Dev", lastName: "User", email: "dev@example.com"
});
```

**CLI:**
```bash
wheels db:seed                          # Run convention seeds (auto-detect)
wheels db:seed --environment=production # Seed for specific environment
wheels db:seed --generate               # Generate random test data (legacy)
wheels db:seed --generate --count=10    # Generate 10 records per model
wheels generate seed                    # Create app/db/seeds.cfm
wheels generate seed --all              # Create seeds.cfm + dev/prod stubs
```

**`seedOnce()`** — idempotent: checks `uniqueProperties` via `findOne()`, creates only if not found. Re-running seeds is always safe.

**Execution order:** `app/db/seeds.cfm` (shared) → `app/db/seeds/<environment>.cfm` (env-specific). Wrapped in a transaction.

**Seeder component:** `application.wheels.seeder` (initialized alongside migrator). Call `application.wheels.seeder.runSeeds()` programmatically.

## Background Jobs Quick Reference

```cfm
// Define a job: app/jobs/SendWelcomeEmailJob.cfc
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

// Enqueue from a controller
job = new app.jobs.SendWelcomeEmailJob();
job.enqueue(data={email: user.email});           // immediate
job.enqueueIn(seconds=300, data={email: "..."});  // delayed 5 minutes
job.enqueueAt(runAt=scheduledDate, data={});       // at specific time

// Process jobs (call from scheduled task or controller)
job = new wheels.Job();
result = job.processQueue(queue="mailers", limit=10);

// Queue management
stats = job.queueStats();          // {pending, processing, completed, failed, total}
job.retryFailed(queue="mailers");  // retry all failed jobs
job.purgeCompleted(days=7);        // clean up old completed jobs
```

**Job Worker CLI** — persistent daemon for processing jobs:
```bash
wheels jobs work                           # process all queues
wheels jobs work --queue=mailers --interval=3  # specific queue, 3s poll
wheels jobs status                         # per-queue breakdown
wheels jobs status --format=json           # JSON output
wheels jobs retry --queue=mailers          # retry failed jobs
wheels jobs purge --completed --failed --older-than=30
wheels jobs monitor                        # live dashboard
```

**Configurable backoff**: `this.baseDelay = 2` and `this.maxDelay = 3600` in job `config()`. Formula: `Min(baseDelay * 2^attempt, maxDelay)`.

Requires migration: `20260221000001_createwheels_jobs_table.cfc`. Run with `wheels dbmigrate latest`.

## Server-Sent Events (SSE) Quick Reference

```cfm
// In a controller action — single event response
function notifications() {
    var data = model("Notification").findAll(where="userId=#params.userId#");
    renderSSE(data=SerializeJSON(data), event="notifications", id=params.lastId);
}

// Streaming multiple events (long-lived connection)
function stream() {
    var writer = initSSEStream();
    for (var item in items) {
        sendSSEEvent(writer=writer, data=SerializeJSON(item), event="update");
    }
    closeSSEStream(writer=writer);
}

// Check if request is from EventSource
if (isSSERequest()) { renderSSE(data="..."); }
```

Client-side: `const es = new EventSource('/controller/notifications');`

## Reference Docs

Deeper documentation lives in `.ai/` — Claude will search it automatically when needed:
- `.ai/wheels/cross-engine-compatibility.md` — **Start here** for Lucee/Adobe cross-engine gotchas
- `.ai/cfml/` — CFML language reference (syntax, data types, components)
- `.ai/wheels/models/` — ORM details, associations, validations, scopes, enums
- `.ai/wheels/controllers/` — filters, rendering, security
- `.ai/wheels/views/` — layouts, partials, form helpers (including HTML5), link helpers
- `.ai/wheels/database/` — migrations, queries, seeding, advanced operations
- `.ai/wheels/cli/` — generators (including admin generator)
- `.ai/wheels/testing/` — unit testing with TestBox, test infrastructure, common gotchas
- `.ai/wheels/configuration/` — routing, environments, settings, DI container

## Commit Message Conventions

This repo uses commitlint. Commit messages must follow: `type(scope): lowercase subject`

**Valid scopes:** `model`, `controller`, `view`, `router`, `middleware`, `migration`, `cli`, `test`, `config`, `di`, `job`, `mailer`, `plugin`, `sse`, `seed`, `docs`

**Invalid scope:** `security` — use the layer it touches (e.g., `model` for SQL injection fix, `view` for XSS fix, `config` for consoleeval hardening, `cli` for MCP server fixes).

**Subject must be lowercase.** No sentence-case, start-case, or pascal-case. Write `fix(model): validate index names` not `fix(model): Validate index names`.

## Branding

The project name is **Wheels** (not "CFWheels"). The rebrand happened at v3.0. Always use "Wheels" in new code, comments, commit messages, PR descriptions, and documentation.

## MCP Server

Endpoint: `/wheels/mcp` (routes must come before `.wildcard()` in routes.cfm).

Tools: `wheels_generate`, `wheels_migrate`, `wheels_test`, `wheels_server`, `wheels_reload`, `wheels_analyze`, `wheels_validate`.
