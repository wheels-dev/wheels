---
description: Build multi-tenant applications with per-request datasource switching, tenant resolution strategies, and shared models.
---

# Multi-Tenancy

Wheels supports **database-per-tenant** multi-tenancy out of the box. Each tenant gets its own datasource, and Wheels automatically routes all model queries to the correct database based on the current request. No changes to your controllers, views, or existing models are needed.

## What is Multi-Tenancy?

Multi-tenancy is an architecture where a single application serves multiple customers (tenants), each with isolated data. Wheels implements the **database-per-tenant** model: every tenant has a separate database, and the framework switches datasources transparently on each request.

This gives you strong data isolation — a bug in your query code can't accidentally leak data across tenants because they're in completely separate databases.

## Quick Start

Setting up multi-tenancy takes three steps:

### 1. Add the TenantResolver Middleware

{% code title="config/settings.cfm" %}
```javascript
set(middleware = [
    new wheels.middleware.TenantResolver(
        resolver = function(req) {
            // Look up the tenant from the subdomain
            var slug = ListFirst(cgi.server_name, ".");
            var t = model("Tenant").findOne(where="slug='#slug#'");
            if (IsObject(t)) {
                return {id: t.id, dataSource: t.dsName};
            }
            return {};  // No tenant found — use default datasource
        }
    )
]);
```
{% endcode %}

### 2. Create a Shared Tenant Model

Your `Tenant` model lives in the central database, not in tenant databases, so mark it as shared:

{% code title="app/models/Tenant.cfc" %}
```javascript
component extends="Model" {
    function config() {
        sharedModel();  // Always use the default datasource
        validatesPresenceOf("name,slug,dsName");
        validatesUniquenessOf(property="slug");
    }
}
```
{% endcode %}

### 3. That's It

Your existing models automatically use the tenant's datasource. No changes needed:

```javascript
// This query runs against the tenant's database automatically
users = model("User").findAll(order="lastName");
```

## Choosing a Resolution Strategy

TenantResolver supports three strategies for identifying which tenant a request belongs to.

### Custom (Default)

Your resolver closure has full control. This is the most flexible approach and works for any identification method — domain lookup, session value, URL parameter, etc.

{% code title="config/settings.cfm" %}
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
{% endcode %}

**Use when:** You need full control over tenant identification, or your logic doesn't fit the header/subdomain patterns.

### Header

Reads a tenant identifier from an HTTP header. This is common when an API gateway or reverse proxy sets the tenant header before the request reaches your application.

{% code title="config/settings.cfm" %}
```javascript
set(middleware = [
    new wheels.middleware.TenantResolver(
        strategy = "header",
        headerName = "X-Tenant-ID",
        resolver = function(req) {
            // The header value is available via the CGI scope
            var tenantId = req.cgi.http_x_tenant_id;
            var t = model("Tenant").findOne(where="externalId='#tenantId#'");
            if (IsObject(t)) return {id: t.id, dataSource: t.dsName};
            return {};
        }
    )
]);
```
{% endcode %}

**Use when:** A gateway, load balancer, or reverse proxy identifies the tenant and passes it via header.

### Subdomain

Extracts the first subdomain segment from the hostname. For example, `acme.myapp.com` yields `"acme"`. The resolver only fires when there are at least 3 domain segments.

{% code title="config/settings.cfm" %}
```javascript
set(middleware = [
    new wheels.middleware.TenantResolver(
        strategy = "subdomain",
        resolver = function(req) {
            // req.$tenantSubdomain is pre-populated by the strategy
            var slug = req.$tenantSubdomain;
            var t = model("Tenant").findOne(where="slug='#slug#'");
            if (IsObject(t)) return {id: t.id, dataSource: t.dsName};
            return {};
        }
    )
]);
```
{% endcode %}

**Use when:** Each tenant has a unique subdomain (e.g., `acme.myapp.com`, `globex.myapp.com`).

{% hint style="info" %}
Both the header and subdomain strategies pre-populate the extracted value on the request struct before calling your resolver: `req.$tenantHeaderValue` for header strategy, `req.$tenantSubdomain` for subdomain strategy. This saves you from re-extracting the value yourself.
{% endhint %}

## Shared Models

Most of your models will be tenant-specific — their tables exist in each tenant's database. But some models belong in the central database: the `Tenant` model itself, billing plans, global configuration, etc.

Call `sharedModel()` in any model that should always use the default application datasource:

{% code title="app/models/Plan.cfc" %}
```javascript
component extends="Model" {
    function config() {
        sharedModel();
        hasMany(name="tenants");
        validatesPresenceOf("name,price");
    }
}
```
{% endcode %}

### Which Models to Share?

| Share | Don't Share |
|-------|------------|
| Tenant registry | Users (per-tenant) |
| Billing plans | Products |
| Global config | Orders, invoices |
| Cross-tenant audit log | Tenant-specific data |

**Rule of thumb:** If the table exists only in the central database, call `sharedModel()`. If it exists in every tenant database, don't.

{% hint style="warning" %}
Don't `include` a shared model from a tenant model in a `findAll()` call if they're in different databases. Wheels uses the calling model's datasource for the entire query, including JOINs.
{% endhint %}

## Accessing Tenant Info

### `tenant()`

Returns the current tenant struct, or an empty struct if no tenant is active:

```javascript
// In a controller or view
if (!StructIsEmpty(tenant())) {
    writeOutput("Welcome, tenant #tenant().id#!");
}
```

The struct contains: `id`, `dataSource`, `config`, and `$locked`.

### Checking if a Tenant is Active

```javascript
// Simple check
if (StructKeyExists(tenant(), "id")) {
    // tenant is active
}

// Or check for empty struct
if (!StructIsEmpty(tenant())) {
    // tenant is active
}
```

## Switching Tenants

The TenantResolver locks the tenant for the duration of the request to prevent accidental switching. If you need to switch tenants mid-request (e.g., for admin cross-tenant operations), use `switchTenant()` with `force=true`:

```javascript
// In an admin controller
function copyProduct() {
    // Read from current tenant
    product = model("Product").findByKey(params.key);

    // Switch to target tenant
    switchTenant(
        tenant = {id: params.targetTenantId, dataSource: params.targetDs},
        force = true
    );

    // Save to target tenant's database
    model("Product").create(name=product.name, price=product.price);
}
```

{% hint style="info" %}
Without `force=true`, calling `switchTenant()` when a tenant is locked throws a `Wheels.TenantLocked` error. This is a safety feature — most code should never need to switch tenants.
{% endhint %}

## Per-Tenant Configuration

You can override application settings on a per-tenant basis by including a `config` struct in the tenant:

```javascript
// In your resolver
return {
    id: t.id,
    dataSource: t.dsName,
    config: {
        appName: t.companyName,
        perPage: t.defaultPageSize,
        showDebugOutput: false
    }
};
```

Any call to `get("appName")` during that request returns the tenant's value instead of the application default. This works for any non-function-scoped setting.

{% hint style="warning" %}
**Security-sensitive settings cannot be overridden per-tenant.** The following settings are protected: `encryptionAlgorithm`, `encryptionSecretKey`, `encryptionEncoding`, `CSRFProtection`, `csrfStore`, `reloadPassword`, `obfuscateUrls`. Attempts to override these via tenant config are silently ignored.
{% endhint %}

## Multi-Tenant Migrations

When you need to run database migrations across all tenant databases, use `TenantMigrator`:

{% code title="Migrate all tenants" %}
```javascript
var tm = new wheels.migrator.TenantMigrator();

// With a static list
var results = tm.migrateAll(
    action = "latest",
    tenants = [
        {id: "acme", dataSource: "acme_ds"},
        {id: "globex", dataSource: "globex_ds"}
    ]
);

// Or with a dynamic provider
var results = tm.migrateAll(
    action = "latest",
    tenantProvider = function() {
        return model("Tenant").findAll(returnAs="structs", select="id, dsName AS dataSource");
    }
);
```
{% endcode %}

The result struct tells you what succeeded and what failed:

```javascript
// results.success = [{tenant: "acme", dataSource: "acme_ds", output: "..."}, ...]
// results.failed = [{tenant: "initech", dataSource: "initech_ds", error: "..."}, ...]
// results.total = 3
```

By default, migration stops on the first error. Pass `stopOnError=false` to continue migrating remaining tenants.

## Multi-Tenant Background Jobs

Jobs automatically capture the current tenant context when enqueued and restore it before `perform()` runs. No extra code needed:

```javascript
// Enqueued within a tenant request — tenant context is captured automatically
job = new app.jobs.GenerateInvoiceJob();
job.enqueue(data={userId: user.id});
```

When the job processes later (possibly on a different server or outside a web request), it restores the original tenant context so all model queries run against the correct tenant database.

{% hint style="info" %}
The tenant context is stored in the job's data as `$wheelsTenantContext` and automatically removed before your `perform()` method receives the data struct.
{% endhint %}

## Complete Example

Here's a full SaaS application setup using subdomain-based tenant resolution:

{% code title="config/settings.cfm" %}
```javascript
set(middleware = [
    new wheels.middleware.RequestId(),
    new wheels.middleware.SecurityHeaders(),
    new wheels.middleware.TenantResolver(
        strategy = "subdomain",
        resolver = function(req) {
            var slug = ListFirst(cgi.server_name, ".");
            var t = model("Tenant").findOne(where="slug='#slug#'");
            if (IsObject(t)) {
                return {
                    id: t.id,
                    dataSource: t.dsName,
                    config: {appName: t.companyName}
                };
            }
            return {};
        }
    )
]);
```
{% endcode %}

{% code title="app/models/Tenant.cfc" %}
```javascript
component extends="Model" {
    function config() {
        sharedModel();
        belongsTo(name="plan");
        hasMany(name="users");
        validatesPresenceOf("name,slug,dsName");
        validatesUniquenessOf(property="slug");
    }
}
```
{% endcode %}

{% code title="app/models/Plan.cfc" %}
```javascript
component extends="Model" {
    function config() {
        sharedModel();
        hasMany(name="tenants");
    }
}
```
{% endcode %}

{% code title="app/models/User.cfc" %}
```javascript
component extends="Model" {
    function config() {
        // No sharedModel() — this table is in each tenant's database
        belongsTo(name="role");
        validatesPresenceOf("email,firstName,lastName");
        validatesUniquenessOf(property="email");
    }
}
```
{% endcode %}

{% code title="app/controllers/Users.cfc" %}
```javascript
component extends="Controller" {

    function index() {
        // Automatically queries the current tenant's database
        users = model("User").findAll(order="lastName", page=params.page, perPage=25);
    }

    function show() {
        user = model("User").findByKey(params.key);
    }

}
```
{% endcode %}

The controllers don't need any tenant-awareness — Wheels handles the datasource switching transparently.
