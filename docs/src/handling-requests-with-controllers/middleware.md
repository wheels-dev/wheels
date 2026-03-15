---
description: Use middleware to process requests before they reach your controllers — add headers, enforce CORS, reject unauthorized requests, and more.
---

# Middleware

Middleware lets you intercept and modify requests at the **dispatch level**, before a controller is even instantiated. This is different from [filters](using-filters.md), which run inside a specific controller.

Use middleware when you need logic that applies globally or to groups of routes — things like request IDs, CORS headers, security headers, rate limiting, or authentication gates.

## How It Works

Each middleware implements a simple contract: receive a `request` struct and a `next` function, do your work, then call `next(request)` to pass control down the chain. The last step in the chain is the actual controller dispatch.

```
Request → RequestId → Cors → SecurityHeaders → Controller → Response
                                                    ↑
                                              next(request)
```

This is sometimes called the "onion model" — the first middleware registered is the outermost layer.

## The Middleware Interface

Every middleware component must implement `wheels.middleware.MiddlewareInterface`:

```cfm
// vendor/wheels/middleware/MiddlewareInterface.cfc
interface {
    public string function handle(required struct request, required any next);
}
```

- **`request`** — A struct containing `params`, `route`, `pathInfo`, and `method`, plus any data added by prior middleware.
- **`next`** — A closure. Call `next(request)` to continue to the next middleware (or the controller). Skip it to short-circuit the pipeline.
- **Return value** — The response string.

## Registering Global Middleware

Register middleware in `config/settings.cfm`. They run on **every request** in the order listed:

```cfm
// config/settings.cfm
set(
    middleware = [
        new wheels.middleware.RequestId(),
        new wheels.middleware.SecurityHeaders(),
        new wheels.middleware.Cors(allowOrigins="https://myapp.com")
    ]
);
```

You can pass component instances (as above) or CFC dot-paths as strings:

```cfm
set(middleware = ["wheels.middleware.RequestId", "app.middleware.RateLimiter"]);
```

String paths are instantiated automatically with a no-arg `init()`.

## Route-Scoped Middleware

Attach middleware to specific route groups using the `middleware` argument on `scope()`:

```cfm
// config/routes.cfm
mapper()
    .scope(path="/api", middleware=[new app.middleware.ApiAuth()])
        .resources("users")
        .resources("products")
    .end()
    .resources("pages")  // no ApiAuth middleware here
.end();
```

Route-scoped middleware runs **after** global middleware. Scopes nest — child scopes inherit and append to parent middleware:

```cfm
mapper()
    .scope(path="/api", middleware=["app.middleware.ApiAuth"])
        .scope(path="/admin", middleware=["app.middleware.AdminOnly"])
            .resources("settings")  // runs: global → ApiAuth → AdminOnly
        .end()
        .resources("users")         // runs: global → ApiAuth
    .end()
.end();
```

## Built-in Middleware

Wheels ships with three middleware components you can use immediately.

### RequestId

Assigns a unique UUID to every request for tracing and debugging.

- Sets `request.wheels.requestId`
- Adds `X-Request-Id` response header

```cfm
set(middleware = [new wheels.middleware.RequestId()]);
```

### SecurityHeaders

Adds OWASP-recommended security headers to every response.

| Header | Default |
|--------|---------|
| `X-Frame-Options` | `SAMEORIGIN` |
| `X-Content-Type-Options` | `nosniff` |
| `X-XSS-Protection` | `1; mode=block` |
| `Referrer-Policy` | `strict-origin-when-cross-origin` |

```cfm
// Use defaults
set(middleware = [new wheels.middleware.SecurityHeaders()]);

// Customize
set(middleware = [
    new wheels.middleware.SecurityHeaders(
        frameOptions = "DENY",
        referrerPolicy = "no-referrer"
    )
]);
```

Set any parameter to an empty string to disable that header.

### Cors

Handles Cross-Origin Resource Sharing headers and OPTIONS preflight requests.

```cfm
set(middleware = [
    new wheels.middleware.Cors(
        allowOrigins = "https://myapp.com,https://admin.myapp.com",
        allowMethods = "GET,POST,PUT,DELETE",
        allowHeaders = "Content-Type,Authorization",
        allowCredentials = true,
        maxAge = 86400
    )
]);
```

| Parameter | Default | Description |
|-----------|---------|-------------|
| `allowOrigins` | `"*"` | Comma-delimited list of allowed origins |
| `allowMethods` | `"GET,POST,PUT,PATCH,DELETE,OPTIONS"` | Allowed HTTP methods |
| `allowHeaders` | `"Content-Type,Authorization,X-Requested-With"` | Allowed request headers |
| `allowCredentials` | `false` | Whether to allow cookies/auth headers |
| `maxAge` | `86400` | Preflight cache duration in seconds |

For simple CORS needs, you may prefer the existing [CORS Requests](cors-requests.md) guide which covers header-only approaches.

### TenantResolver

Resolves the current tenant from the incoming request and sets `request.wheels.tenant` for automatic per-request datasource switching. Supports three resolution strategies.

| Parameter | Default | Description |
|-----------|---------|-------------|
| `resolver` | `""` | Closure that receives the request struct and returns a tenant struct (`{id, dataSource, config}`). Return `{}` for unrecognized tenants. |
| `strategy` | `"custom"` | Resolution strategy: `"custom"`, `"header"`, or `"subdomain"` |
| `headerName` | `"X-Tenant-ID"` | HTTP header to read when strategy is `"header"` |

```javascript
set(middleware = [
    new wheels.middleware.TenantResolver(
        resolver = function(req) {
            var t = model("Tenant").findOne(where="domain='#cgi.server_name#'");
            if (IsObject(t)) return {id: t.id, dataSource: t.dsName};
            return {};
        }
    )
]);
```

The middleware locks the tenant for the duration of the request and cleans up automatically. All model queries are transparently routed to the tenant's datasource (except models marked with `sharedModel()`).

For the full multi-tenancy guide — including shared models, tenant migrations, and background jobs — see [Multi-Tenancy](../working-with-wheels/multi-tenancy.md).

## Writing Custom Middleware

Create a CFC that implements `wheels.middleware.MiddlewareInterface`:

```cfm
// app/middleware/RateLimiter.cfc
component implements="wheels.middleware.MiddlewareInterface" output="false" {

    public RateLimiter function init(numeric maxRequests = 100) {
        variables.maxRequests = arguments.maxRequests;
        return this;
    }

    public string function handle(required struct request, required any next) {
        // Check rate limit (pseudo-code)
        local.clientIp = cgi.remote_addr;
        if ($isRateLimited(local.clientIp)) {
            cfheader(statusCode="429", statusText="Too Many Requests");
            return "Rate limit exceeded. Try again later.";
        }

        // Continue to next middleware / controller
        return arguments.next(arguments.request);
    }

    private boolean function $isRateLimited(required string ip) {
        // Your rate limiting logic here
        return false;
    }

}
```

### Patterns

**Enrich the request** — add data for downstream middleware or the controller:

```cfm
public string function handle(required struct request, required any next) {
    arguments.request.currentUser = $lookupUser();
    return arguments.next(arguments.request);
}
```

**Short-circuit** — return a response without calling `next()`:

```cfm
public string function handle(required struct request, required any next) {
    if (!$isAuthenticated(arguments.request)) {
        cfheader(statusCode="401");
        return "Unauthorized";
    }
    return arguments.next(arguments.request);
}
```

**Post-process** — modify the response after the controller runs:

```cfm
public string function handle(required struct request, required any next) {
    local.startTick = GetTickCount();
    local.response = arguments.next(arguments.request);
    local.elapsed = GetTickCount() - local.startTick;
    cfheader(name="X-Response-Time", value="#local.elapsed#ms");
    return local.response;
}
```

## Middleware vs. Filters

| | Middleware | Filters |
|---|---|---|
| **Runs at** | Dispatch level (before controller) | Controller level (inside controller) |
| **Scope** | Global or route group | Single controller |
| **Access to** | Request struct, response string | Controller instance, `params`, views |
| **Best for** | Cross-cutting concerns (auth, headers, logging) | Controller-specific logic (load record, check permissions) |

Both can coexist. A typical setup might use middleware for security headers and request IDs globally, then filters for loading specific records inside individual controllers.
