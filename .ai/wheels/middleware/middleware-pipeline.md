# Middleware Pipeline

## Architecture

Middleware runs at the dispatch level in `Dispatch.cfc`, wrapping controller execution. The pipeline uses nested closures (onion model) — first registered = outermost layer.

```
Dispatch.$request()
  → $buildMiddlewarePipeline()        # on $init(), from application.wheels.middleware
  → $getRouteMiddleware(params)       # per-request, from matched route
  → Pipeline.run(request, coreHandler)
      → middleware[1].handle(request, next)
          → middleware[2].handle(request, next)
              → coreHandler(request)   # controller() + processAction()
```

## Key Files

| File | Purpose |
|------|---------|
| `vendor/wheels/middleware/MiddlewareInterface.cfc` | Contract: `handle(request, next)` |
| `vendor/wheels/middleware/Pipeline.cfc` | Chains middleware via nested closures |
| `vendor/wheels/middleware/RequestId.cfc` | Adds `X-Request-Id` header + `request.wheels.requestId` |
| `vendor/wheels/middleware/Cors.cfc` | CORS headers + OPTIONS preflight |
| `vendor/wheels/middleware/SecurityHeaders.cfc` | OWASP security headers |
| `vendor/wheels/middleware/TenantResolver.cfc` | Multi-tenant resolution + datasource switching |
| `vendor/wheels/Dispatch.cfc` | `$buildMiddlewarePipeline()`, `$getRouteMiddleware()`, modified `$request()` |
| `vendor/wheels/mapper/scoping.cfc` | `middleware` param on `scope()`, parent-child merging |
| `vendor/wheels/mapper/matching.cfc` | Copies `middleware` from scope stack to matched route |
| `vendor/wheels/events/onapplicationstart.cfc` | Initializes `application.$wheels.middleware = []` |

## Pipeline.cfc Internals

`Pipeline.run(request, coreHandler)` iterates middleware in reverse, wrapping each around the next handler:

```cfm
// Build chain from inside out
local.next = arguments.coreHandler;
for (local.i = ArrayLen(variables.middleware); local.i >= 1; local.i--) {
    local.next = $wrapMiddleware(variables.middleware[local.i], local.next);
}
return local.next(arguments.request);
```

**CFML closure scoping gotcha:** `$wrapMiddleware` uses a shared `var ctx = {}` struct because closures in CFML have their own `local` scope. Writing `local.mw` inside a closure creates a new variable, not a reference to the enclosing function's `local.mw`.

```cfm
private any function $wrapMiddleware(required any mw, required any nextFn) {
    var ctx = {mw = arguments.mw, nextFn = arguments.nextFn};
    return function(required struct request) {
        return ctx.mw.handle(request = arguments.request, next = ctx.nextFn);
    };
}
```

## Registration

### Global (config/settings.cfm)

```cfm
set(middleware = [
    new wheels.middleware.RequestId(),
    new wheels.middleware.SecurityHeaders(),
    new wheels.middleware.Cors(allowOrigins="https://myapp.com")
]);
```

Accepts instances or string CFC paths (auto-instantiated with `init()`).

### Route-scoped (config/routes.cfm)

```cfm
mapper()
    .scope(path="/api", middleware=["app.middleware.ApiAuth"])
        .resources("users")
    .end()
.end();
```

Route middleware runs after global middleware. Nested scopes inherit parent middleware.

## Dispatch.cfc Integration

In `$request()`, the controller dispatch is wrapped in a `coreHandler` closure:

```cfm
local.coreHandler = function(required struct request) {
    local.ctrl = controller(name=request.params.controller, params=request.params);
    local.ctrl.processAction();
    if (local.ctrl.$performedRedirect()) {
        $location(argumentCollection=local.ctrl.getRedirect());
    }
    local.ctrl.$flashClear();
    return local.ctrl.response();
};
```

If route-scoped middleware exists, a merged pipeline (global + route) is created per-request. Otherwise the pre-built global pipeline is used.

## Request Context Struct

The `request` struct passed through middleware contains:

| Key | Description |
|-----|-------------|
| `params` | Merged URL/form/route params (same as controller `params`) |
| `route` | The matched route struct from `request.wheels.currentRoute` |
| `pathInfo` | Raw path info string |
| `method` | HTTP method (GET, POST, etc.) |

Middleware can add arbitrary keys (e.g., `request.currentUser`) for downstream access.

## Built-in Middleware Reference

### RequestId
- No constructor args
- Sets `request.wheels.requestId = CreateUUID()`
- Adds `X-Request-Id` response header

### Cors
- `allowOrigins` (default `"*"`) — comma-delimited origins
- `allowMethods` (default `"GET,POST,PUT,PATCH,DELETE,OPTIONS"`)
- `allowHeaders` (default `"Content-Type,Authorization,X-Requested-With"`)
- `allowCredentials` (default `false`)
- `maxAge` (default `86400`) — preflight cache seconds
- Short-circuits on OPTIONS with empty response

### SecurityHeaders
- `frameOptions` (default `"SAMEORIGIN"`)
- `contentTypeOptions` (default `"nosniff"`)
- `xssProtection` (default `"1; mode=block"`)
- `referrerPolicy` (default `"strict-origin-when-cross-origin"`)
- Set any to `""` to disable that header
- Runs after `next()` (post-processing pattern)

### TenantResolver
- `resolver` — closure(request) => struct `{id, dataSource, config}`; return `{}` for no-op
- `strategy` (default `"custom"`) — `"custom"`, `"header"`, or `"subdomain"`
- `headerName` (default `"X-Tenant-ID"`) — header to read when strategy is `"header"`
- Sets `request.wheels.tenant` with `$locked=true`; cleaned up in `finally` block
- See [Multi-Tenancy Configuration](../configuration/multi-tenancy.md) and [TenantResolver Reference](tenant-resolver.md)
