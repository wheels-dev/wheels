# Shared Models (Multi-Tenancy)

## Automatic Datasource Switching

When a tenant is active (`request.wheels.tenant` exists), every model query automatically routes to the tenant's datasource. This happens in `$performQuery()` (in `vendor/wheels/databaseAdapters/Base.cfc`):

```cfm
if (
    !variables.$sharedModel
    && arguments.dataSource == variables.dataSource
    && IsDefined("request.wheels.tenant.dataSource")
    && Len(request.wheels.tenant.dataSource)
) {
    arguments.dataSource = request.wheels.tenant.dataSource;
}
```

The override triggers only when:
1. The model is **not** shared (`$sharedModel = false`)
2. The query uses the model's default datasource (not an explicit override)
3. A tenant is active with a non-empty datasource

## `sharedModel()`

Call `sharedModel()` in a model's `config()` to exclude it from tenant datasource switching. The model always uses the application default datasource.

```cfm
// app/models/Tenant.cfc
component extends="Model" {
    function config() {
        sharedModel();
        hasMany(name="subscriptions");
    }
}
```

### How It Works
1. `sharedModel()` sets `variables.wheels.class.sharedModel = true` on the model
2. After adapter assignment in `Model.cfc`, the flag propagates: `adapter.$setSharedModel(true)`
3. `$performQuery()` checks `variables.$sharedModel` and skips the DS override

### Propagation Chain
```
Model config() → sharedModel() → wheels.class.sharedModel = true
Model $wheels() → $assignAdapter() → adapter.$setSharedModel(true)
Query time → $performQuery() → checks adapter.$sharedModel → skips override
```

## Decision Matrix

| Model | Shared? | Why |
|-------|---------|-----|
| Tenant | Yes | Central registry of all tenants |
| Plan / Subscription | Yes | Billing data in central DB |
| SystemConfig | Yes | Global app configuration |
| AuditLog (central) | Yes | Cross-tenant audit trail |
| User | Depends | Per-tenant if users belong to one tenant; shared if users span tenants |
| Product | No | Tenant-specific catalog |
| Order | No | Tenant-specific transactions |
| Invoice | No | Tenant-specific billing records |

**Rule of thumb:** If the table exists in every tenant database, don't share it. If it exists only in the central database, share it.

## Example — SaaS Model Structure

```cfm
// app/models/Tenant.cfc — SHARED (central DB)
component extends="Model" {
    function config() {
        sharedModel();
        hasMany(name="users");
        validatesPresenceOf("name,slug,dsName");
        validatesUniquenessOf(property="slug");
    }
}

// app/models/Plan.cfc — SHARED (central DB)
component extends="Model" {
    function config() {
        sharedModel();
        hasMany(name="tenants");
    }
}

// app/models/User.cfc — TENANT-SPECIFIC (per-tenant DB)
component extends="Model" {
    function config() {
        belongsTo(name="role");
        validatesPresenceOf("email,firstName");
        validatesUniquenessOf(property="email");
    }
}

// app/models/Product.cfc — TENANT-SPECIFIC (per-tenant DB)
component extends="Model" {
    function config() {
        hasMany(name="orders");
        validatesPresenceOf("name,price");
    }
}
```

## Key Files

| File | Purpose |
|------|---------|
| `vendor/wheels/model/miscellaneous.cfc` (lines 352-361) | `sharedModel()` method |
| `vendor/wheels/Model.cfc` (lines 109-112) | Propagation to adapter |
| `vendor/wheels/databaseAdapters/Base.cfc` (lines 131, 142-151) | `$sharedModel` flag, getter/setter |
| `vendor/wheels/databaseAdapters/Base.cfc` (lines 569-580) | DS override logic in `$performQuery()` |
