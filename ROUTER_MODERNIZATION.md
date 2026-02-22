# Wheels Router Modernization Analysis

## Current Architecture

The Wheels router lives in `vendor/wheels/Mapper.cfc` with four mixin components:

| File | Purpose |
|------|---------|
| `Mapper.cfc` | Core: initialization, regex compilation, pattern normalization, `$addRoute`, scope stack management |
| `mapper/mapping.cfc` | `$draw()`, `end()` — lifecycle and RESTful route expansion |
| `mapper/matching.cfc` | `get()`, `post()`, `patch()`, `put()`, `delete()`, `root()`, `wildcard()`, `$match()` — route registration |
| `mapper/resources.cfc` | `resource()`, `resources()`, `member()`, `collection()` — RESTful resource generation |
| `mapper/scoping.cfc` | `scope()`, `namespace()`, `package()`, `controller()`, `constraints()` — nesting and grouping |
| `Dispatch.cfc` | `$findMatchingRoute()`, `$request()`, `$createParams()` — runtime matching and dispatch |

### How It Works

1. **Route Definition** (`config/routes.cfm`): The `mapper()` function creates a `Mapper` instance, returns `this` for fluent chaining. Routes are defined via `.resources()`, `.get()`, `.post()`, etc.

2. **Scope Stack**: A `scopeStack` array tracks nesting context. `scope()` pushes, `end()` pops. Resources, namespaces, and packages push scoped state onto the stack.

3. **Pattern Compilation**: `$match()` normalizes patterns, converts `[variable]` segments to regex via `$patternToRegex()`, supports optional segments `(...)`, and glob patterns `*[var]`.

4. **Route Storage**: `$addRoute()` appends route structs to both `variables.routes` and `application.wheels.routes` — a flat array.

5. **Runtime Matching** (`$findMatchingRoute`): **Linear scan** of `application.wheels.routes`, testing each route's regex against the request path. First match wins.

6. **Dispatch**: `$request()` calls `$paramParser()` which finds the matching route, merges URL/form/JSON params, and hands off to the controller.

### Current Feature Set

- RESTful resources (singular and plural) with full CRUD
- Nested resources via `callback` or `nested=true`
- HTTP verb matchers: GET, POST, PUT, PATCH, DELETE
- HEAD → GET fallback
- Named routes with auto-generated camelCase names
- Namespaces and packages (controller subfolder scoping)
- Route constraints (regex per variable)
- Optional pattern segments
- Glob patterns (`*[variable]`)
- Shallow nesting
- Format mapping (`.[format]`)
- Wildcard catch-all routes
- Route redirects
- `_method` override for PUT/PATCH/DELETE from forms
- JSON body parsing
- URL obfuscation support

---

## Comparison with Modern Frameworks

### Feature Gap Analysis

| Feature | Wheels | Laravel | Rails | Fastify | Phoenix | ASP.NET Core |
|---------|--------|---------|-------|---------|---------|-------------|
| **RESTful resources** | Yes | Yes | Yes | Manual | Yes | Yes |
| **Named routes** | Yes (auto) | Yes | Yes (auto) | Plugin | Yes (verified) | Yes |
| **Nested resources** | Yes | Yes | Yes | Manual | Yes | Yes |
| **Route constraints** | Regex only | Regex + typed | Regex + custom class | JSON Schema + custom | No (controller-level) | Typed + chained + custom |
| **Route groups/scoping** | namespace, package, scope | group() with attributes | namespace, scope, concerns | register() + prefix | scope + pipe_through | MapGroup() |
| **Middleware at route level** | No (controller filters only) | Yes | Constraints + controller filters | Yes (lifecycle hooks) | Yes (pipelines per scope) | Yes (endpoint filters) |
| **API versioning** | Manual namespace | Route prefix groups | Namespace nesting | Native Accept-Version | Nested scopes | First-class package |
| **Rate limiting** | No | Built-in | rack-attack gem | Plugin | Hammer lib | Built-in (4 strategies) |
| **Route caching/compilation** | No | artisan route:cache | Boot-time compile | Radix tree | Compile-time pattern match | DFA matcher |
| **Route model binding** | No | Yes (implicit + explicit) | No (controller-level) | No | No | Via filters |
| **Health check routes** | No | Manual | Built-in (7.1+) | Plugin | Manual | First-class |
| **Subdomain routing** | No | Route::domain() | constraints subdomain: | Native host constraint | Custom Plug | [Host()] attribute |
| **Fallback routes** | wildcard() | Route::fallback() | match via: :all | setNotFoundHandler | No | app.MapFallback() |
| **Route listing/debugging** | Route tester GUI | artisan route:list | bin/rails routes | --routes flag | mix phx.routes | dotnet-routes tool |
| **Typed constraints** | No | whereNumber(), whereAlpha() | No | Built-in | No | :int, :guid, :bool, etc. |
| **Route-level redirect** | Yes | Yes | Yes | Yes | No | Yes |

### Key Gaps (Prioritized)

#### 1. Linear Route Matching (Performance - High Impact)
**Current**: `$findMatchingRoute()` does O(n) linear scan with regex matching per route.
**Modern**: Fastify uses a radix tree (O(log n)), ASP.NET Core uses a DFA, Phoenix compiles to pattern matching.
**Impact**: Applications with 100+ routes see measurable latency. Every request pays the cost.

#### 2. No Route-Level Middleware (Architecture - High Impact)
**Current**: Middleware-like behavior requires controller filters. No way to attach middleware to route groups at the routing layer.
**Modern**: Every major framework supports attaching middleware/pipelines at the route or group level.
**Impact**: Cross-cutting concerns like auth, CORS, and rate limiting must be duplicated across controllers.

#### 3. No Route Groups with Shared Attributes (DX - High Impact)
**Current**: `namespace()` adds both URL prefix AND controller package. `package()` adds only controller package. No way to group routes sharing middleware, constraints, or other attributes without side effects.
**Modern**: Laravel `Route::group()`, Rails `scope`, Phoenix `scope` + `pipe_through` all support attribute-only grouping.
**Impact**: Developers cannot create logical groupings like "all API routes share these constraints and this middleware."

#### 4. No Typed/Convenience Constraints (DX - Medium Impact)
**Current**: Only raw regex via `constraints: { id: "\d+" }`.
**Modern**: Laravel has `whereNumber()`, `whereAlpha()`, `whereUuid()`. ASP.NET has `:int`, `:guid`, `:bool`, `:min(n)`.
**Impact**: More error-prone, verbose constraint definitions.

#### 5. No Route Caching (Performance - Medium Impact)
**Current**: Routes are re-registered on every application start. Regex compiled per route on first match.
**Modern**: Laravel compiles routes to a cached file. Phoenix compiles at compile-time.
**Impact**: Slow app startup with many routes; regex compilation happens at runtime.

#### 6. No API Versioning Support (DX - Medium Impact)
**Current**: Must manually use `namespace("api").namespace("v1")...` nesting.
**Modern**: Fastify has native `Accept-Version` header support. ASP.NET has a dedicated versioning package.
**Impact**: No standardized API versioning pattern.

#### 7. No Health Check Route (Operations - Low-Medium Impact)
**Current**: Must define manually.
**Modern**: Rails 7.1+ and ASP.NET Core have built-in health check routes for Kubernetes probes.
**Impact**: Operational friction for containerized deployments.

#### 8. No Subdomain Routing (Feature - Low Impact)
**Current**: Not supported.
**Modern**: Laravel, Rails, Fastify, and ASP.NET all support subdomain-based routing.
**Impact**: Multi-tenant apps require workarounds.

---

## Modernization Recommendations

### Phase 1: Quick Wins (Non-Breaking)

#### 1.1 Add `group()` Method
A true grouping method that doesn't imply namespacing or packaging — just shared attributes.

```cfm
// New: group routes sharing middleware, prefix, or constraints
mapper()
    .group(path="api", constraints={format: "json"}, callback=function(map) {
        map.resources("users")
        map.resources("posts")
    })
.end()
```

**Implementation**: Add a `group()` method to `scoping.cfc` that delegates to `scope()` without implying package or namespace semantics.

#### 1.2 Add Typed Constraint Helpers
Convenience methods on the mapper for common constraint patterns.

```cfm
// New convenience methods
.get(name="user", pattern="users/[id]", to="users##show")
    .whereNumber("id")
    .whereAlpha("slug")
    .whereAlphaNumeric("token")
    .whereUuid("guid")
    .whereIn("status", "active,inactive,pending")
```

**Implementation**: Add chainable constraint methods to `matching.cfc` that set regex constraints on the last-registered route.

#### 1.3 Add `health()` Convenience Route

```cfm
mapper()
    .health()  // GET /health -> returns {status: "ok", timestamp: ...}
    // or
    .health(to="monitoring##check")  // custom handler
.end()
```

**Implementation**: Add to `matching.cfc` as a specialized `get()` call with a built-in default handler.

#### 1.4 Add `apiVersion()` Scoping

```cfm
mapper()
    .api(callback=function(api) {
        api.version(1, callback=function(v1) {
            v1.resources("users")
        })
        api.version(2, callback=function(v2) {
            v2.resources("users")
        })
    })
.end()
// Generates: /api/v1/users, /api/v2/users
```

**Implementation**: Add `api()` and `version()` methods that combine namespace + path prefix.

#### 1.5 Add Route Listing Utility

```cfm
// CLI or programmatic route dumping
mapper.getRoutes()  // already exists
// Add formatted output
mapper.$listRoutes()  // returns formatted table of all routes
```

**Implementation**: Enhance existing `getRoutes()` with a formatted output option.

### Phase 2: Performance (Non-Breaking)

#### 2.1 Pre-Compile All Regex at Registration Time
**Current**: `$findMatchingRoute()` lazily compiles regex on first match.
**Fix**: Compile all regex in `$addRoute()`. The `$compileRegex` call validates the regex at registration time rather than at first match. Note: the compiled Java Pattern object is NOT stored on the route struct because `Duplicate()` (used at match time) cannot reliably deep-copy Java objects across all CFML engines.

```cfc
// In $addRoute: validate regex compiles correctly (do not store the Java object)
$compileRegex(argumentCollection = arguments);
```

#### 2.2 Build a Route Lookup Index
Create a map from HTTP method → routes for that method, reducing the search space.

```cfc
// In $addRoute: index by method
if (StructKeyExists(arguments, "methods")) {
    for (method in ListToArray(arguments.methods)) {
        if (!StructKeyExists(variables.routeIndex, method)) {
            variables.routeIndex[method] = [];
        }
        ArrayAppend(variables.routeIndex[method], arguments);
    }
}
```

Then `$findMatchingRoute()` only scans routes for the current HTTP method.

#### 2.3 Static Route Fast Path
Many routes have no variables (e.g., `/login`, `/about`). These can be exact-matched via a hash map in O(1) before falling back to regex scanning.

```cfc
// In $addRoute: detect static routes
if (!Find("[", arguments.pattern)) {
    variables.staticRoutes[arguments.methods & ":" & arguments.pattern] = arguments;
}

// In $findMatchingRoute: check static routes first
local.staticKey = arguments.requestMethod & ":/" & arguments.path;
if (StructKeyExists(variables.staticRoutes, local.staticKey)) {
    return Duplicate(variables.staticRoutes[local.staticKey]);
}
```

### Phase 3: Architectural (Potentially Breaking)

#### 3.1 Route-Level Middleware
Allow attaching middleware functions or component names at the route or group level.

```cfm
mapper()
    .group(middleware="authenticate", callback=function(map) {
        map.resources("posts")
        map.group(middleware="requireAdmin", callback=function(admin) {
            admin.resources("users")
        })
    })
.end()
```

**Implementation**: Store `middleware` in the route struct. During dispatch, invoke middleware chain before calling the controller action. This would require changes to `Dispatch.cfc`.

#### 3.2 Route Model Binding
Auto-resolve route parameters to model instances, similar to Laravel.

```cfm
.resources("users")  // params.key auto-resolves to User model instance

// Or explicit binding
.get(name="user", pattern="users/[user]", to="users##show")
    .bind("user", "User")  // [user] param resolved via model("User").findByKey()
```

**Implementation**: After route matching in `$createParams()`, check for bindings and resolve model instances.

#### 3.3 Radix Tree Router (Major Refactor)
Replace linear scan with a trie/radix tree for O(log n) matching. This is the approach used by Fastify's `find-my-way` and ASP.NET Core's DFA matcher.

**Complexity**: High. Would require a complete rewrite of `$findMatchingRoute()` and a tree-building step after route registration.

**Recommendation**: Only pursue if route counts regularly exceed ~200. The method-indexed + static fast path from Phase 2 handles most real-world cases.

---

## Implementation Priority Matrix

| Change | Impact | Effort | Breaking? | Phase |
|--------|--------|--------|-----------|-------|
| `group()` method | High | Low | No | 1 |
| Typed constraints | Medium | Low | No | 1 |
| `health()` route | Medium | Low | No | 1 |
| API versioning helpers | Medium | Low | No | 1 |
| Route listing | Low | Low | No | 1 |
| Pre-compile regex | Medium | Low | No | 2 |
| Method-indexed lookup | High | Medium | No | 2 |
| Static route fast path | Medium | Medium | No | 2 |
| Route-level middleware | High | High | Yes* | 3 |
| Route model binding | Medium | Medium | No | 3 |
| Radix tree router | High | Very High | Yes* | 3 |

*Phase 3 items are additive and backward-compatible if implemented carefully, but they change dispatch behavior.

---

## Recommended Starting Point

**Implement Phase 1 + Phase 2 together.** These are all non-breaking additions that modernize the router's DX and performance without disrupting existing applications. The combined changes would bring Wheels routing significantly closer to Laravel/Rails quality while maintaining full backward compatibility.

The `group()` method and typed constraints alone address the two most frequent complaints from developers coming from other frameworks. The performance optimizations (method indexing + static fast path) can reduce route matching time by 50-80% for typical applications.

Phase 3 items (especially route-level middleware) should be considered for a major version release since they represent a philosophical shift in how middleware is managed.
