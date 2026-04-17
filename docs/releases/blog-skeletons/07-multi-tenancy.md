---
status: skeleton
slot: post 7 (week 3; SaaS-audience focus)
target_length: 900–1200 words
---

# Multi-Tenancy Built In

**Subhead / dek:** *Per-request datasource switching in core — no gem, no package, no plugin. And tenant-aware background jobs come along for the ride.*

**Target audience:**
- SaaS founders and architects evaluating CFML frameworks for a multi-tenant product
- Existing Wheels teams who've been rolling their own tenant switching via `application.wheels.dataSourceName = ...`
- Rails/Laravel/Django devs curious what "built-in multi-tenancy" actually looks like

**Lead paragraph intent:**
- Multi-tenancy in Rails is `apartment` gem. In Laravel it's `stancl/tenancy`. In Django it's `django-tenants`. In Wheels 4.0 it's *the framework*.
- That sounds boastful — but the practical difference is real: tenant resolution, datasource switching, and tenant-aware job queues are one coherent system, not three plugins duct-taped together.
- PR [#1951](https://github.com/wheels-dev/wheels/pull/1951) landed the core. This post walks a realistic SaaS scenario to show why that matters.

## Sections

### 1. "The seam you need to cut cleanly"
- Multi-tenancy is a seam problem, not a feature problem. You need *one* seam that catches every query, every job, every background task.
- Plugin-based multi-tenancy catches 80% — then a stray `cfquery` or a job that forgot to resolve tenant context leaks data across tenants. That's a "write the incident report on Sunday" bug.
- Framework-level tenancy catches 100% because every data path goes through the datasource resolver.

### 2. Three models, one framework
- **Separate database per tenant** — cleanest isolation, per-customer backup/restore. Wheels 4.0 supports it via datasource switching.
- **Shared database, separate schema** — supported via datasource naming that points to the same DB but different schema.
- **Shared database, row-level** — scoped queries. Less cleanly isolated but fine for many products. (Note: this model requires discipline regardless of framework.)

### 3. Tenant resolution — from request to datasource
- Typical sources: subdomain (`acme.myapp.com`), path prefix (`/t/acme`), header (`X-Tenant: acme`), auth claim (JWT `tid`).
- Resolution happens early — as middleware — and stores the tenant context on the request.
- Models pick up the datasource automatically for the rest of the request lifecycle.

### 4. Tenant-aware background jobs
- Enqueue from tenant A's request context → job lands in tenant A's queue.
- Worker picks up job → tenant context restored → `model("Order").findAll()` queries tenant A's DB.
- No "tenant ID as payload field" ceremony. No `with_tenant(tenant) { ... }` wrapper at the top of every job's `perform`.
- Tease post #4 (jobs).

### 5. When NOT to use framework-level multi-tenancy
- Admin / ops console that needs cross-tenant queries. Plan for it deliberately — exit the tenant context explicitly, or use a "system" datasource for admin reads.
- Cross-tenant reports. Same rule — these are a deliberate exception, not a framework fight.

### 6. Compared to the alternatives
- **Rails + apartment** — similar model; requires gem + config. Framework-level in Wheels.
- **Laravel + stancl/tenancy** — rich feature set but adds middleware and per-request initialization overhead from a plugin. Wheels inlines this.
- **Django + django-tenants** — solid but schema-only by default. Wheels supports separate DB out of the box.

### 7. Migration and seeding per tenant
- Each tenant DB gets the same migration set run against it.
- `wheels dbmigrate latest` can target per-tenant datasources.
- Seeding via `wheels db:seed` respects the active tenant context.
- (Short section — deep multi-tenant migration tactics is a follow-on post.)

### 8. Operational story
- Adding a tenant = creating a datasource + running migrations + optional seed.
- Removing a tenant = destroying the datasource. Clean delete, no row-leak risk.
- Backup/restore is per-datasource — operationally clean.
- Rate limiter database storage lives on the *app* DB, not per-tenant — one less thing to provision.

## Code / config snippets to include (pick 2)

```cfm
// config/settings.cfm — tenant resolution via middleware
set(middleware = [
    new app.middleware.TenantResolver()     // sets request-scoped tenant ctx
]);

// app/middleware/TenantResolver.cfc
component implements="wheels.middleware.MiddlewareInterface" {
    public any function handle(required struct request, required any next) {
        var subdomain = ListFirst(arguments.request.cgi.server_name, ".");
        arguments.request.tenant = subdomain;
        // Framework datasource switching hook — exact API in docs
        $setTenantDatasource(arguments.request.tenant);
        return arguments.next(arguments.request);
    }
}
```

```cfm
// Job that implicitly runs in tenant context
component extends="wheels.Job" {
    function config() {
        super.config();
        this.queue = "reports";
    }
    public void function perform(struct data = {}) {
        var orders = model("Order").findAll();   // tenant A's orders, automatically
        generateMonthlyReport(orders);
    }
}
```

## Suggested visuals

- **Architecture diagram:** request arrives → TenantResolver middleware → datasource resolved → controller/model → (on enqueue) job stored with tenant context → worker picks up → tenant context restored → model queries land on correct DB. Highlight that "tenant context" is one concept threaded through.
- **Comparison table:** Wheels 4.0 vs Rails+apartment vs Laravel+stancl vs Django-tenants — axis: framework-native? separate-DB model? tenant-aware jobs? schema model? Row-level model?

## Outro / CTA

- "If you've been thinking 'we'll deal with multi-tenancy later,' 4.0 makes 'now' a lot cheaper than 'later.'"
- Link to multi-tenancy docs once they land in `docs/src/`.
- Invite feedback on real SaaS patterns — this is a feature the team wants to harden based on production use.

## Citations (must link in final post)

- [Multi-tenancy PR #1951](https://github.com/wheels-dev/wheels/pull/1951)
- [Job worker daemon PR #1934](https://github.com/wheels-dev/wheels/pull/1934) (for the jobs-are-tenant-aware claim)
- [Middleware pipeline PR #1924](https://github.com/wheels-dev/wheels/pull/1924) (for the resolver pattern)
- [Feature audit § Multi-tenancy](https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-4.0-audit.md#9-multi-tenancy)
- Multi-tenancy docs page (to be confirmed / written if absent)
