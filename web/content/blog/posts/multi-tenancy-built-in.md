---
title: Multi-Tenancy Built In
slug: multi-tenancy-built-in
publishedAt: '2026-05-10T14:00:00.000Z'
updatedAt: '2026-05-07T02:00:09.000Z'
author: Peter Amiri
tags:
  - wheels-4
  - multi-tenancy
  - saas
categories: []
excerpt: >-
  Wheels 4.0 lifts multi-tenancy out of plugin territory and into the
  framework core. Per-request datasource switching catches every query and
  every job on the way to the database, and tenant-aware background jobs come
  along for the ride.
coverImage: null
---

If you've been rolling your own tenant switching — a `beforeFilter` here, a thread-local there, a prayer that nobody writes a raw `cfquery` in a view — Wheels 4.0 is the release where you get to throw that scaffolding away. Per-request datasource switching now lives in the framework core. Every model call, every association load, every background job picks up the active tenant's datasource automatically.

This is not a plugin. There is nothing to install. If you can resolve "who is this request for?" you can write a multi-tenant Wheels app.

## The seam you need to cut cleanly

Multi-tenancy is a seam problem, not a feature problem. You need *one* seam that catches every query, every job, every background task. Miss one, and a stray `cfquery` or a job that forgot to resolve tenant context leaks data across tenants. That is the incident-on-a-Sunday bug — the one where customer A sees customer B's invoice and your week evaporates.

Plugin-based tenancy catches about eighty percent of the paths. The hard ones are the straggler query in a report action, the `CreateObject("java", ...)` that goes around the ORM, and the background job enqueued from a web request that never asked "whose job is this?" The plugin only sees the places where it was wired in.

Framework-level tenancy catches the other twenty percent because every data path is routed through the datasource resolver. The seam is in the framework, not the consumer code. You can forget about it, and that is the point.

## Three models, one framework

Wheels 4.0 supports the three established SaaS data patterns. You pick based on isolation requirements, not framework limitations.

**Separate database per tenant** gives the cleanest isolation. Per-customer backup and restore, per-customer performance tuning, per-customer encryption at rest. The datasource resolver switches the entire connection per request. This is the default story for anyone who has had a regulated tenant ask hard questions about data segregation.

**Shared database, separate schema** — supported via datasource naming. One physical database, one connection pool, logical separation through schema prefixes. Middle ground between operational simplicity and isolation.

**Shared database, row-level** — every table gets a `tenantId` column and every query gets scoped. Wheels supports it through default scopes, but honestly: this model requires the most discipline regardless of framework. The framework can't protect you from a hand-rolled join that forgets the where clause. Pick this and you're signing up for code review on every data access.

## Tenant resolution — from request to datasource

Tenant resolution happens early, in middleware, before your controller ever instantiates. The resolved tenant is attached to the request, and the datasource resolver picks it up from there.

```cfm
// config/settings.cfm — tenant resolution via middleware
set(middleware = [
    new app.middleware.TenantResolver()
]);

// app/middleware/TenantResolver.cfc
component implements="wheels.middleware.MiddlewareInterface" {
    public any function handle(required struct request, required any next) {
        var subdomain = ListFirst(arguments.request.cgi.server_name, ".");
        arguments.request.tenant = subdomain;
        $setTenantDatasource(arguments.request.tenant);
        return arguments.next(arguments.request);
    }
}
```

The resolution source is up to you: subdomain (`acme.myapp.com`), path prefix (`/t/acme`), request header (`X-Tenant: acme`), or a claim out of a JWT (`tid`). The middleware contract is the same — pull the identifier, call `$setTenantDatasource`, pass the request along.

From that point on, every `model("Order").findAll()` in the request lifecycle hits the right database. You don't pass the tenant around. You don't remember to scope. The resolver already did it.

## Tenant-aware background jobs

This is the part that separates a framework-level solution from a plugin-level one. When you enqueue a job from tenant A's request, the tenant context is persisted with the job. When the worker picks that job up later — in a different process, on a different host, hours later — the framework restores the tenant context before `perform` runs.

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

No "tenant ID as payload field" ceremony. No `with_tenant(tenant) { ... }` wrapper wrapped around every `perform` body. No unit test that accidentally passes because it happened to run against the right default datasource. The `model("Order").findAll()` call inside the job behaves exactly the way it would inside the controller that enqueued the job. You get tenant-aware jobs without ceremony, and that is the feature.

## When NOT to use framework-level multi-tenancy

Honesty clause. There are places where you *want* to escape the tenant context, and pretending otherwise makes the feature worse, not better.

**Admin and ops consoles.** The whole point of an internal admin console is cross-tenant visibility. "Which tenants signed up this week?" "Which tenants are approaching their rate limit?" Those queries cannot run inside a tenant's datasource. Exit the tenant context explicitly, or wire a dedicated "system" datasource for admin reads. Don't try to make the framework solve a problem it's deliberately preventing.

**Cross-tenant reports and billing.** Same rule. Monthly invoicing, aggregate usage metrics, platform-wide analytics — these live in a system-level datasource with deliberate, audited queries. Treat the escape hatch as a deliberate exception, not a framework fight.

The framework makes the right thing easy. It doesn't make the cross-cutting thing impossible. Both matter.

## Compared to the alternatives

If you're coming from another framework: Rails + [apartment](https://github.com/influitive/apartment) is the closest analogue — similar mental model, added via gem and config. Laravel + [stancl/tenancy](https://tenancyforlaravel.com/) is rich but adds middleware and per-request init overhead from a package. Django + [django-tenants](https://github.com/django-tenants/django-tenants) is solid but schema-only by default.

None of this is revolutionary. The contribution is that Wheels ships it in the core and ties it into the background job system, so the hard-to-catch paths are caught by default.

## Migration and seeding per tenant

Each tenant database gets the same migration set. `wheels dbmigrate latest` targets per-tenant datasources — either one at a time, or across all registered tenants in a loop. Seeding respects the active tenant context, so your `seeds.cfm` runs against the right database without special casing.

Adding a tenant looks like: create the datasource, run migrations, run seeds. Removing a tenant is destroying the datasource. There is no row-leak risk to audit, because there are no rows to leave behind.

## Operational story

Per-datasource backup and restore. Per-datasource scaling. A tenant hammering your CPU doesn't starve the others. A tenant requesting GDPR erasure is a `DROP DATABASE` away from complete.

One note: the rate limiter's database storage lives on the application datasource, not per-tenant. That's deliberate — you want cross-tenant rate-limit visibility for abuse detection, and you don't want to provision that table inside every customer database.

## Where this lands in 4.0

Multi-tenancy was one of the themes we pushed hardest on during the sprint to 4.0 — roughly 260 pull requests across 15 weeks, with contributions from @bpamiri, @zainforbjs, @chapmandu, @mlibbe, @MukundaKatta, and Dependabot keeping the dependency graph honest.

If you've been thinking "we'll deal with multi-tenancy later," 4.0 makes "now" a lot cheaper than "later." The seam is in place. Middleware, datasource resolution, and background job context restoration are all wired together. The expensive part — retrofitting tenant awareness onto an app that wasn't designed for it — is the part you avoid by picking it up early.

## Where to go next

- [Multi-tenancy guide](https://guides.wheels.dev/v4-0-0-snapshot/digging-deeper/multi-tenancy/) — the user-facing reference for tenant resolution, datasource switching, and migrations per tenant.
- [Background jobs guide](https://guides.wheels.dev/v4-0-0-snapshot/digging-deeper/background-jobs/) — how the tenant context is restored when a worker picks up a job.
- [Middleware pipeline](https://guides.wheels.dev/v4-0-0-snapshot/core-concepts/middleware-pipeline/) — where the tenant resolver lives.
- [Full audit § Multi-tenancy](https://github.com/wheels-dev/wheels/blob/develop/docs/releases/wheels-4.0-audit.md) — the PR-level receipts.

We'd love to hear from teams running production SaaS on this — especially the pattern of tenant identity source (subdomain vs. path vs. header vs. JWT claim) and how it interacts with your auth layer. That's the area where we expect the 4.0.x polish cycle to want the most feedback.

