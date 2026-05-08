# Wheels Framework

CFML MVC framework with ActiveRecord ORM. Models in `app/models/`, controllers in `app/controllers/`, views in `app/views/`, migrations in `app/migrator/migrations/`, config in `config/`, tests in `tests/`.

## Directory Layout

```
app/controllers/    app/models/    app/views/    app/views/layout.cfm
app/migrator/migrations/    app/db/seeds.cfm    app/db/seeds/
app/events/    app/global/    app/lib/
app/mailers/    app/jobs/    app/plugins/    app/snippets/
config/settings.cfm    config/routes.cfm    config/environment.cfm
plugins/    public/    tests/    vendor/    .env (never commit)
```

## Development Tools

Prefer MCP tools when the Wheels MCP server is available (`mcp__wheels__*`). Fall back to CLI otherwise.

| Task | MCP | CLI |
|------|-----|-----|
| Generate | `wheels_generate(type, name, attributes)` | `wheels g model/controller/scaffold Name attrs` |
| Migrate | `wheels_migrate(action="latest\|up\|down\|info")` | `wheels migrate latest\|up\|down\|info` |
| Test | `wheels_test()` | `wheels test run` |
| Reload | `wheels_reload()` | `?reload=true&password=...` |
| Server | `wheels_server(action="status")` | `wheels start\|stop\|status` |
| Analyze | `wheels_analyze(target="all")` | — |
| Admin | — | `wheels g admin ModelName` |
| Seed | — | `wheels seed` (legacy alias: `wheels db:seed`) |

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

### 7. timestamps() Includes createdAt, updatedAt, and deletedAt
Don't also add separate datetime columns for these.
```cfm
// WRONG — duplicates
t.timestamps();
t.datetime(columnNames="createdAt");

// RIGHT
t.timestamps();  // creates createdAt, updatedAt, AND deletedAt (soft-delete)
```
Note: `t.timestamps()` adds three columns, not two — the third is the soft-delete marker. Verified against `vendor/wheels/migrator/TableDefinition.cfc`.

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

Optional first-party modules are distributed as standalone repositories and installed into `vendor/<name>/`. The framework auto-discovers `vendor/*/package.json` on startup via `PackageLoader.cfc` with per-package error isolation.

Public author-facing guide: [Packages](web/sites/guides/src/content/docs/v4-0-0-snapshot/digging-deeper/packages.mdx) — manifest fields, mixin targets, lifecycle, service providers, lazy loading, testing, publishing flow. Submission workflow: [wheels-packages/CONTRIBUTING.md](https://github.com/wheels-dev/wheels-packages/blob/main/CONTRIBUTING.md).

Six first-party packages live in standalone repos under `wheels-dev/`, indexed by the `wheels-dev/wheels-packages` registry:

- `wheels-dev/wheels-sentry` — error tracking
- `wheels-dev/wheels-hotwire` — Turbo/Stimulus
- `wheels-dev/wheels-basecoat` — UI components
- `wheels-dev/wheels-legacy-adapter` — 3.x → 4.x compatibility shims
- `wheels-dev/wheels-i18n` — internationalization (JSON or DB-backed translations, pluralization)
- `wheels-dev/wheels-seo-suite` — SEO tooling (meta tags, Open Graph, sitemaps, robots.txt, debug panel)

```
vendor/                # Runtime: framework core + installed packages
  wheels/              #   Framework core (excluded from package discovery)
  wheels-sentry/       #   Installed package
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

**`provides.mixins`**: Comma-delimited targets from the allowlist `application,dispatch,controller,mapper,model,base,sqlserver,mysql,postgresql,h2,test`, plus the special values `global` (inject into all targets) and `none` (explicit opt-out). Determines which framework components receive the package's public methods. Default: `none` (explicit opt-in, unlike legacy plugins which default to `global`). Unknown targets (typos, `view`, `service`, etc.) are rejected with a clear error — view helpers belong in `controller` mixins since Wheels views execute in the controller's variables scope.

### Installing a Package

Use the `wheels packages` CLI. Resolves names against the `wheels-dev/wheels-packages` registry, verifies sha256, extracts to `vendor/<name>/`.

```bash
wheels packages list                          # browse the registry
wheels packages search <query>                # name/description/tag match
wheels packages show <name>                   # detail page
wheels packages add <name>                    # latest compat version (canonical verb)
wheels packages add <name>@<version>          # pin
wheels packages add <name> --force            # overwrite an existing vendor/<name>
wheels packages update <name> --yes           # explicit update
wheels packages update --all --yes            # update every installed package
wheels packages remove <name>                 # delete vendor/<name>
wheels packages registry refresh              # bust the 24h cache
wheels packages registry info                 # show registry URL + cache state
```

Override the registry with `WHEELS_PACKAGES_REGISTRY=<org>/<repo>` (defaults to `wheels-dev/wheels-packages`). Restart or `wheels reload` after install.

### Error Isolation

Each package loads in its own try/catch. A broken package is logged and skipped — the app and other packages continue normally.

### Testing Packages

```bash
# Run a specific package's tests (package must be in vendor/)
curl "http://localhost:60007/wheels/core/tests?db=sqlite&format=json&directory=vendor.wheels-sentry.tests"
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

**All new tests use WheelsTest BDD syntax.** RocketUnit (`test_` prefix, `assert()`) is legacy only — never use it for new tests.

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

## Running Tests Locally (LuCLI — Recommended)

**IMPORTANT: Always run the test suite before pushing.** Do not rely on CI alone.

### Fastest method: one command
```bash
bash tools/test-local.sh              # run all core tests
bash tools/test-local.sh model        # run model tests only
bash tools/test-local.sh security     # run security tests only
```

The script handles everything: creates SQLite DBs, starts a LuCLI server if needed, runs tests, reports results, cleans up. No Docker required.

### Prerequisites (one-time setup)
```bash
# Install LuCLI (0.3.3+ recommended)
brew install lucli    # or download from GitHub releases
# Java 21 required
brew install openjdk@21
```

### Manual method (if you need a persistent server)
```bash
cd /path/to/wheels
sqlite3 wheelstestdb.db "SELECT 1;"
sqlite3 wheelstestdb_tenant_b.db "SELECT 1;"
lucli server run --port=8080

# In another terminal:
curl -s "http://localhost:8080/?reload=true&password=wheels"
curl -sf "http://localhost:8080/wheels/core/tests?db=sqlite&format=json" | \
  python3 -c "import json,sys; d=json.load(sys.stdin); print(f'{d[\"totalPass\"]} pass, {d[\"totalFail\"]} fail, {d[\"totalError\"]} error')"
```

### Run specific test directories
```bash
bash tools/test-local.sh model        # vendor/wheels/tests/specs/model/
bash tools/test-local.sh controller   # vendor/wheels/tests/specs/controller/
bash tools/test-local.sh view         # vendor/wheels/tests/specs/view/
bash tools/test-local.sh security     # vendor/wheels/tests/specs/security/
bash tools/test-local.sh middleware   # vendor/wheels/tests/specs/middleware/
bash tools/test-local.sh dispatch     # vendor/wheels/tests/specs/dispatch/
bash tools/test-local.sh migrator     # vendor/wheels/tests/specs/migrator/
```

## Running Tests Locally (Docker matrix)

Docker is the authoritative way to reproduce CI's `compat-matrix.yml` workflow
(every engine × every database) before pushing. Source is bind-mounted via
[compose.yml](compose.yml) at `./:/wheels-test-suite`, so edit-reload-test
cycles don't require image rebuilds — only the Wheels application reloads
between iterations.

### `tools/test-matrix.sh` — local mirror of `compat-matrix.yml`

```bash
tools/test-matrix.sh                       # Lucee 7 + SQLite (happy path, fastest)
tools/test-matrix.sh lucee7 mysql          # Lucee 7 + MySQL
tools/test-matrix.sh lucee7 sqlite,mysql   # Multiple DBs against one engine
tools/test-matrix.sh lucee6,lucee7 sqlite  # Multiple engines against one DB
tools/test-matrix.sh --all                 # Full matrix (every engine × every DB)
tools/test-matrix.sh --rebuild lucee7      # Force `docker compose build` (image cache stale)
tools/test-matrix.sh --down                # Tear everything down
```

Mirrors CI exactly: engine + DB containers come up under
`COMPOSE_PROJECT_NAME=wheels` (so containers are named `wheels-<service>-1`,
matching every assertion in `compat-matrix.yml`); engine restarts between DB
runs to clear cached model metadata; warmup curl before each test run; same
test URL (`/wheels/core/tests?db=<db>&format=json`); same JSON parsing.

Default behavior: containers stay running between invocations (fast iteration
for repeated runs against the same engine/DB). Edit framework code → `--reload`
isn't needed if you're hitting the test endpoint, since `wheels/core/tests`
re-evaluates each request. For full app reload (model metadata, package
discovery): `curl "http://localhost:<port>/?reload=true&password=wheels"`.

### Engines and ports (mirror `compat-matrix.yml` matrix)
| Engine | Port |
|--------|------|
| lucee6 | 60006 |
| lucee7 | 60007 |
| adobe2023 | 62023 |
| adobe2025 | 62025 |
| boxlang | 60001 |

`compose.yml` also defines `lucee5`, `adobe2018`, `adobe2021` services for
historical reasons; they are NOT in the CI matrix and should be considered
unsupported for new development.

### Databases (mirror `compat-matrix.yml` DATABASES env)

`sqlite`, `h2` (Lucee only), `mysql`, `postgres`, `sqlserver`, `cockroachdb`,
`oracle`. SQLite and H2 are file-based (no container needed). The rest spawn
their own service containers.

### Manual ad-hoc invocations (skip the wrapper)

If you want to script something the wrapper doesn't cover, the underlying
moves are documented in [.github/workflows/compat-matrix.yml](.github/workflows/compat-matrix.yml).
Always set `COMPOSE_PROJECT_NAME=wheels` first so container names match CI.

```bash
export COMPOSE_PROJECT_NAME=wheels
docker compose up -d lucee7 mysql
# wait for ready (see compat-matrix.yml lines 79-124 for canonical readiness check)
curl -s "http://localhost:60007/wheels/core/tests?db=mysql&format=json&directory=tests.specs.controller" > /tmp/results.json
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
`SOFT_FAIL_DBS` in `.github/workflows/compat-matrix.yml` (lines 389, 519) is currently empty (`""`) — **all databases, including CockroachDB, are hard-gated in CI**. To mark a database as soft-fail (failures logged as warnings but not blocking the build), add it to `SOFT_FAIL_DBS` in both locations. Remove a database from the list once its tests are fixed.

### Cleanup
```bash
tools/test-matrix.sh --down    # Stop and remove all containers + network
```

## Local Onboarding Harness

`tools/test-onboarding.sh` simulates the brand-new-user fresh-install flow without
touching the user's daily wheels install. It is the right tool when:

- Fixing CLI / framework / template code that affects the `wheels new` →
  `wheels start` → `wheels migrate latest` cliff.
- Validating cliff fixes BEFORE asking for a fresh-VM tutorial run.
- Iterating on dotted-path resolution, Lucee bundle issues, or generated
  config emission.

```bash
bash tools/test-onboarding.sh             # symlink-mount worktree (default)
MODE=copy bash tools/test-onboarding.sh   # closer to brew-install simulation
BASELINE=1 bash tools/test-onboarding.sh  # use the brew-installed wheels
KEEP_TEMP=1 bash tools/test-onboarding.sh # preserve temp dirs for inspection
FROM_PHASE=4 bash tools/test-onboarding.sh # skip earlier phases when iterating
```

The harness uses `LUCLI_HOME` isolation (writes only into `mktemp -d`), reuses
the user's existing Lucee Express via symlink to skip the ~74MB redownload, and
runs ~90 seconds end-to-end through 7 phases mirroring the fresh-VM onboarding
journal format. Output is directly comparable to fresh-VM run reports.

| Phase | Covers | Fresh-VM findings |
|---|---|---|
| 1 | Setup isolated `LUCLI_HOME`, framework path, Lucee Express symlink | — |
| 2 | `wheels new` (no duplicate `create` lines, file tree, no `bundleName`) | F1, F3, F4 |
| 3 | Server boot via `lucli server run` + sqlite-jdbc shim | (formula simulation) |
| 4 | Migration cliff — verify the actual sqlite db has tables, not just exit 0 | F2, F5 |
| 5 | Seed (cfscript wrapper + `seedOnce` idempotency) | F3-orig |
| 6 | CRUD walkthrough (tutorial chapters 2-3 happy path) | tutorial verification |
| 7 | `wheels packages list` | F7 (currently SKIP pending follow-up) |

Output uses `✓` / `✗` / `-` per check. A green local run is a strong predictor
of a green fresh-VM run; the SKIP markers signal known pending issues that are
expected to fail until their respective follow-up PRs ship.

Deeper reference: [.ai/wheels/testing/onboarding-harness.md](.ai/wheels/testing/onboarding-harness.md).

## Auto-Migration Quick Reference

Generate migrations from model/DB schema diffs. Rename detection via explicit hints (authoritative) + heuristic suggestions (normalized-token + Levenshtein).

```cfm
// Programmatic
var am = CreateObject("component", "wheels.migrator.AutoMigrator");

// Single model
var d = am.diff("User");
var d = am.diff("User", {renames: {"full_name": "fullName"}});
var d = am.diff("User", {heuristicThreshold: 0.85});

// All models (per-model hints keyed by model name)
var all = am.diffAll({
    hints: {"User": {renames: {"full_name": "fullName"}}},
    heuristicThreshold: 0.7
});

// Write migration CFC from diff result
am.writeMigration(d, "rename_name_field");
```

```bash
# CLI
wheels dbmigrate diff User                                    # preview
wheels dbmigrate diff User --rename=full_name:fullName        # with hint
wheels dbmigrate diff User --write --name=rename_name         # commit file
wheels dbmigrate diff --threshold=0.85                        # all models, stricter
wheels dbmigrate diff --rename=User.full_name:fullName        # diffAll hint
```

**Diff result struct:**
```
{modelName, tableName,
 addColumns, removeColumns, changeColumns,        // pruned of rename pairs
 renameColumns,       // confirmed renames (emitted into up/down)
 suggestedRenames}    // heuristic candidates for display
```

**Limits:** PK renames not detected; rename + type change requires separate migrations; calculated properties excluded from diff.

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

**CLI** (LuCLI canonical form; `wheels db:seed` is the legacy CommandBox alias — prefer the short form):
```bash
wheels seed                             # Run convention seeds (auto-detect env)
wheels seed --environment=production    # Seed for specific environment
wheels seed --generate                  # Legacy: random test data
wheels generate seed                    # Create app/db/seeds.cfm
wheels generate seed --all              # Create seeds.cfm + dev/prod stubs
```
Note: the `--count` / `--models` / `--dataFile` flags on `--generate` only exist on the legacy CommandBox `wheels db:seed` surface; LuCLI's `wheels seed` ignores them.

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

The `wheels_jobs` table is auto-created by `Job.cfc::$ensureJobTable()` on first enqueue or processing — no migration needed. (The older `20260221000001_createwheels_jobs_table.cfc` migration is vestigial; Phase 2b drift audit confirmed auto-create is now the path.)

## Deploy Quick Reference

`wheels deploy` ships your Dockerized Wheels app to production Linux servers via SSH. Ported from Basecamp Kamal's developer CLI — same `config/deploy.yml` schema, same on-server conventions (container names, labels, network, lock path), invokes the same `kamal-proxy` Go binary for zero-downtime rollover. No Ruby runtime required.

    wheels deploy init                     # scaffold config/deploy.yml + .kamal/secrets
    wheels deploy setup                    # one-time server bootstrap + first deploy
    wheels deploy                          # rolling deploy
    wheels deploy --dry-run                # print commands without executing
    wheels deploy rollback v1              # roll back to a previous version
    wheels deploy config                   # print resolved config as YAML
    wheels deploy version                  # show Kamal version this port mirrors

### Subcommands

```cfm
wheels deploy app <verb>         // boot/start/stop/details/containers/images/logs/live/maintenance/remove
wheels deploy proxy <verb>       // boot/reboot/start/stop/restart/details/logs/remove
wheels deploy accessory <verb>   // boot/reboot/start/stop/restart/details/logs/remove (sidecars: db/redis/search)
wheels deploy build <verb>       // deliver/push/pull/create/remove/details/dev
wheels deploy registry <verb>    // setup/login/logout/remove
wheels deploy server <verb>      // exec/bootstrap
wheels deploy prune <verb>       // all/images/containers [--keep=N]
wheels deploy lock <verb>        // acquire/release/status (manual — normal deploys auto-lock)
wheels deploy secrets <verb>     // fetch/extract/print (adapters: op/bitwarden/aws/lastpass/doppler)
wheels deploy audit              // tail /tmp/kamal-audit.log on each server
wheels deploy details            // aggregate app + proxy + accessory status
wheels deploy remove --confirm   // teardown all app/proxy/accessory containers
wheels deploy docs [section]     // in-terminal config reference
```

### On-server parity contract (byte-compatible with Ruby Kamal)

- Container names: `<service>-<role>-<version>`
- Labels: `service=`, `role=`, `destination=`, `version=`
- Docker network: `kamal`
- Lock file: `/tmp/kamal_deploy_lock_<service>`
- Proxy config: `/home/<user>/.config/kamal-proxy/`
- Hook env prefix: `KAMAL_*` (never `WHEELS_*` — user hooks migrate unchanged)

A server managed by Ruby Kamal can be taken over by `wheels deploy` without cleanup.

### Architecture

```
cli/lucli/services/deploy/
├── cli/*.cfc             DeployMainCli + Deploy<App|Proxy|Accessory|Build|Registry|Server|Prune|Lock|Secrets>Cli
├── commands/*.cfc        Base + Docker/App/Proxy/Builder/Registry/Auditor/Lock/Hook/Accessory/PruneCommands
├── config/*.cfc          Config + Role/Env/Builder/Proxy/Registry/Ssh/Accessory/Validator/ConfigLoader
├── lib/*.cfc             JarLoader/Mustache/Yaml/SshClient/SshPool/FakeSshPool/Output/SecretResolver
└── secrets/*.cfc         BaseAdapter + OnePassword/Bitwarden/AwsSecrets/LastPass/Doppler adapters

cli/lucli/lib/deploy/*.jar  jmustache, snakeyaml, sshj + BouncyCastle transitives (URLClassLoader-isolated)
cli/lucli/templates/deploy/ Mustache templates for `wheels deploy init` output
```

Commands-are-strings invariant: every `*Commands.cfc` method returns a shell-command string; only `*Cli.cfc` and the orchestrator execute them. That's why `--dry-run` is trivial and unit tests run without network.

### Critical gotchas

1. **Kamal-compatible schema, ONE divergence.** ERB in `deploy.yml` is NOT supported (rendering it would require embedding a Ruby runtime). Kamal's native `${VAR}` env-var interpolation is preserved unchanged — uppercase-snake tokens resolve via `envOverride → .kamal/secrets → System.getenv → ""` (see `ConfigLoader.$interpolate`). Mustache (`{{...}}`) is used only by `wheels deploy init` to scaffold a fresh `deploy.yml`/`secrets`; it is NOT applied to `deploy.yml` at runtime. Everything else in `config/deploy.yml` is byte-identical to Kamal 2.4.0.
2. **Hook env prefix is `KAMAL_`, not `WHEELS_`.** This is deliberate — it means Ruby Kamal users' existing `.kamal/hooks/` scripts work unchanged.
3. **`app live` / `app maintenance` use a marker file** (`/tmp/kamal-maintenance-<svc>`) rather than kamal-proxy native maintenance mode. Phase 2 simplification; Phase 3 follow-up will align with Kamal's proxy-native semantics.
4. **`wheels deploy remove` is destructive and requires `--confirm`.** Bare `wheels deploy remove` throws without touching anything.
5. **Lucee reserved scope names in subagent-authored deploy code.** `client`, `session`, `application` — use `ssh`/`sc`, `sess`, `app` instead. Bit us multiple times during the port.
6. **No `--dry-run` flag in Ruby Kamal 2.4.0.** The `tools/deploy-config-diff.sh` harness compares config-layer output only. Byte-identical command-string parity is aspirational; see `tools/deploy-dry-run-diff.sh` for the plan.

### Testing

`cli/lucli/tests/specs/deploy/` extends `wheels.wheelstest.system.BaseSpec`. Run with:

    bash tools/test-cli-local.sh

Fixtures at `cli/lucli/tests/_fixtures/deploy/configs/` (`minimal.yml`, `full.yml`, `with-accessories.yml`, `invalid/*.yml`). `FakeSshPool.cfc` records every command for offline assertions; no sshd needed for unit tests. `SshClientSpec` + `SshPoolSpec` exercise real SSH via the fixture at `cli/lucli/tests/_fixtures/deploy/sshd/` (brought up by `tools/deploy-sshd-up.sh`).

### Reference docs

- User guides: `docs/src/working-with-wheels/deployment/` (first-deploy, config-reference, accessories, secrets, hooks, migrating-from-kamal)
- Per-verb CLI reference: `docs/src/command-line-tools/commands/deploy/`
- Design spec: `docs/superpowers/specs/2026-04-20-wheels-deploy-kamal-port-design.md`
- Implementation plan: `docs/superpowers/plans/2026-04-20-wheels-deploy-kamal-port.md`
- Retrospective: `docs/superpowers/plans/2026-04-21-phase1-retrospective.md`

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

## Browser Testing Quick Reference

Shipped in v4.0 across PRs #2113, #2115, #2116. Specs extend `wheels.wheelstest.BrowserTest` and drive a real Chromium through `this.browser` — a fluent DSL wrapping Playwright Java.

```cfm
// vendor/wheels/tests/specs/browser/LoginBrowserSpec.cfc
component extends="wheels.wheelstest.BrowserTest" {

    this.browserEngine = "chromium";   // chromium only in PR 1

    function run() {
        // browserDescribe() wraps describe() with beforeEach/afterEach that
        // create a fresh Page per `it`. WheelsTest's BDD lifecycle only treats
        // beforeAll/afterAll as class-level, so we register per-it hooks
        // from inside the suite body via this helper.
        browserDescribe("Login flow", () => {
            it("can load a page and read its title", () => {
                if (this.browserTestSkipped) return;
                this.browser.visitUrl("data:text/html,<title>Hi</title><h1>x</h1>")
                            .assertTitleContains("Hi");
            });
        });
    }
}
```

Install Playwright locally before first run (~370MB download: JARs + Chromium):

```bash
wheels browser setup              # downloads JARs + Chromium
```

Then run browser specs via the normal test suite:
```bash
bash tools/test-local.sh                    # skips browser specs if JARs missing
```

### Implemented DSL methods

- **Navigation:** visit, visitUrl, back, forward, refresh, visitRoute
- **Interaction:** click, press, fill, type, clear, select, check, uncheck, attach, dragAndDrop
- **Keyboard:** keys, pressEnter, pressTab, pressEscape
- **Waiting:** waitFor, waitForText, waitForUrl
- **Scoping:** within(selector, callback)
- **Cookies:** setCookie, deleteCookie, cookie, clearCookies
- **Auth:** loginAs, logout
- **Dialogs:** acceptDialog, dismissDialog, dialogMessage (Lucee-only via createDynamicProxy)
- **Viewport:** resize, resizeToMobile, resizeToTablet, resizeToDesktop
- **Script:** script (returns `page.evaluate` result), pause
- **Assertions (text/vis/presence):** assertSee, assertDontSee, assertSeeIn, assertVisible, assertMissing, assertPresent, assertNotPresent
- **Assertions (URL/title/query):** assertUrlIs, assertUrlContains, assertTitleContains, assertQueryStringHas, assertQueryStringMissing, assertRouteIs
- **Assertions (form):** assertInputValue, assertChecked, assertHasClass
- **Terminals:** currentUrl, title, pageSource, text, value, screenshot

### Key gotchas

- **`##` in selectors** — CFML requires `##` to emit literal `#`. `"##email"` → `"#email"` at runtime.
- **`client` is a Lucee reserved scope.** `var client = ...` in a closure throws "client scope is not enabled". Use `var c = ...` or `var bc = ...`.
- **Data URLs work for most tests** — no server needed for ~95% of DSL coverage. Full HTTP integration (cookies, form submits, redirects) needs a running fixture app; that wiring is the same as Wheels Web app bootstrap (separate server + baseUrl).
- **`this.browserTestSkipped`** — when Playwright JARs aren't installed (fresh CI, clean machine), `beforeAll` sets this flag and `browserDescribe`'s hooks short-circuit. All `it`s should check `if (this.browserTestSkipped) return;` to stay green on CI.
- **CI runs browser tests** — `pr.yml` and `snapshot.yml` install Playwright JARs + Chromium (cached via `browser-manifest.json` hash). Browser specs run as part of the normal test suite. `WHEELS_BROWSER_TEST_BASE_URL=http://localhost:60007` is set automatically.
- **Fixture routes** — `/_browser/login-as` and `/_browser/logout` are mounted automatically in test mode. They must come before `.wildcard()` in routes.cfm.
- **Dialogs are Lucee-only** — `acceptDialog`, `dismissDialog`, `dialogMessage` use `createDynamicProxy` which is Lucee-specific. Specs skip gracefully on other engines.

Full reference: `.ai/wheels/testing/browser-testing.md`.

## Reference Docs

Deeper documentation lives in `.ai/` — Claude will search it automatically when needed:
- `.ai/wheels/cross-engine-compatibility.md` — **Start here** for Lucee/Adobe cross-engine gotchas
- `.ai/cfml/` — CFML language reference (syntax, data types, components, control flow, best practices)
- `.ai/wheels/core-concepts/` — MVC architecture, ORM mapping, routing conventions, Rails comparison
- `.ai/wheels/models/` — ORM details, associations, validations, scopes, enums, batch processing
- `.ai/wheels/controllers/` — actions, filters, rendering (JSON/views/redirects), security, SSE, parameter verification
- `.ai/wheels/views/` — layouts, partials, form helpers (including HTML5), link helpers, pagination, forms
- `.ai/wheels/database/` — migrations, queries, associations, validations, seeding
- `.ai/wheels/configuration/` — routing, environments, settings, DI container, multi-tenancy, security
- `.ai/wheels/middleware/` — pipeline structure, rate limiting, tenant resolver
- `.ai/wheels/jobs/` — background job queue, retries, priority queues
- `.ai/wheels/mcp/` — AI agent integration via LuCLI stdio MCP (setup, tool reference, auto-discovery)
- `.ai/wheels/packages/` — first-party packages (sentry, hotwire, basecoat) + activation model
- `.ai/wheels/cli/` — generators (model, controller, scaffold, admin, migrations)
- `.ai/wheels/testing/` — WheelsTest BDD, browser testing, browser automation patterns, **onboarding harness** (fresh-install simulation for cliff fixes)
- `.ai/wheels/security/` — CSRF protection, HTTPS detection
- `.ai/wheels/patterns/` — authentication, CRUD, validation templates
- `.ai/wheels/snippets/` — copy-paste model + controller examples
- `.ai/wheels/troubleshooting/` — common errors, form helper errors

## Commit Message Conventions

This repo uses commitlint. The canonical rules live in `commitlint.config.js`; this section reflects them. If the two ever disagree, the config wins — open a PR updating this section to match.

### Format

`type(scope): subject`

- **type** is required.
- **scope** is optional. Omit it when no allowed scope fits cleanly (this is normal — many commits don't need one).
- **subject** is required, must not be empty, and must not be ALL-CAPS.

### Valid types

`feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.

### Valid scopes (full list)

Framework layers:
`model`, `controller`, `view`, `router`, `middleware`, `migration`, `cli`, `test`, `config`, `di`, `job`, `mailer`, `plugin`, `sse`, `seed`, `docs`

Static-site monorepo (under `web/`):
`web`, `web/ui`, `web/landing`, `web/blog`, `web/guides`, `web/api`, `web/starlight`

When a change spans multiple layers or doesn't map cleanly, **use no scope** — `docs: …`, `fix: …`, `ci: …` are all valid bare forms. Prefer no scope over guessing.

### Common scope choices by file path

| You touched | Scope to use |
|---|---|
| `web/sites/guides/...` (tutorial, guides content) | `docs` (preferred for prose) or `web/guides` (preferred for site infra) |
| `web/sites/landing/...` | `web/landing` |
| `web/sites/blog/...` | `web/blog` |
| `web/sites/api/...` | `web/api` |
| `web/sites/packages/...` | `web` |
| `web/tests/visual-baselines/...` | `web` |
| `app/views/...`, `vendor/wheels/view/...` | `view` |
| `app/models/...`, `vendor/wheels/model/...` | `model` |
| `cli/...`, `vendor/wheels/cli/...` | `cli` |
| `config/...` | `config` |
| `tests/...` | `test` |
| `.github/workflows/...` | type `ci`, no scope (e.g. `ci: pin softprops…`) |
| `CLAUDE.md`, `README.md`, root docs | type `docs`, no scope |

### Invalid scopes

- `security` — use the layer it touches (e.g., `model` for SQL injection fix, `view` for XSS fix, `config` for consoleeval hardening).
- Anything not in the lists above. Specifically **do not invent scopes** like `tutorial`, `package`, `release` — commitlint will reject them.

### Subject rules

- Must not be empty.
- Must not be ALL-CAPS (e.g., `fix: FIX BUG` is rejected).
- Sentence-case, start-case, and pascal-case **are allowed** — proper nouns like `Giscus`, `CockroachDB`, `Buttondown` may keep their canonical capitalization.
- Header (`type(scope): subject`) capped at 100 chars.

### When you forget and CI rejects the commit

`gh pr checks <PR>` shows `Validate Commit Messages | fail`. The fix:

```bash
git commit --amend -m "<corrected message>"
git push --force-with-lease origin <branch>
```

CI re-runs on the new commit. No need for a separate "fix commit message" commit on a single-commit PR.

## Branding

The project name is **Wheels** (not "CFWheels"). The rebrand happened at v3.0. Always use "Wheels" in new code, comments, commit messages, PR descriptions, and documentation.

## MCP Server

**Canonical surface (Wheels 4.0+):** LuCLI stdio MCP at `wheels mcp wheels`. Configure your AI IDE with:

```json
{"mcpServers":{"wheels":{"command":"wheels","args":["mcp","wheels"]}}}
```

Or run `wheels mcp setup` to generate `.mcp.json` + `.opencode.json` automatically.

Tools are auto-discovered from `cli/lucli/Module.cfc` public functions, prefixed with the module name (`wheels_generate`, `wheels_migrate`, `wheels_test`, `wheels_reload`, `wheels_seed`, `wheels_analyze`, `wheels_validate`, `wheels_routes`, `wheels_info`, `wheels_destroy`, `wheels_doctor`, `wheels_stats`, `wheels_notes`, `wheels_db`, `wheels_upgrade`, `wheels_create`, `wheels_deploy`). CLI-only tools (`mcp`, `d`, `new`, `console`, `start`, `stop`, `browser`) are hidden from MCP `tools/list` via `mcpHiddenTools()`.

Workflow orchestration (multi-step planning, feature development) is not a framework concern — use your preferred Claude Code plugin (Superpowers, feature-dev, etc.). The framework ships deterministic Wheels operations via MCP; the model orchestrates.

**Deprecated:** The in-dev-server HTTP endpoint at `/wheels/mcp` (routed from `vendor/wheels/public/views/mcp.cfm`). Emits a deprecation notice and warning log on first request. Scheduled for removal in a future release — migrate to the stdio surface. See `docs/command-line-tools/commands/mcp/mcp-configuration-guide.md`.
