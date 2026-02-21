# Modernizing the Wheels Rim: A Comprehensive Plan

**Date:** February 21, 2026
**Scope:** Core framework infrastructure modernization with backwards compatibility
**Target:** Wheels 3.x (incremental) and Wheels 4.0 (breaking changes with migration path)

---

## 1. Executive Summary

The "rim" of the Wheels framework — its core infrastructure spanning the ORM, routing, controller pipeline, plugin/mixin system, dependency injection, and request dispatch — was architectured in an era before middleware pipelines, interface-driven design, and event-driven patterns became standard in web frameworks.

This document compares the current Wheels rim against five modern peers (Rails 8.1, Laravel 12, AdonisJS 6, Phoenix 1.8, Django 6.0), identifies 14 specific modernization targets, and proposes a phased implementation plan that preserves backwards compatibility throughout the 3.x series while laying groundwork for the modular Wheels 4.0 vision.

---

## 2. Comparative Analysis: Wheels Rim vs. Modern Frameworks

### 2.1 Request Pipeline & Middleware

| Aspect | **Wheels 3.0** | **Rails 8.1** | **Laravel 12** | **AdonisJS 6** | **Phoenix 1.8** |
|---|---|---|---|---|---|
| Pipeline model | Filter chain (before/after) | Rack middleware stack | PSR-15 middleware pipeline | HTTP middleware classes | Plug pipeline |
| Composability | Per-controller only | Global + per-route | Global + route groups + per-route | Global + route groups | Global + per-route + per-scope |
| Short-circuit | Filter returns false | Middleware skips `call` | Middleware skips `$next` | Middleware skips `next` | `halt` connection |
| Cross-cutting concerns | Plugin mixins (global injection) | Middleware + concerns | Middleware + service providers | Middleware + IoC | Plugs + contexts |

**Current Wheels pattern** (`vendor/wheels/controller/filters.cfc`):
```cfm
// Controller config()
filters(through="authenticate", type="before", except="login,register");
filters(through="logRequest", type="after");
```

**Problem:** Filters are controller-scoped. There is no global middleware pipeline. Cross-cutting concerns (logging, CORS, rate limiting, request ID tracking) must be implemented as plugin mixins injected into every controller via `$initializeMixins()`. This is brittle — the mixin system (`Plugins.cfc:219-274`) uses `StructAppend` to merge methods into component variable scopes, which can cause naming collisions and makes debugging difficult.

**Modern approach (middleware pipeline):**
```cfm
// config/middleware.cfm — global pipeline
application.wheels.middleware = [
    "wheels.middleware.RequestId",
    "wheels.middleware.Cors",
    "wheels.middleware.RateLimiter",
    "wheels.middleware.Session",
    "wheels.middleware.Csrf",
    "app.middleware.TenantResolver"
];

// config/routes.cfm — route-group middleware
mapper()
    .namespace(name="api", middleware="apiAuth,rateLimiter")
        .resources("users")
    .end()
.end();
```

### 2.2 Dependency Injection & Service Container

| Aspect | **Wheels 3.0** | **Rails 8.1** | **Laravel 12** | **AdonisJS 6** | **Phoenix 1.8** |
|---|---|---|---|---|---|
| DI container | Minimal (`Injector.cfc`) | None (convention) | Full IoC container | Full IoC container | None (OTP) |
| Service resolution | `map().to().asSingleton()` | Manual + autoloading | Auto-resolve + contextual binding | Class-based injection | Module attributes |
| Scoped instances | No | No | Request/singleton/transient | Singleton/transient | Process-based |
| Auto-wiring | No | No | Yes (type-hint resolution) | Yes (decorator-based) | No |

**Current Wheels pattern** (`vendor/wheels/Injector.cfc`):
```cfm
// wheels/Bindings.cfc
function configure(injector) {
    injector.map("global").to("wheels.Global").asSingleton();
    injector.map("Plugins").to("wheels.Plugins").asSingleton();
}
```

**Problem:** The Injector is bare-minimum — it supports `map/to/asSingleton` and `getInstance` but lacks request-scoped bindings, auto-wiring, contextual binding, or interface-to-implementation mapping. Most dependency resolution in Wheels still happens through `CreateObject()` calls scattered throughout the codebase (e.g., `Model.cfc:415`, `Dispatch.cfc`, `Plugins.cfc`). The mixin system functions as a poor-man's DI by injecting methods into component scopes at boot time.

**Modern approach:** Expand the Injector to support:
- Request-scoped bindings (resolved per HTTP request)
- Interface-to-implementation mapping (for the Wheels 4.0 modular vision)
- Auto-wiring based on argument names or type hints
- Service providers that register bindings during bootstrap

### 2.3 ORM & Query Builder

| Aspect | **Wheels 3.0** | **Rails 8.1** | **Laravel 12** | **AdonisJS 6** | **Phoenix 1.8** |
|---|---|---|---|---|---|
| Pattern | ActiveRecord | ActiveRecord | ActiveRecord | Active Record (Lucid) | Data Mapper (Ecto) |
| Query scopes | None | `scope :active, -> { where(active: true) }` | `scopeActive($q)` | `scopes({active: q => q.where()})` | Composable queries |
| Enum support | None | `enum status: [:draft, :published]` | `$casts['status'] = StatusEnum` | Column decorators | Ecto.Enum |
| Batch operations | None | `find_each`, `in_batches` | `chunk()`, `lazy()` | `chunk()` | `Repo.stream()` |
| Query builder | SQL string interpolation | Arel (AST-based) | Fluent query builder | Knex-based builder | Ecto.Query (composable) |
| Eager loading | `include="assoc"` (JOIN-based) | `includes` (separate query) | `with()` (separate query) | `preload()` | `preload` / `assoc` |

**Current Wheels pattern** (`vendor/wheels/model/read.cfc`, `sql.cfc`):
```cfm
model("User").findAll(
    where="status = 'active' AND role = 'admin'",
    include="orders",
    order="createdAt DESC",
    page=1, perPage=25
);
```

**Problems:**
1. **No query scopes** — Reusable query fragments must be manually composed as string concatenation. Every call site repeats `where="status = 'active'"`.
2. **No chainable query builder** — The `where` parameter is a raw SQL string. There's no composable query object.
3. **No batch processing** — `findAll()` loads the entire result set into memory. Processing 100K records requires manual pagination.
4. **No enum mapping** — Status columns use raw strings/integers with no framework-level abstraction.
5. **JOIN-only eager loading** — The `include` parameter generates JOINs, which can produce cartesian products with multiple has-many associations. Modern frameworks use separate queries to avoid this.

**Modern approach (query scopes + chainable builder):**
```cfm
// Model config()
scope(name="active", where="status = 'active'");
scope(name="recent", order="createdAt DESC");
scope(name="admins", where="role = 'admin'");
enum(property="status", values="draft,published,archived");

// Usage — composable
model("User").active().recent().admins().findAll(page=1, perPage=25);

// Batch processing
model("User").active().findEach(batchSize=1000, callback=function(user) {
    // Process one user at a time, memory-efficient
});
```

### 2.4 Routing & Resource Nesting

| Aspect | **Wheels 3.0** | **Rails 8.1** | **Laravel 12** | **AdonisJS 6** | **Phoenix 1.8** |
|---|---|---|---|---|---|
| Nested resources | Callback syntax (new) | Native block syntax | Native closure syntax | Native chained syntax | Native `do` blocks |
| API versioning | Manual namespace | `api_only: true` + namespace | `Route::prefix('v1')` | Route groups | `scope "/api/v1"` |
| Rate limiting | None | `rate_limit` macro | `throttle` middleware | Rate limiter middleware | Custom plugs |
| Route model binding | None | Implicit via convention | Implicit + explicit | Implicit via models | N/A |
| Health check route | None | Built-in `/up` | Built-in | Built-in | Built-in |

**Current Wheels pattern** (`vendor/wheels/mapper/resources.cfc`):
```cfm
mapper()
    .resources("posts")
    .resources("comments")  // Flat — no URL nesting
    .root(to="home##index")
    .wildcard()
.end();
```

The framework recently added callback-based nested resources:
```cfm
.resources(name="posts", callback=function(map) {
    map.resources("comments");
})
```

**Remaining gaps:**
1. **No route model binding** — Controllers must manually call `model("Post").findByKey(params.key)`. Modern frameworks auto-resolve model instances from route parameters.
2. **No API versioning convention** — No built-in pattern for `/api/v1/...` routing with version-specific controllers.
3. **No rate limiting** — No built-in request throttling.
4. **No health check** — No standard `/up` or `/health` endpoint.

### 2.5 Plugin/Extension System

| Aspect | **Wheels 3.0** | **Rails 8.1** | **Laravel 12** | **AdonisJS 6** | **Phoenix 1.8** |
|---|---|---|---|---|---|
| Extension model | Zip-based plugins + mixin injection | Gems + Railties | Composer packages + Service Providers | npm packages + providers | Hex packages + behaviours |
| Method injection | `StructAppend` into variable scopes | `include` modules | Service container binding | IoC decorators | `use` macros |
| Conflict handling | Last-loaded wins | Explicit includes | Explicit registration | Explicit registration | Explicit imports |
| Plugin isolation | None (global namespace) | Module namespaces | Service container scoping | Module namespaces | Module system |

**Current Wheels pattern** (`vendor/wheels/Plugins.cfc`):
```cfm
// Plugins are zip files in app/plugins/
// Extracted, then all public methods are injected into component scopes:
StructAppend(variablesScope, application[$wheels.appKey].mixins[$wheels.className], true);
```

**Problems:**
1. **No namespacing** — Plugin methods are injected directly into the variable scope of every model/controller/etc. Two plugins providing `authenticate()` will silently overwrite each other.
2. **Zip-based distribution** — While functional, this is outdated. Modern frameworks use standard package managers (npm, Composer, Hex).
3. **No lifecycle hooks** — Plugins can't hook into `onApplicationStart`, `onRequestStart`, or `onError` without relying on the mixin system.
4. **Railo-era workarounds** — The code still references Railo bugs (`Plugins.cfc:306`) and uses approaches designed for engines from a decade ago.

### 2.6 Background Jobs & Async

| Aspect | **Wheels 3.0** | **Rails 8.1** | **Laravel 12** | **AdonisJS 6** | **Phoenix 1.8** |
|---|---|---|---|---|---|
| Job system | Basic (`wheels.Job`) | Active Job + Solid Queue | Queue (Redis/SQS/DB) | Bull/BullMQ | Oban |
| Worker process | None (poll-based) | Solid Queue daemon | `queue:work` daemon | Separate worker | BEAM processes |
| Retry logic | Configurable | Built-in + dead letter | Built-in + failed jobs table | Built-in | Built-in + snooze |
| Scheduled jobs | `enqueueAt()` / `enqueueIn()` | Solid Queue recurring | `schedule:run` | `@adonisjs/scheduler` | Oban cron |
| Job monitoring | `queueStats()` | Mission Control dashboard | Horizon dashboard | Bull Board | Oban Web |
| Concurrency control | None | Solid Queue concurrency limits | Rate limiting per queue | Configurable | `unique` jobs |

**Current Wheels pattern** (`vendor/wheels/Job.cfc`):
```cfm
component extends="wheels.Job" {
    function config() { this.queue = "mailers"; this.maxRetries = 5; }
    public void function perform(struct data = {}) {
        sendEmail(to=data.email, subject="Welcome!");
    }
}
// Enqueue
job.enqueue(data={email: user.email});
```

**Problem:** The Job class exists but there's no worker daemon (`wheels jobs work`), no monitoring dashboard, no dead letter queue, and no concurrency controls. Jobs are enqueued but have no standard way to be processed.

### 2.7 Real-Time / Server-Sent Events

| Aspect | **Wheels 3.0** | **Rails 8.1** | **Laravel 12** | **AdonisJS 6** | **Phoenix 1.8** |
|---|---|---|---|---|---|
| SSE | Basic (`controller/sse.cfc`) | Turbo Streams (SSE) | Broadcasting via SSE | Transmit (SSE) | LiveView (WebSocket) |
| WebSocket | None | Action Cable | Laravel Reverb | WebSocket server | Phoenix Channels |
| Pub/Sub | None | Solid Cable (DB-backed) | Broadcasting (Redis/Pusher) | Redis pub/sub | PubSub (PG/Redis) |
| Client library | None | Turbo + Stimulus | Echo.js | `@adonisjs/transmit-client` | `phoenix.js` |

**Current state:** SSE is functional (`vendor/wheels/controller/sse.cfc`) with `renderSSE()`, `initSSEStream()`, `sendSSEEvent()`, and `closeSSEStream()`. However, there's no pub/sub system, no channel abstraction, and no client-side JavaScript library.

---

## 3. Modernization Targets (Prioritized)

### Tier 1: High Impact, Backwards-Compatible (Wheels 3.x)

| # | Target | Effort | Impact | Compatibility |
|---|--------|--------|--------|---------------|
| 1 | Middleware pipeline | Medium | High | Additive — filters still work |
| 2 | Query scopes | Low | High | Additive — new methods on Model |
| 3 | Chainable query builder | Medium | High | Additive — `where` string still works |
| 4 | Route model binding | Low | Medium | Additive — opt-in per route |
| 5 | Enum support on models | Low | Medium | Additive — new `enum()` config method |
| 6 | Batch processing (`findEach`, `findInBatches`) | Low | Medium | Additive — new finder methods |
| 7 | Health check route | Trivial | Low | Additive — auto-registered route |

### Tier 2: Medium Impact, Mostly Backwards-Compatible (Wheels 3.x)

| # | Target | Effort | Impact | Compatibility |
|---|--------|--------|--------|---------------|
| 8 | Expanded DI container (request scope, auto-wire) | Medium | Medium | Additive — old `map/to` still works |
| 9 | Job worker daemon (`wheels jobs work`) | Medium | High | Additive — completes existing Job class |
| 10 | Pub/Sub for SSE channels | Medium | Medium | Additive — new module |
| 11 | API versioning routes | Low | Medium | Additive — new Mapper method |
| 12 | Pagination view helpers | Low | Medium | Additive — new view functions |
| 13 | Rate limiting middleware | Medium | Medium | Additive — new middleware |

### Tier 3: Architectural (Wheels 4.0)

| # | Target | Effort | Impact | Compatibility |
|---|--------|--------|--------|---------------|
| 14 | Plugin system → Service Provider model | High | High | Breaking — migration path required |

---

## 4. Detailed Implementation Plan

### 4.1 Middleware Pipeline (Target #1)

**Goal:** Allow global and route-scoped middleware that runs before/after the controller filter chain, replacing ad-hoc plugin mixins for cross-cutting concerns.

**Design:**

```cfm
// A middleware is a CFC with handle(request, next)
component implements="wheels.middleware.MiddlewareInterface" {
    public any function handle(required struct request, required any next) {
        // Before logic
        request.startTime = GetTickCount();

        // Call next middleware in pipeline
        local.response = arguments.next(arguments.request);

        // After logic
        local.response.headers["X-Response-Time"] = GetTickCount() - request.startTime;

        return local.response;
    }
}
```

**Implementation steps:**
1. Create `wheels.middleware.MiddlewareInterface` with `handle(request, next)` contract
2. Create `wheels.middleware.Pipeline` that chains middleware with a `next` closure
3. Modify `Dispatch.cfc:$request()` to wrap the controller dispatch in the middleware pipeline
4. Add `middleware` parameter to `Mapper` route definitions
5. Ship built-in middleware: `RequestId`, `Cors`, `SecurityHeaders`

**Backwards compatibility:** Existing controller `filters()` continue to work unchanged. Middleware runs at the dispatch level (before controller instantiation), while filters run inside the controller. They are complementary, not conflicting.

### 4.2 Query Scopes (Target #2)

**Goal:** Allow reusable, composable query fragments defined in the model.

**Design:**

```cfm
// Model config()
function config() {
    scope(name="active", where="status = 'active'");
    scope(name="recent", order="createdAt DESC", maxRows=10);
    scope(name="byRole", handler="scopeByRole");  // Dynamic scope
}

// Dynamic scope handler
private struct function scopeByRole(required string role) {
    return {where: "role = '#arguments.role#'"};
}

// Usage
model("User").active().recent().findAll();
model("User").byRole("admin").findAll(page=1, perPage=25);
```

**Implementation steps:**
1. Add `scope()` config method to `Model.cfc` — stores scope definitions in `variables.wheels.class.scopes`
2. Add `$applyScope()` to model that returns a query specification struct
3. Use `onMissingMethod` in the model class to intercept scope calls and build a query spec chain
4. Modify `findAll()`, `findOne()`, `findByKey()` to accept and merge query spec structs
5. Return a `ScopeChain` proxy object from scope calls that accumulates specs and delegates to finders

**Backwards compatibility:** All existing `findAll(where="...")` calls work unchanged. Scopes are purely additive.

### 4.3 Chainable Query Builder (Target #3)

**Goal:** Replace raw SQL string construction with a composable, injection-safe query builder.

**Design:**

```cfm
// Current (still works)
model("User").findAll(where="status = 'active' AND age > 18", order="name ASC");

// New chainable builder
model("User")
    .where("status", "active")
    .where("age", ">", 18)
    .orderBy("name", "ASC")
    .limit(25)
    .offset(0)
    .get();

// Complex conditions
model("User")
    .where("status", "active")
    .orWhere("role", "admin")
    .whereNotNull("emailVerifiedAt")
    .whereBetween("createdAt", startDate, endDate)
    .get();
```

**Implementation steps:**
1. Create `wheels.model.QueryBuilder` class that accumulates query clauses
2. The builder stores clauses as structured data (not SQL strings) for parameterized query generation
3. `model("User")` returns a proxy that can initiate a builder chain via `.where()` etc.
4. The builder's `.get()` / `.first()` / `.count()` methods delegate to existing `findAll()` / `findOne()` internally
5. Ensure all values are parameterized (never interpolated) for SQL injection prevention

**Backwards compatibility:** The existing `findAll(where="string")` API remains the primary interface. The query builder is an alternative entry point that constructs the same internal query specification.

### 4.4 Route Model Binding (Target #4)

**Goal:** Automatically resolve model instances from route `key` parameters.

**Design:**

```cfm
// config/routes.cfm
mapper()
    .resources("users")  // GET /users/[key] auto-resolves model("User").findByKey(key)
.end();

// Controller — user is already resolved
function show() {
    // params.user is a model object (not just an ID)
    renderView(user=params.user);
}

// Opt-out
function show() {
    // Use params.key directly if you prefer
    user = model("User").findByKey(params.key);
}
```

**Implementation steps:**
1. Add `binding=true` option to resource routes (default configurable via `set(routeModelBinding=true)`)
2. In `Dispatch.cfc:$createParams()`, after route matching, resolve model instances
3. Detect the resource name from the route, singularize it for model name, call `findByKey()`
4. If the record is not found, throw `Wheels.RecordNotFound` (rendering a 404)
5. Store the resolved object in `params.<singularName>` alongside the raw `params.key`

**Backwards compatibility:** Off by default. Enable globally with `set(routeModelBinding=true)` or per-route. Existing code accessing `params.key` continues to work — the binding adds `params.<modelName>` alongside it.

### 4.5 Enum Support (Target #5)

**Goal:** Map integer/string columns to named states with built-in scopes and accessors.

**Design:**

```cfm
// Model config()
function config() {
    enum(property="status", values="draft,published,archived");
    enum(property="priority", values={low: 0, medium: 1, high: 2, critical: 3});
}

// Usage
user = model("User").new(status="draft");
user.status;          // "draft"
user.isDraft();       // true
user.isPublished();   // false

// Auto-generated scopes
model("User").draft().findAll();       // where status = 'draft'
model("User").published().findAll();   // where status = 'published'
```

**Implementation steps:**
1. Add `enum()` to Model config — stores in `variables.wheels.class.enums`
2. Generate dynamic boolean methods via `onMissingMethod`: `is<Value>()`
3. Generate scopes for each enum value
4. Add validation: `validatesInclusionOf(property="status", list="draft,published,archived")`
5. Support both string-based and integer-backed enums

**Backwards compatibility:** Purely additive. Existing models without `enum()` are unaffected.

### 4.6 Batch Processing (Target #6)

**Goal:** Process large datasets without loading everything into memory.

**Design:**

```cfm
// Process records one at a time
model("User").findEach(batchSize=1000, callback=function(user) {
    user.sendReminderEmail();
});

// Process in batches (callback receives a query)
model("User").findInBatches(batchSize=500, callback=function(users) {
    // users is a query of up to 500 records
    processUserBatch(users);
});

// With conditions
model("User").findEach(
    where="status = 'active'",
    order="createdAt ASC",
    batchSize=1000,
    callback=function(user) { /* ... */ }
);
```

**Implementation steps:**
1. Add `findEach()` to `model/read.cfc` — internally paginates using `findAll(page=n, perPage=batchSize)`
2. Add `findInBatches()` — same pagination but passes the entire query to the callback
3. Use primary key ordering by default for consistent pagination
4. Support `where`, `include`, and `order` parameters

**Backwards compatibility:** Purely additive new methods.

### 4.7 Job Worker Daemon (Target #9)

**Goal:** Complete the background job system with a persistent worker process.

**Design:**

```bash
# CLI commands
wheels jobs work --queue=default,mailers --concurrency=4
wheels jobs status
wheels jobs retry --queue=failed
wheels jobs purge --completed --older-than=7d
```

**Implementation steps:**
1. Ensure `_wheels_jobs` table auto-creates on first use (already designed in `Job.cfc`)
2. Implement `wheels.JobWorker` class that polls the job table
3. Create CLI commands: `work`, `status`, `retry`, `purge`
4. Add exponential backoff retry: delay = `min(baseDelay * 2^attempt, maxDelay)`
5. Add dead letter handling: jobs exceeding `maxRetries` move to `status='dead'`
6. Add concurrency control: worker claims jobs with `UPDATE ... WHERE status='pending' LIMIT 1` (row locking)
7. Add job timeout: kill jobs exceeding `this.timeout` seconds
8. Add `wheels jobs monitor` output showing queue depths and throughput

**Backwards compatibility:** Builds on existing `Job.cfc` API. No changes to how jobs are defined or enqueued.

### 4.8 Pub/Sub for SSE Channels (Target #10)

**Goal:** Add a channel abstraction over the existing SSE implementation.

**Design:**

```cfm
// Controller
function notifications() {
    subscribeToChannel(
        channel="user.#params.userId#",
        events="notification,alert",
        lastEventId=GetHTTPRequestData().headers["Last-Event-ID"] ?: ""
    );
}

// Publish from anywhere (model callback, job, etc.)
publish(channel="user.42", event="notification", data=SerializeJSON({
    title: "New message",
    body: "You have a new message from Alice"
}));
```

**Implementation steps:**
1. Create `wheels.Channel` module with in-memory pub/sub (suitable for single-server)
2. Create `wheels.channel.DatabaseAdapter` for multi-server pub/sub via a `_wheels_events` table
3. Add `subscribeToChannel()` controller method that wraps `initSSEStream()` with channel filtering
4. Add global `publish()` function
5. Ship `wheels-sse.js` client library for auto-reconnect and event handling
6. Integrate with Job system for async publishing

**Backwards compatibility:** The existing `renderSSE()` / `initSSEStream()` / `sendSSEEvent()` API continues to work for direct SSE. Channels are a higher-level abstraction built on top.

### 4.9 Expanded DI Container (Target #8)

**Goal:** Evolve the Injector into a production-grade service container.

**Design:**

```cfm
// config/services.cfm
injector.map("mailer").to("app.services.MailerService").asSingleton();
injector.map("storage").to("app.services.S3StorageService").asSingleton();
injector.map("paymentGateway").to("app.services.StripeGateway").asRequestScoped();

// Controller — resolve services
function create() {
    var mailer = service("mailer");
    mailer.send(to=user.email, template="welcome");
}

// Or via injection in controller config
function config() {
    inject("mailer");
    inject("storage");
}
```

**Implementation steps:**
1. Add `asRequestScoped()` to Injector — instances tied to `request` scope
2. Add `service(name)` global helper (like `model()` but for services)
3. Add `inject(name)` controller config method for declarative injection
4. Add interface binding: `injector.bind("StorageInterface").to("S3Storage")`
5. Add auto-wiring: resolve init arguments by matching parameter names to mappings

**Backwards compatibility:** Existing `map().to().asSingleton()` continues to work. New features are additive.

### 4.10 Plugin System Evolution (Target #14 — Wheels 4.0)

**Goal:** Replace the zip-based, mixin-injection plugin system with a Service Provider model.

**Current problems:**
- Plugins are zip files that must be extracted (`Plugins.cfc:110-126`)
- Methods are injected via `StructAppend` into variable scopes (`Plugins.cfc:279-313`)
- No namespacing — collision risk
- Dead code referencing Railo-era workarounds (`Plugins.cfc:306`)
- "mixableComponents" is a hardcoded comma-delimited list (`Plugins.cfc:15`)

**Proposed Service Provider model:**

```cfm
// app/plugins/MyAuth/ServiceProvider.cfc
component implements="wheels.ServiceProviderInterface" {

    function register(container) {
        container.map("auth").to("MyAuth.AuthService").asSingleton();
        container.map("authMiddleware").to("MyAuth.AuthMiddleware");
    }

    function boot(app) {
        // Register middleware
        app.addMiddleware("MyAuth.AuthMiddleware");
        // Register routes
        app.routes(function(mapper) {
            mapper.get(name="login", to="sessions##new");
            mapper.post(name="authenticate", to="sessions##create");
        });
        // Register model methods via traits (explicit, not global injection)
        app.modelTrait("authenticatable", "MyAuth.Authenticatable");
    }
}
```

**Migration path:**
1. In 3.x, introduce `ServiceProvider` interface alongside existing plugin system
2. Plugins can optionally include a `ServiceProvider.cfc` for new-style registration
3. In 4.0, deprecate mixin injection; require all plugins to use Service Providers
4. Ship a `wheels-legacy-plugin-adapter` for running old plugins in 4.0

---

## 5. Implementation Phases

### Phase 1: Foundation (Weeks 1-4, Wheels 3.x patch)

| Deliverable | Files Modified | Risk |
|---|---|---|
| Middleware pipeline | `Dispatch.cfc`, new `middleware/` dir | Low — additive |
| Query scopes | `Model.cfc`, `model/read.cfc` | Low — additive |
| Health check route | `Mapper.cfc` | Trivial |
| Enum support | `Model.cfc`, `model/properties.cfc` | Low — additive |
| Batch processing | `model/read.cfc` | Low — additive |

### Phase 2: Developer Experience (Weeks 5-8, Wheels 3.x minor)

| Deliverable | Files Modified | Risk |
|---|---|---|
| Chainable query builder | New `model/QueryBuilder.cfc` | Medium — new abstraction |
| Route model binding | `Dispatch.cfc`, `Mapper.cfc` | Low — opt-in |
| Pagination view helpers | New `view/pagination.cfc` | Low — additive |
| API versioning routes | `mapper/scoping.cfc` | Low — additive |
| Rate limiting middleware | New `middleware/RateLimiter.cfc` | Low — additive |

### Phase 3: Infrastructure (Weeks 9-14, Wheels 3.x minor)

| Deliverable | Files Modified | Risk |
|---|---|---|
| Job worker daemon | `Job.cfc`, new CLI commands | Medium — new process model |
| Pub/Sub channels | New `Channel.cfc`, extends `sse.cfc` | Medium — new module |
| Expanded DI container | `Injector.cfc` | Medium — extends core |
| `wheels-sse.js` client library | New JS file in `public/` | Low — client-only |

### Phase 4: Architectural (Wheels 4.0)

| Deliverable | Files Modified | Risk |
|---|---|---|
| Service Provider plugin model | `Plugins.cfc` replacement | High — migration needed |
| Interface-driven module system | Core refactor per 4.0 vision | High — major version |
| Legacy compatibility adapter | New adapter module | Medium |

---

## 6. Backwards Compatibility Contract

All changes in Phases 1-3 adhere to these rules:

1. **No existing public API changes** — All current method signatures remain unchanged
2. **No config() changes** — Existing model/controller config continues to work
3. **No route changes** — Existing route definitions continue to work
4. **Additive only** — New features are new methods, new config options, new files
5. **Opt-in by default** — New behavior (route model binding, middleware) requires explicit enablement
6. **Deprecation before removal** — Any feature targeted for removal in 4.0 gets a deprecation notice in 3.x with a minimum of 2 minor versions before removal

**Specific compatibility guarantees:**
- `model("User").findAll(where="...")` — unchanged forever
- `filters(through="...", type="before")` — works alongside middleware
- `hasMany(name="...")` / `belongsTo(name="...")` — unchanged
- `validatesPresenceOf(properties="...")` — unchanged
- `mapper().resources("...").end()` — unchanged
- Plugin zip files — supported through 3.x, deprecated in 4.0

---

## 7. What NOT to Change

Based on competitive analysis, these aspects of Wheels should remain as-is:

1. **ActiveRecord pattern** — Don't introduce Repository or Data Mapper. ActiveRecord is Wheels' identity and its ORM is already competitive with Rails/Laravel.

2. **Convention-over-configuration philosophy** — Don't add XML/YAML config files. The `config()` method pattern is clean and sufficient.

3. **Server-rendered MVC architecture** — Don't bolt on React/Vue/SPA patterns. Pair with HTMX or Alpine.js for progressive enhancement instead.

4. **Multi-engine support** — The 8-engine compatibility is a genuine differentiator. Don't drop engines to simplify.

5. **The `model()` helper** — `model("User").findAll()` is more readable than any alternative. Keep it.

6. **CFML as the primary language** — Don't try to add TypeScript or transpilation layers. Improve the CFML developer experience instead.

---

## 8. Success Metrics

| Metric | Current | Target (3.x) | Target (4.0) |
|---|---|---|---|
| Middleware support | None (plugin mixins) | Full pipeline | Full pipeline + route-scoped |
| Query composability | String concatenation | Scopes + builder | Scopes + builder + streaming |
| Background job processing | Enqueue only | Full worker + monitoring | Distributed workers |
| Real-time capability | Basic SSE | SSE + pub/sub channels | SSE + WebSocket channels |
| Plugin architecture | Mixin injection | Mixin + Service Provider | Service Provider only |
| DI container | map/to/singleton | + request scope + auto-wire | Full IoC |

---

## 9. Conclusion

The Wheels rim is structurally sound — the ActiveRecord ORM, convention-based routing, and controller architecture are competitive with modern peers. The modernization targets are primarily about **composability** (middleware pipeline, query scopes, chainable builder), **completeness** (job worker, pub/sub, pagination helpers), and **architectural hygiene** (DI container, Service Providers).

The key insight from the competitive analysis is that Wheels doesn't need to change its fundamental paradigm. It needs to make its existing paradigm more composable and complete. Rails, Laravel, and Phoenix succeed not because of novel architecture, but because they make common patterns effortless. Each of the 14 targets above addresses a specific pattern that Wheels developers currently implement manually.

By implementing Phases 1-3 within the 3.x series (fully backwards-compatible), and Phase 4 in the 4.0 release (with a migration path), Wheels can close the gaps identified in the competitive analysis while preserving the conventions and simplicity that define the framework.
