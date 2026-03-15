# TenantResolver Middleware — AI Reference

## Constructor API

```cfm
new wheels.middleware.TenantResolver(
    resolver = "",           // closure(request) => struct {id, dataSource, config} — or empty for no-op
    strategy = "custom",     // string — "custom" | "header" | "subdomain"
    headerName = "X-Tenant-ID" // string — header to read when strategy="header"
)
```

The `resolver` closure receives the middleware request struct and must return a struct with at minimum a `dataSource` key. Return `{}` for unrecognized tenants.

## Resolution Strategies

### Custom (Default)
Delegates entirely to the resolver closure. If no resolver is provided, returns `{}` (no tenant set).

### Header
1. Normalizes `headerName` to CGI format: `X-Tenant-ID` → `http_x_tenant_id`
2. Reads from `request.cgi[headerKey]` or falls back to `cgi[headerKey]`
3. If empty, returns `{}`
4. If resolver provided, calls `resolver(request)` and returns result
5. Without resolver, returns `{}` (header alone is not enough — no datasource)

### Subdomain
1. Reads `server_name` from `request.cgi` or `cgi` scope
2. If fewer than 3 domain segments, returns `{}` (e.g., `myapp.com` has no subdomain)
3. Extracts first segment: `acme.myapp.com` → `"acme"`
4. If resolver provided, calls `resolver(request)` and returns result
5. Without resolver, returns `{}`

## Method Inventory

| Method | Visibility | Purpose |
|--------|-----------|---------|
| `init(resolver, strategy, headerName)` | public | Constructor — stores config |
| `handle(request, next)` | public | MiddlewareInterface — resolve → set → next → cleanup |
| `$resolveTenant(request)` | private | Dispatches to strategy-specific method |
| `$resolveFromCustom(request)` | private | Calls resolver closure directly |
| `$resolveFromHeader(request)` | private | Reads header, then calls resolver |
| `$resolveFromSubdomain(request)` | private | Extracts subdomain, then calls resolver |

## Tenant Lifecycle

### Set Phase (in `handle()`)
1. Call `$resolveTenant(request)` → returns struct
2. Validate: must be non-empty struct with a non-empty `dataSource` key
3. Default missing keys: `id=""`, `config={}`
4. Set `$locked = true` to prevent mid-request switching
5. Assign to `request.wheels.tenant` (the built-in `request` scope, not `arguments.request`)

### Cleanup Phase (in `finally` block)
- Always runs, even on errors
- Removes `request.wheels.tenant` via `StructDelete(request.wheels, "tenant")`
- Ensures no tenant leakage between requests

### Scope Note
CFML's `request` keyword always refers to the built-in request scope, even inside a function with a parameter named `request`. The middleware uses `arguments.request` for the pipeline struct but sets tenant state on the bare `request` scope, because that's what `$performQuery()` and `$get()` read from.

## Usage Patterns

### Database Lookup (Most Common)
```cfm
new wheels.middleware.TenantResolver(
    resolver = function(req) {
        var host = cgi.server_name;
        var t = model("Tenant").findOne(where="domain='#host#'");
        if (IsObject(t)) return {id: t.id, dataSource: t.dsName, config: {appName: t.name}};
        return {};
    }
)
```

### API Gateway with Header
```cfm
new wheels.middleware.TenantResolver(
    strategy = "header",
    headerName = "X-Tenant-ID",
    resolver = function(req) {
        var tenantId = req.cgi.http_x_tenant_id;
        var ds = application.tenantMap[tenantId] ?: "";
        if (Len(ds)) return {id: tenantId, dataSource: ds};
        return {};
    }
)
```

### SaaS Subdomain
```cfm
new wheels.middleware.TenantResolver(
    strategy = "subdomain",
    resolver = function(req) {
        var slug = ListFirst(cgi.server_name, ".");
        var t = model("Tenant").findOne(where="slug='#slug#'");
        if (IsObject(t)) return {id: t.id, dataSource: t.dsName};
        return {};
    }
)
```

### Route-Scoped (Tenant Only for API)
```cfm
// config/routes.cfm
mapper()
    .scope(path="/api", middleware=[
        new wheels.middleware.TenantResolver(
            strategy="header",
            headerName="X-Tenant-ID",
            resolver=myResolverFunction
        )
    ])
        .resources("users")
        .resources("products")
    .end()
    .resources("pages")  // no tenant resolution here
.end();
```

## Key File

`vendor/wheels/middleware/TenantResolver.cfc` — 172 lines, implements `wheels.middleware.MiddlewareInterface`.
