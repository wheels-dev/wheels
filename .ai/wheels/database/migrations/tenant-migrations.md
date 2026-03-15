# Tenant Migrations

## Description

`TenantMigrator` runs the standard Wheels migrator against multiple tenant datasources in sequence. It temporarily sets `request.wheels.tenant` for each tenant so the migration uses the correct datasource.

## `migrateAll()` API

```cfm
var tm = new wheels.migrator.TenantMigrator();
var results = tm.migrateAll(
    action = "latest",           // string — "latest", "up", "down", or "info"
    tenants = [],                // array of structs — static tenant list
    tenantProvider = function(){},// closure — returns array of tenant structs (used if tenants is empty)
    stopOnError = true           // boolean — stop on first failure (default: true)
);
```

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `action` | string | `"latest"` | Migration action to perform |
| `tenants` | array | `[]` | Static list of tenant structs (each needs `dataSource`, optionally `id` and `config`) |
| `tenantProvider` | closure | — | Called when `tenants` is empty; must return array of tenant structs |
| `stopOnError` | boolean | `true` | If true, stops iterating on first failure |

### Return Struct

```cfm
{
    success: [
        {tenant: "acme", dataSource: "acme_ds", output: "..."},
        {tenant: "globex", dataSource: "globex_ds", output: "..."}
    ],
    failed: [
        {tenant: "initech", dataSource: "initech_ds", error: "Table already exists"}
    ],
    total: 3
}
```

## Static vs Dynamic Tenant Lists

### Static List
```cfm
var results = tm.migrateAll(
    action = "latest",
    tenants = [
        {id: "acme", dataSource: "acme_ds"},
        {id: "globex", dataSource: "globex_ds"}
    ]
);
```

### Dynamic Provider
```cfm
var results = tm.migrateAll(
    action = "latest",
    tenantProvider = function() {
        return model("Tenant").findAll(returnAs="structs", select="id, dsName AS dataSource");
    }
);
```

The provider closure is called once at the start. Use this when tenants are stored in a database and the list changes over time.

## Error Handling

### `stopOnError = true` (Default)
Stops iterating on the first tenant that fails. Already-succeeded tenants are not rolled back. The `failed` array contains at most one entry.

### `stopOnError = false`
Continues to all remaining tenants. Collects all errors in the `failed` array. Use this for "migrate as many as possible" scenarios.

### Validation
Tenant structs without a `dataSource` key (or with an empty value) are added to `failed` with error: `"Tenant struct missing required 'dataSource' key"`.

## How It Works Internally

For each tenant:
1. Set `request.wheels.tenant` to the tenant context
2. Call `$createMigrator(dataSource)`:
   - Temporarily set `application.wheels.dataSourceName` to tenant's datasource
   - Instantiate `wheels.migrator.Migrator()` (picks up the temporary DS)
   - Restore original `application.wheels.dataSourceName`
3. Call `migrator.migrate(action)` — runs against tenant DS
4. On success, append to `results.success`
5. On failure, append to `results.failed`; break if `stopOnError`
6. Always clean up `request.wheels.tenant` in `finally` block

## Key File

`vendor/wheels/migrator/TenantMigrator.cfc` — 136 lines.
