# Multi-Tenancy

## Quick Reference

### Tenant Struct Shape
```cfm
request.wheels.tenant = {
    id: "acme",                    // string — tenant identifier
    dataSource: "acme_ds",         // string — CFML datasource name (required)
    config: {appName: "Acme Co"}, // struct — per-tenant setting overrides
    $locked: true                  // boolean — set by middleware, prevents mid-request switching
};
```

### Helper Functions

| Function | Returns | Description |
|----------|---------|-------------|
| `tenant()` | struct | Current tenant struct, or `{}` if none active |
| `$tenantDataSource()` | string | Tenant datasource, or app default if none active |
| `switchTenant(tenant, force)` | void | Switch tenant mid-request; throws `Wheels.TenantLocked` if locked unless `force=true` |

### Minimal Setup
```cfm
// config/settings.cfm
set(middleware = [
    new wheels.middleware.TenantResolver(
        resolver = function(req) {
            var t = model("Tenant").findOne(where="slug='#ListFirst(cgi.server_name, '.')#'");
            if (IsObject(t)) return {id: t.id, dataSource: t.dsName};
            return {};
        }
    )
]);
```

## Architecture

### Request Flow
```
HTTP Request
  → TenantResolver.handle()
      → $resolveTenant() via strategy (custom/header/subdomain)
      → Sets request.wheels.tenant (with $locked=true)
      → next(request) — controller dispatch
          → model("X").findAll()
              → $performQuery() checks request.wheels.tenant.dataSource
              → Query runs against tenant DS (unless sharedModel)
      → finally: StructDelete(request.wheels, "tenant")
```

### Database-Per-Tenant Model
Each tenant gets its own database (or datasource). All models automatically route queries to the active tenant's datasource. Models marked with `sharedModel()` bypass this and always use the application default datasource.

### The `$locked` Flag
TenantResolver sets `$locked = true` to prevent accidental mid-request tenant switching. `switchTenant()` respects this flag unless called with `force=true`. This ensures queries within a single request are consistent.

## Setup — Resolution Strategies

### Custom Strategy (Default)
Full control — your closure receives the request struct and returns a tenant struct.

```cfm
set(middleware = [
    new wheels.middleware.TenantResolver(
        resolver = function(req) {
            var slug = ListFirst(cgi.server_name, ".");
            var t = model("Tenant").findOne(where="slug='#slug#'");
            if (IsObject(t)) return {
                id: t.id,
                dataSource: t.dsName,
                config: {appName: t.name, rewriteUrls: t.customDomain}
            };
            return {};
        }
    )
]);
```

### Header Strategy
Reads tenant identifier from an HTTP header. Requires a resolver to map the header value to a tenant struct.

```cfm
set(middleware = [
    new wheels.middleware.TenantResolver(
        strategy = "header",
        headerName = "X-Tenant-ID",
        resolver = function(req) {
            var tenantId = req.cgi.http_x_tenant_id;
            var t = model("Tenant").findOne(where="externalId='#tenantId#'");
            if (IsObject(t)) return {id: t.id, dataSource: t.dsName};
            return {};
        }
    )
]);
```

The header name is normalized to CGI format: `X-Tenant-ID` → `http_x_tenant_id`.

### Subdomain Strategy
Extracts the first subdomain segment from `cgi.server_name`. Requires at least 3 domain segments (e.g., `acme.myapp.com`). Pass a resolver to map the subdomain to a tenant struct.

```cfm
set(middleware = [
    new wheels.middleware.TenantResolver(
        strategy = "subdomain",
        resolver = function(req) {
            var subdomain = ListFirst(cgi.server_name, ".");
            var t = model("Tenant").findOne(where="subdomain='#subdomain#'");
            if (IsObject(t)) return {id: t.id, dataSource: t.dsName};
            return {};
        }
    )
]);
```

Without a resolver, the subdomain strategy returns `{}` (no-op). The strategy determines *when* the resolver fires (only when subdomain conditions are met), while the resolver does the actual lookup.

## Shared Models

Models that live in a central database (not per-tenant) should call `sharedModel()` in their `config()`. See [Shared Models](../models/shared-models.md) for details.

```cfm
// app/models/Tenant.cfc
component extends="Model" {
    function config() {
        sharedModel();
        hasMany(name="users");
    }
}
```

## Per-Tenant Config Overrides

Include a `config` struct in the tenant to override application settings on a per-tenant basis. These keys take precedence over `$get()` for non-function settings.

```cfm
// In your resolver
return {
    id: t.id,
    dataSource: t.dsName,
    config: {
        appName: t.companyName,
        showDebugOutput: false,
        perPage: 50
    }
};
```

Any call to `get("appName")` during that request returns the tenant-specific value instead of the application default. Function-scoped settings (e.g., `get(name="x", functionName="findAll")`) are not overridden.

**Security denylist**: The following settings cannot be overridden per-tenant: `encryptionAlgorithm`, `encryptionSecretKey`, `encryptionEncoding`, `CSRFProtection`, `csrfStore`, `reloadPassword`, `obfuscateUrls`. Attempts to override these are silently ignored.

## Accessing Tenant Context

### `tenant()`
Returns the current tenant struct, or `{}` if no tenant is active.

```cfm
// In a controller or view
if (!StructIsEmpty(tenant())) {
    writeOutput("Current tenant: #tenant().id#");
}
```

### `$tenantDataSource()`
Returns the current tenant's datasource name, or the application default if no tenant is active.

```cfm
var ds = $tenantDataSource(); // "acme_ds" or application default
```

### `switchTenant()`
Switches the active tenant mid-request. Throws `Wheels.TenantLocked` if the current tenant was set by middleware, unless `force=true`.

```cfm
// Switch to a different tenant (e.g., for admin cross-tenant operations)
switchTenant(tenant={id: "other", dataSource: "other_ds"}, force=true);
```

Throws `Wheels.InvalidTenant` if the struct is missing a `dataSource` key.

## Gotchas

1. **Resolver must return `dataSource`** — If the returned struct has no `dataSource` key (or it's empty), no tenant context is set. The request proceeds with the application default datasource.

2. **Empty struct = no tenant** — Return `{}` from your resolver for unrecognized tenants. Don't throw — let the request proceed tenant-free.

3. **Shared models need explicit marking** — Any model that lives in the central database must call `sharedModel()`. Without it, the model's queries route to the tenant datasource and may fail if the table doesn't exist there.

4. **Associations don't cross datasources** — The calling model's datasource is used for the entire query, including JOINs. Don't `include` a shared model from a tenant model if they're in different databases.

5. **`$locked` prevents switching** — `switchTenant()` throws unless you pass `force=true`. This is intentional — mid-request switching can cause data inconsistencies.

6. **Cleanup is automatic** — TenantResolver uses a `finally` block to remove `request.wheels.tenant` after each request, even on errors.

7. **Config overrides are non-function only** — `tenant.config` keys override `$get(name)` but not `$get(name, functionName)`. Function-scoped defaults remain unchanged.

## Key Files

| File | Purpose |
|------|---------|
| `vendor/wheels/middleware/TenantResolver.cfc` | Middleware — resolves tenant per request |
| `vendor/wheels/Global.cfc` (lines 467-542) | `tenant()`, `$tenantDataSource()`, `switchTenant()` |
| `vendor/wheels/Global.cfc` (lines 425-443) | `$get()` — per-tenant config override logic |
| `vendor/wheels/databaseAdapters/Base.cfc` (lines 569-580) | `$performQuery()` — DS override |
| `vendor/wheels/databaseAdapters/Base.cfc` (lines 131-151) | `$sharedModel` flag on adapter |
| `vendor/wheels/model/miscellaneous.cfc` (lines 352-361) | `sharedModel()` config method |
| `vendor/wheels/Model.cfc` (lines 109-112) | Propagates sharedModel flag to adapter |
| `vendor/wheels/migrator/TenantMigrator.cfc` | Runs migrations across tenant datasources |
| `vendor/wheels/Job.cfc` (lines 135-145, 272-294) | Job tenant context capture/restore |
