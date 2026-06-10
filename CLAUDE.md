# Wheels Framework

CFML MVC framework with ActiveRecord ORM. The framework itself lives in `vendor/wheels/` (NOT a dependency — this repo IS the framework). The repo also contains a demo app under `app/` you can hand-test against.

## Code Map (where things live)

```
vendor/wheels/                  Framework core (model/, controller/, view/, dispatch/, migrator/, middleware/, …)
vendor/wheels/tests/specs/      Framework test suite — what CI runs across every engine × DB
app/                            Demo app (models, controllers, views, migrations) — exercise framework changes here
tests/specs/                    Demo-app test suite (separate from the framework suite)
cli/lucli/                      The `wheels` binary — branded LuCLI runtime + Module.cfc (MCP tools)
cli/lucli/services/deploy/      `wheels deploy` (Kamal port — see .ai/wheels/deploy.md)
cli/lucli/tests/specs/          CLI test suite
config/settings.cfm             Demo-app config (routes.cfm, environment.cfm, services.cfm-if-present)
plugins/                        DEPRECATED — legacy plugin system; modern packages live in vendor/<name>/
.ai/wheels/                     Deep reference docs Claude searches when needed
.claude/commands/               Wheels-bot prompts (.github/workflows/bot-*.yml runs these)
```

**Branding:** the project name is **Wheels** (not "CFWheels"). The rebrand happened at v3.0. Use "Wheels" in code, comments, commits, PRs, and docs.

## Before Reporting a Change Complete

| If you touched | Run | Required? |
|---|---|---|
| `vendor/wheels/**` | `bash tools/test-local.sh` (full) or `bash tools/test-local.sh <area>` | Always |
| `app/**` only | Demo-app specs via `wheels test` | Always |
| `cli/lucli/**` | `bash tools/test-cli-local.sh` | Always |
| Anything cross-engine-risky (closures, `obj.map()`, reserved scopes, struct literals, mixins) | `tools/test-matrix.sh adobe2023 mysql` AND `tools/test-matrix.sh lucee7 mysql` | If touched code matches any anti-pattern below |
| Added/changed a migration | `wheels migrate latest && wheels migrate down && wheels migrate up` | Always |
| Changed a public framework API | `grep -r` callers under `vendor/wheels`, `app`, `tests`, `cli/lucli/tests` | Always |

Type checks and a green test suite verify *code correctness*. They do NOT verify *feature correctness* for UI changes — if you changed a view/form/route, hand-test it in a browser or say so explicitly.

## Cross-Engine Invariants (apply to every change in `vendor/wheels/`)

The framework must run on Lucee 5/6/7, Adobe CF 2018/2021/2023/2025, and BoxLang. These rules cause more bugs than anything else combined.

1. **`obj.map()` resolves to the built-in struct member function** on Lucee/Adobe — not your CFC method. Use `mapInstance()` on the Injector, or rename your method.
2. **`application` scope doesn't accept function members on Adobe CF.** Pass a plain struct context instead.
3. **Closure `this` captures the declaring scope** — use `var ctx = {ref: obj}` to share references across closures.
4. **`obj["key"]()` inside closures crashes Adobe CF 2021/2023's parser.** Split: `var fn = obj["key"]; fn();`.
5. **Inline closure as constructor named arg** (`new Foo(callback = function(){...})`) crashes Adobe CF with `ArrayStoreException: ASTcffunction`. **Worse: it takes down the entire TestBox bundle** because `getComponentMetadata()` triggers eager compilation. Hoist: `var fn = function(){...}; new Foo(callback = fn);`.
6. **Adobe CF copies arrays by value in struct literals.** `{arr = myArray}` then mutating `arr` inside a closure won't affect the original. Use parent struct ref: `{owner = parentStruct}` then `owner.arr`.
7. **`private` mixin functions are not integrated.** `$integrateComponents()` only copies `public` methods into model/controller objects. ALL helpers in `vendor/wheels/model/*.cfc`, view helpers, etc. MUST use `public` access with `$` prefix for internal scope. BoxLang passes; Lucee/Adobe fail.
8. **`Left(str, 0)` crashes Lucee 7.** Guard: `len > 0 ? Left(str, len) : ""`.
9. **`toBeInstanceOf("component")` fails on BoxLang** — returns the FQN, not the literal `"component"`. Use `toBeWheelsModel()` for finder results.
10. **Adobe CF 2023 and 2025 reject the `arguments` scope as `attributeCollection` on *any* built-in CFML tag.** Affects every `cfheader` / `cfcache` / `cfcontent` / `cfmail` / `cfdirectory` / `cffile` / `cflocation` / `cfhtmlhead` / `cfimage` / `cfdbinfo` / `cfinvoke` / `cfwddx` / `cfzip` wrapper. Covers both the string-interpolated (`attributeCollection = "#arguments#"`) and direct-struct (`attributeCollection = arguments`) forms. Adobe 2023/2025 throw — `cfheader`'s message is `"Failed to add HTML header"`; other tags surface their own — and `$header()` is catastrophic because it runs on every request. Copy to a plain struct first: `local.args = {}; for (local.key in arguments) { local.args[local.key] = arguments[local.key]; }`. Lucee 6/7, BoxLang, and Adobe 2018/2021 accept both forms; Adobe 2023/2025 require the plain struct. The 13 sites in `vendor/wheels/Global.cfc` were patched uniformly in [#2750](https://github.com/wheels-dev/wheels/pull/2750).
11. **`local.X = ...` inside `catch` doesn't persist on BoxLang.** Catch body runs under a nested `local` that gets discarded on exit, so `expect(local.X)` after the catch reads the un-touched outer value. Use a struct field: `var state = {flag = false}; ... state.flag = true;`. Bare `var bareName` + unscoped `bareName = true` also works but the struct form mirrors `TenantResolverSpec` and is the prior-art pattern.
12. **`for (local.i = ...)` inside `finally` miscompiles on Lucee 7.** Lucee 7.0.1+100 throws `variable [local] doesn't exist` at runtime when a `for` loop declares or iterates `local`-/`var`-scoped variables inside a `finally` block (one probe shape even produced a JVM `Expecting a stackmap frame` verifier error). Bare assignments and function calls in `finally` are fine; loops are not. Hoist the loop into a `public` `$`-prefixed helper and call it from `finally` — reference: `$restoreEmailViewVariables()` in `vendor/wheels/controller/miscellaneous.cfc` ([#2922](https://github.com/wheels-dev/wheels/pull/2922)).

Verify Adobe CF fixes locally before pushing — don't iterate via CI:
```bash
curl -s "http://localhost:62023/wheels/core/tests?db=mysql&format=json" | \
  python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('totalPass',0),'pass',d.get('totalFail',0),'fail',d.get('totalError',0),'error')"
```

Deep reference: [.ai/wheels/cross-engine-compatibility.md](.ai/wheels/cross-engine-compatibility.md).

## Anti-Patterns (Top 14)

These are the most common mistakes when generating or modifying Wheels code. Check every time.

### 1. Mixed Argument Styles
Wheels functions cannot mix positional and named arguments. #1 error source.
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
```

### 4. HTML5 Form Helpers Exist — Use Them
```cfm
#emailField(objectName="user", property="email")#
#urlField(objectName="user", property="website")#
#numberField(objectName="product", property="quantity", min="1", max="100")#
#telField(objectName="user", property="phone")#
#dateField(objectName="event", property="startDate")#
#colorField(objectName="theme", property="primaryColor")#
#rangeField(objectName="settings", property="volume", min="0", max="100")#
#searchField(objectName="search", property="query")#
// Tag forms: emailFieldTag, numberFieldTag, etc.
```

### 5. Migration Seed Data — Direct SQL Only
Parameter binding in `execute()` is unreliable. Use inline SQL.
```cfm
// WRONG
execute(sql="INSERT INTO roles (name) VALUES (?)", parameters=[{value="admin"}]);

// RIGHT — and use NOW() for database-agnostic dates (MySQL/PG/MSSQL/H2/SQLite)
execute("INSERT INTO roles (name, createdAt, updatedAt) VALUES ('admin', NOW(), NOW())");
```

### 6. Route Order Matters
Routes match first-to-last. Wrong order = wrong matches.
```
Order: MCP routes → resources → custom named routes → root → wildcard (last!)
```

### 7. `timestamps()` Adds Three Columns (Not Two)
`createdAt`, `updatedAt`, AND `deletedAt` (soft-delete marker). Don't add separate datetime columns for these. Verified against `vendor/wheels/migrator/TableDefinition.cfc`.

### 8. Controller Filters Must Be Private
Public filter functions become routable actions.
```cfm
// WRONG
function authenticate() { ... }

// RIGHT
private function authenticate() { ... }
```

Conversely, public **framework helpers** mixed onto every controller (`env`, `model`, `redirectTo`, `linkTo`, the `is*` request predicates, the flash helpers, …) are auto-excluded from the routable surface. At app start `application.wheels.protectedControllerMethods` is built from the `wheels.Global` + `wheels.controller.*` + `wheels.view.*` mixin surface (the same `getMetaData().functions` set `$integrateComponents` mixes in), and `$callAction()` throws `Wheels.ActionNotAllowed` → 404 for any action whose name matches one. So a helper can't be invoked as an action — but you also **can't name a user action after a framework helper** (it 404s instead of dispatching). The standard REST action names (`index`, `show`, `new`, `edit`, `create`, `update`, `delete`) are not helpers, so they're unaffected ([#2845](https://github.com/wheels-dev/wheels/pull/2845)).

### 9. Always cfparam View Variables
Every variable passed from controller to view needs a cfparam at the top of the view file.
```cfm
<cfparam name="users" default="">
<cfparam name="user" default="">
```

### 10. Test Closure Scope
CFML closures can't access outer `local` vars. Use shared structs:
```cfm
// WRONG
var count = 0;
items.each(function(i) { count++; });  // local.count not visible

// RIGHT
var result = {count: 0};
items.each(function(i) { result.count++; });
```

### 11. CFML Reserved Scopes Shadow Function Parameters
**Source:** [#2591](https://github.com/wheels-dev/wheels/pull/2591) — `consoleExec(url, body)` received the URL scope struct in place of the URL string, throwing `Cannot cast Object type [url] to a value of type [string]`.

Reserved scope names in CFML: `url`, `form`, `cgi`, `client`, `session`, `application`, `cookie`, `request`, `server`, `arguments`, `variables`, `local`, `this`. Naming a function parameter, local var, or argument the same as a scope shadows it but the scope can also win depending on engine and context.

```cfm
// WRONG
function consoleExec(required string url, required string body) {
    makeHttpPost(url, body);  // url = URL scope struct on Lucee, not the string
}

// RIGHT
function consoleExec(required string requestUrl, required string body) {
    makeHttpPost(requestUrl, body);
}
```

Rule: never use a reserved scope name as a parameter, local var, or function argument name. Also avoid `client` in browser-test code (Lucee throws "client scope is not enabled" when accessed).

### 12. Empty Array in `whereIn` / `whereNotIn`
**Source:** [#2736](https://github.com/wheels-dev/wheels/pull/2736) — `whereIn("id", [])` previously emitted literal `WHERE id IN ()`, a JDBC syntax error on every supported engine.

```cfm
// As of 4.0.x — short-circuits to 1=0 (no rows) for IN, 1=1 (all rows) for NOT IN
model("Post").whereIn("id", []).count()                            // 0
model("Post").whereNotIn("id", []).count()                         // total count
model("Post").where("status","active").whereIn("id", []).count()   // 0 (composes)
```

When writing query-builder methods or anything that interpolates arrays into SQL `IN`/`NOT IN`: always handle empty inputs explicitly. Empty inputs aren't exotic — they're what you get from form filters, sub-query results, and any runtime-built array.

### 13. Comma-List Config ≠ Single-Value HTTP Header
**Source:** [#2725](https://github.com/wheels-dev/wheels/pull/2725) — `Cors` middleware was echoing the comma-delimited `allowOrigins` config straight into `Access-Control-Allow-Origin`, violating the CORS spec (must be a single origin or `*`) and poisoning CDN caches.

When config accepts a list-shape (comma-delimited string or array) but the output is a single-value protocol field, you MUST resolve to one value (or omit the header). Don't pass the list through.

```cfm
// WRONG
header("Access-Control-Allow-Origin", listed);   // "https://a.com,https://b.com"

// RIGHT — match against request origin, emit single value or omit
var resolved = $resolveAllowOrigin(allowOrigins, requestOrigin);  // "" | "*" | "https://a.com"
if (len(resolved)) header("Access-Control-Allow-Origin", resolved);
```

Pair with `Vary: Origin` whenever the response varies by request origin ([#2724](https://github.com/wheels-dev/wheels/pull/2724)).

### 14. Strip CFML Comments Before Source-Scanning
**Source:** [#2595](https://github.com/wheels-dev/wheels/pull/2595) — `wheels validate` checked for `extends="Model"` with raw `findNoCase()` and was satisfied by a commented-out `// component extends="Model"` line, missing real missing-inheritance bugs.

Any validator, analyzer, scanner, or upgrade-check that does substring-matching over CFML source must strip line comments (`// …`), block comments (`/* … */`), AND tag comments (`<!--- … --->`) first. Helpers exist:
- `cli/lucli/services/Analysis.cfc::$stripCfmlComments()`
- `cli/lucli/Module.cfc::stripCfmlComments()`
- `cli/lucli/services/Doctor.cfc::$stripCfmlBlockComments()`

### 15. Migrator helpers accept singular AND plural column names — prefer the plural
**Source:** [#2781](https://github.com/wheels-dev/wheels/issues/2781) (`t.references()`) + [#2803](https://github.com/wheels-dev/wheels/issues/2803) (`t.primaryKey()`) — these two helpers were the last outliers in `TableDefinition.cfc`. Every sibling helper accepted `columnNames` / `columnName` via `$combineArguments`, but `references` required `referenceNames` and `primaryKey` required `name`. AI agents and humans both kept reaching for the consistent form and hitting "argument required" errors. Now resolved: both accept `columnNames` as an alias, and that's the preferred form going forward.

```cfm
// RIGHT — modern, matches every other column helper
t.string(columnNames="name");
t.integer(columnNames="age");
t.references(columnNames="user");
t.primaryKey(columnNames="userId", autoIncrement=true);

// LEGACY — still works, but the new code path uses columnNames
t.references(referenceNames="user");
t.primaryKey(name="userId", autoIncrement=true);
```

For new migrator helpers or anywhere you accept a column-name argument: declare `string columnNames` (NOT `required`), and call `$combineArguments(args=arguments, combine="columnNames,columnName", required=true)` at the top of the body. The pattern is documented in [vendor/wheels/migrator/CLAUDE.md](vendor/wheels/migrator/CLAUDE.md). Boolean nullable flag is `allowNull` everywhere — never `null`.

`t.references()` also respects `useUnderscoreReferenceColumns` (boolean, framework default `false`, `wheels new` template default `true`) — when true it produces `<name>_id` / `<name>_type` columns matching Wheels model `belongsTo` defaults.

## Wheels Conventions

- **config()**: All model associations/validations/callbacks and controller filters/verifies go in `config()`.
- **Naming**: Models singular PascalCase (`User.cfc`), controllers plural PascalCase (`Users.cfc`), tables plural lowercase (`users`).
- **Parameters**: `params.key` for URL key, `params.user` for form struct, `params.user.firstName` for nested.
- **extends**: Models extend `"Model"`, controllers extend `"Controller"`, tests extend `"wheels.WheelsTest"`. (Legacy: `"wheels.Test"` was RocketUnit — never use for new tests.)
- **Validation property param**: `property` (singular) for single, `properties` (plural) for list: `validatesPresenceOf(properties="name,email")`.

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

    private struct function scopeByRole(required string role) {
        return {where: "role = '#arguments.role#'"};
    }
}
```

Finders: `model("User").findAll()`, `findOne(where="...")`, `findByKey(params.key)`.
Create: `model("User").new(params.user).save()`, or `model("User").create(params.user)`.
Include associations: `findAll(include="role,orders")`. Pagination: `findAll(page=params.page, perPage=25)`.

### Scopes / Enums / Builder / Batch

```cfm
// Scopes — chain composably
model("User").active().recent().findAll();
model("User").byRole("admin").findAll(page=1, perPage=25);

// Enums — auto-generated checkers and scopes
user.isDraft();                    // true/false
model("User").draft().findAll();

// Chainable query builder (injection-safe; values auto-quoted)
model("User")
    .where("status", "active")
    .where("age", ">", 18)
    .whereNotNull("emailVerifiedAt")
    .orderBy("name", "ASC")
    .limit(25)
    .get();
// Methods: where, orWhere, whereNull, whereNotNull, whereBetween, whereIn, whereNotIn, orderBy, limit, get

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

### Route Model Binding

Resolves `params.key` into a model instance before the action runs. Lands in `params.<singularModelName>`. Throws `Wheels.RecordNotFound` (404) if missing; silently skips if the model class doesn't exist.

```cfm
.resources(name="users", binding=true)                // params.user
.resources(name="posts", binding="BlogPost")          // params.blogPost
.scope(path="/api", binding=true)                     // all nested resources bound
.end()
set(routeModelBinding=true);                          // global, in config/settings.cfm
```

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
    .scope(path="/api", middleware=["app.middleware.ApiAuth"])
        .resources("users")
    .end()
.end();
```

Built-in: `wheels.middleware.RequestId`, `wheels.middleware.Cors`, `wheels.middleware.SecurityHeaders`, `wheels.middleware.RateLimiter`. Custom: implement `wheels.middleware.MiddlewareInterface`, place in `app/middleware/`.

### Rate Limiting

```cfm
new wheels.middleware.RateLimiter()                                            // fixed window, 60 req / 60s
new wheels.middleware.RateLimiter(maxRequests=100, windowSeconds=120, strategy="slidingWindow")
new wheels.middleware.RateLimiter(maxRequests=50, windowSeconds=60, strategy="tokenBucket")
new wheels.middleware.RateLimiter(storage="database")                          // auto-creates wheels_rate_limits
new wheels.middleware.RateLimiter(keyFunction=function(req) {                  // rate-limit per API key
    return req.cgi.http_x_api_key ?: "anonymous";
})
```

Strategies: `fixedWindow` (default), `slidingWindow`, `tokenBucket`. Storage: `memory` or `database`. Emits `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`. Returns `429` with `Retry-After` when exceeded.

`windowSeconds` must be > 0; `maxRequests` must be >= 0. Invalid values throw `Wheels.RateLimiter.InvalidConfiguration` at construction. `maxRequests = 0` is a valid kill-switch.

## DI Container Quick Reference

Register services in `config/services.cfm` (loaded at app start; environment overrides supported):

```cfm
var di = injector();
di.map("emailService").to("app.lib.EmailService").asSingleton();
di.map("currentUser").to("app.lib.CurrentUserResolver").asRequestScoped();
di.bind("INotifier").to("app.lib.SlackNotifier").asSingleton();
```

Resolve with `service("emailService")` anywhere, or `inject("emailService, currentUser")` in controller `config()`. Scopes: transient (default), `.asSingleton()`, `.asRequestScoped()`. Auto-wiring: `init()` params matching registered names are auto-resolved when no `initArguments` passed.

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

**Critical**: core tests use `directory="wheels.tests.specs"` which compiles EVERY CFC in the directory. One compilation error in any spec file crashes the entire suite for that engine. The "inline closure as constructor named arg" anti-pattern (#5 in Cross-Engine Invariants) is the classic example.

### Test-specific gotchas

- **Test infra scope**: Wheels internals (`$dbinfo`, `model()`, etc.) aren't available as bare calls in `.cfm` files included from plain CFCs like `TestRunner.cfc`. Use `application.wo.model()` or native CFML tags (`cfdbinfo`).
- **`#` escape**: HTML entities like `&#111;` contain `#` which CFML interprets as expression delimiter. In string literals, escape: `&##111;`. Comments (`//`) are fine. Unescaped `#` in strings crashes the **entire** test suite, not just that file.
- **`$clearRoutes()` in test specs**: NOT inherited from `wheels.WheelsTest`. Copy from `linksSpec.cfc` if your spec manipulates routes.

### Running tests locally

```bash
bash tools/test-local.sh                      # all core tests (SQLite)
bash tools/test-local.sh model                # vendor/wheels/tests/specs/model/
bash tools/test-local.sh controller           # …/controller/
bash tools/test-local.sh view                 # …/view/
bash tools/test-local.sh security             # …/security/
bash tools/test-local.sh middleware           # …/middleware/
bash tools/test-local.sh dispatch             # …/dispatch/
bash tools/test-local.sh migrator             # …/migrator/

# Cross-engine via Docker (mirrors compat-matrix.yml exactly)
tools/test-matrix.sh                          # Lucee 7 + SQLite (fastest)
tools/test-matrix.sh lucee7 mysql
tools/test-matrix.sh lucee7 sqlite,mysql
tools/test-matrix.sh lucee6,lucee7 sqlite
tools/test-matrix.sh --all                    # full matrix
tools/test-matrix.sh --rebuild lucee7         # force image rebuild
tools/test-matrix.sh --down                   # teardown
```

Engines: `lucee6`, `lucee7`, `adobe2023`, `adobe2025`, `boxlang` (CI matrix). Ports: 60006 / 60007 / 62023 / 62025 / 60001. Databases: `sqlite`, `h2` (Lucee only), `mysql`, `postgres`, `sqlserver`, `cockroachdb`, `oracle`. Oracle is soft-fail in CI (see `SOFT_FAIL_DBS` in `.github/workflows/compat-matrix.yml`).

Java 21 + Wheels CLI 4.0.0+ required for `tools/test-local.sh`. Docker required for `tools/test-matrix.sh`. `compose.yml` bind-mounts source at `./:/wheels-test-suite` so edit-reload-test cycles don't require image rebuilds.

### Onboarding harness

`tools/test-onboarding.sh` simulates a brand-new-user fresh-install flow without touching your daily wheels install. Use when fixing CLI/framework/template code that affects `wheels new` → `wheels start` → `wheels migrate latest`. Validates cliff fixes BEFORE asking for a fresh-VM tutorial run. ~90s end-to-end across 7 phases. Deep reference: [.ai/wheels/testing/onboarding-harness.md](.ai/wheels/testing/onboarding-harness.md).

### Browser tests

Specs extend `wheels.wheelstest.BrowserTest`. Install Playwright once: `wheels browser setup` (~370MB). Then `bash tools/test-local.sh` includes them. Deep reference: [.ai/wheels/testing/browser-testing.md](.ai/wheels/testing/browser-testing.md).

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

_Auto-migration is currently CFC-only (`wheels.migrator.AutoMigrator`, shown above). There is no `wheels dbmigrate diff` CLI command — invoking it errors._

Result struct: `{modelName, tableName, addColumns, removeColumns, changeColumns, renameColumns, suggestedRenames}`. Limits: PK renames not detected; rename + type change requires separate migrations; calculated properties excluded.

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

Worker CLI:
```bash
wheels jobs work --queue=mailers --interval=3
wheels jobs status [--format=json]
wheels jobs retry --queue=mailers
wheels jobs purge --completed --failed --older-than=30
wheels jobs monitor
```

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

## Commit Message Conventions

The canonical rules live in `commitlint.config.js` — if this section and the config disagree, the config wins.

### Format

`type(scope): subject` — scope is optional.

- **type** required.
- **scope** optional and unrestricted. Suggested: `model`, `controller`, `view`, `router`, `middleware`, `migrator`, `cli`, `test`, `config`, `di`, `job`, `mailer`, `plugin`, `sse`, `seed`, `docs`, or static-site monorepo scopes like `web`, `web/blog`, `web/guides`. None enforced.
- **subject** required, non-empty, not ALL-CAPS, header ≤ 100 chars, body lines ≤ 100 chars.

### Valid types

`feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.

Notes:
- `ci` is a TYPE, not a scope — never write `refactor(ci):`.
- DCO sign-off email must match `git config user.email` — prefer `git commit -s` over manual trailer.

## CLI / MCP

**Canonical surface (Wheels 4.0+):** the Wheels CLI's stdio MCP server at `wheels mcp wheels`.

```json
{"mcpServers":{"wheels":{"command":"wheels","args":["mcp","wheels"]}}}
```

There is no `wheels mcp setup` command — copy the JSON above into `.mcp.json` manually (see the MCP integration guide for OpenCode/Cursor variants).

Tools are auto-discovered from `cli/lucli/Module.cfc` public functions, prefixed with the module name (`wheels_generate`, `wheels_migrate`, `wheels_test`, `wheels_reload`, `wheels_seed`, `wheels_analyze`, `wheels_validate`, `wheels_routes`, `wheels_info`, `wheels_destroy`, `wheels_doctor`, `wheels_stats`, `wheels_notes`, `wheels_db`, `wheels_upgrade`, `wheels_create`, `wheels_deploy`). CLI-only tools (`mcp`, `d`, `g`, `new`, `console`, `start`, `stop`, `browser`) are hidden via `mcpHiddenTools()`.

**Deprecated:** the in-dev-server HTTP endpoint at `/wheels/mcp`. Emits a deprecation notice on first request. Migrate to the stdio surface.

> **`wheels` IS the CLI.** Built on the LuCLI runtime under the wheels brand — there is no separate `lucli` binary on a normal install. Older docs mentioning `lucli` predate the rebrand.

## Development Tools (preferred forms)

Prefer MCP tools when the Wheels MCP server is available. Fall back to CLI otherwise.

| Task | MCP | CLI |
|------|-----|-----|
| Generate | `wheels_generate(type, name, attributes)` | `wheels g model/controller/scaffold Name attrs` |
| Migrate | `wheels_migrate(action="latest\|up\|down\|info\|doctor")` | `wheels migrate latest\|up\|down\|info\|doctor` |
| Migrator reconciliation | — | `wheels migrate forget\|pretend <version> --yes` (shared dev DB orphan cleanup; see #2780) |
| Test | `wheels_test()` | `wheels test` |
| Reload | `wheels_reload()` | `?reload=true&password=...` |
| Server | — | `wheels start\|stop` |
| Analyze | `wheels_analyze(target="all")` | — |
| Admin | — | `wheels g admin ModelName` |
| Seed | — | `wheels seed` |

## Reference Docs (verified to exist)

Search `.ai/` for deeper documentation:

- [.ai/wheels/cross-engine-compatibility.md](.ai/wheels/cross-engine-compatibility.md) — Start here for Lucee/Adobe gotchas
- [.ai/wheels/deploy.md](.ai/wheels/deploy.md) — `wheels deploy` Kamal port (extracted from CLAUDE.md)
- [.ai/wheels/wheels-bot.md](.ai/wheels/wheels-bot.md) — Bot architecture (extracted from CLAUDE.md)
- [.ai/wheels/testing/browser-testing.md](.ai/wheels/testing/browser-testing.md) — Browser DSL (extracted from CLAUDE.md)
- [.ai/wheels/testing/onboarding-harness.md](.ai/wheels/testing/onboarding-harness.md) — Fresh-install simulation
- [.ai/wheels/controllers/api.md](.ai/wheels/controllers/api.md) — API controller patterns
- [.ai/wheels/views/query-association-patterns.md](.ai/wheels/views/query-association-patterns.md) — Loop / include patterns
- [.ai/wheels/security/https-detection.md](.ai/wheels/security/https-detection.md)
- [.ai/wheels/channels/channels.md](.ai/wheels/channels/channels.md)
- [.ai/wheels/snippets/model-snippets.md](.ai/wheels/snippets/model-snippets.md), [controller-snippets.md](.ai/wheels/snippets/controller-snippets.md)
- [.ai/wheels/troubleshooting/common-errors.md](.ai/wheels/troubleshooting/common-errors.md), [form-helper-errors.md](.ai/wheels/troubleshooting/form-helper-errors.md)
- [.ai/wheels/troubleshooting/shared-dev-databases.md](.ai/wheels/troubleshooting/shared-dev-databases.md) — Orphan-version handling + `migrate doctor` / `forget` / `pretend` reconciliation commands (#2780)
- [.ai/cfml/](.ai/cfml/) — CFML language reference (syntax, components, control flow)

**External:** user-facing guides at `web/sites/guides/src/content/docs/v4-0-0/` (deployment, command-line-tools/mcp-integration, etc.) — these ship to guides.wheels.dev. Use when you need the version Wheels users read.
