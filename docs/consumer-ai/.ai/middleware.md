# Middleware Quick Reference

Part of the Wheels application guide; start with `../CLAUDE.md`.

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

Built-in: `wheels.middleware.RequestId`, `wheels.middleware.Cors`, `wheels.middleware.SecurityHeaders`, `wheels.middleware.RateLimiter`, `wheels.middleware.AuthMiddleware` (authenticate + attach the result; with no `authenticator` passed it uses the DI container's `authenticator`, which `wheels generate auth` registers; the 401 body is `{"error": ..., "status": 401}`, and `genericErrors=true` emits a generic `Unauthorized` message instead of `authResult.error`), `wheels.middleware.TenantResolver` (resolve the active tenant; `failClosed=true` 403s unmatched tenants instead of proceeding on the default datasource). Custom: implement `wheels.middleware.MiddlewareInterface`, place in `app/middleware/`.

A controller reads what middleware attached to the request: the `AuthMiddleware` result as `request.auth` (`success`, `principal`, `strategy`; with `allowAnonymous=true` a failed result is there too), and the whole middleware context as `request.wheels.middlewareContext`.

**Singleton lifecycle contract**: both global and route-scoped middleware (including string-path entries) are resolved once and cached for the application lifetime. The same instance handles every matching request — stateful middleware (e.g. in-memory `RateLimiter` on a `.scope()`) accumulates state across requests as intended. Implication: every middleware component must be safe to share across concurrent requests (use CFML locks for any mutable state).

## Rate Limiting

```cfm
new wheels.middleware.RateLimiter()                                            // fixed window, 60 req / 60s
new wheels.middleware.RateLimiter(maxRequests=100, windowSeconds=120, strategy="slidingWindow")
new wheels.middleware.RateLimiter(maxRequests=50, windowSeconds=60, strategy="tokenBucket")
new wheels.middleware.RateLimiter(storage="database")                          // auto-creates wheels_rate_limits
// rate-limit per API key — hoist the closure first: an inline function literal
// as a constructor named arg crashes Adobe CF's compiler
var apiKeyFn = function(req) {
    var apiKey = req.cgi.http_x_api_key ?: "";
    return Len(apiKey) ? apiKey : "anonymous";
};
new wheels.middleware.RateLimiter(keyFunction=apiKeyFn)
```

The `keyFunction` receives the dispatch middleware context `{params, route, pathInfo, method, cgi}`. The `cgi` member is the sanitized `request.cgi` copy overlaid on every inbound HTTP header under its CGI-style `http_*` name (built by `Dispatch.$buildMiddlewareCgiScope()`), so arbitrary headers like `X-Api-Key` resolve per client. Keep the `Len()` guard: a missing or empty-valued header reads as an empty string, and returning it would put every such client in one bucket.

Strategies: `fixedWindow` (default), `slidingWindow`, `tokenBucket`. Storage: `memory` or `database`. Emits `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`. Returns `429` with `Retry-After` when exceeded.

`windowSeconds` must be > 0; `maxRequests` must be >= 0. Invalid values throw `Wheels.RateLimiter.InvalidConfiguration` at construction. `maxRequests = 0` is a valid kill-switch.
