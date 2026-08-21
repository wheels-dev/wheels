---
title: 'Processing 400,000 Rows Without Melting the JVM: findEach and findInBatches'
slug: findeach-findinbatches-batch-processing
publishedAt: '2026-07-17T14:00:00.000Z'
updatedAt: '2026-07-06T05:14:40.000Z'
author: Peter Amiri
tags:
  - wheels-4
  - models
  - performance
  - orm
categories: []
excerpt: >-
  findAll on 400,000 rows materializes everything into memory at once — and
  the request cache holds it there. Wheels 4's findEach and findInBatches walk
  big result sets a page at a time, with three built-in optimizations you'd
  forget to hand-roll and two sharp edges worth knowing first.
coverImage: null
---

The feature request sounds harmless: "email a renewal reminder to every user whose subscription lapses this quarter." You write the obvious thing:

```cfm
users = model("User").findAll(where="renewsAt <= '#quarterEnd#'", returnAs="objects");
for (user in users) {
    user.sendRenewalReminder();
}
```

On staging, with four hundred users, it's fine. In production, with four hundred *thousand*, that first line materializes every matching record into memory at once — and then the framework's request-level query cache holds the result for the rest of the request on top of it. Somewhere around the JVM's heap ceiling, your renewal reminder becomes an incident review.

Wheels 4 ships the correct shape as two model methods: `findEach()` when you want to process records one at a time, and `findInBatches()` when you want to work a chunk at a time. This post is how they work, what they do under the hood that you'd forget to do yourself, and the two sharp edges worth knowing before you point them at a million rows.

## `findEach` — one record at a time, bounded memory

```cfm
model("User").findEach(
    where = "renewsAt <= '2026-09-30'",
    batchSize = 1000,
    callback = function(user) {
        user.sendRenewalReminder();
    }
);
```

Behind the scenes: the framework pages through the result set `batchSize` records at a time (default 1000), instantiates just that page as model objects, hands each object to your callback, then moves to the next page. Peak memory is one batch, no matter how many rows match. The full signature also accepts the finder arguments you'd expect — `order`, `include`, `select`, `includeSoftDeletes` — plus `returnAs="object"` (default) or `"struct"` if you don't need model behavior and want cheaper instantiation.

## `findInBatches` — a chunk at a time, for set-based work

Same pagination engine, different callback unit: your function receives the whole batch, as a query by default (or `returnAs="objects"` / `"structs"`).

```cfm
model("Order").findInBatches(
    where = "status = 'shipped' AND invoicedAt IS NULL",
    batchSize = 500,
    callback = function(orders) {
        // one API call per 500 orders, not per order
        invoiceService.submitBatch(orders);
    }
);
```

The rule of thumb: reach for `findEach` when the work is inherently per-record (send an email, recompute one row's denormalized field), and `findInBatches` when the downstream is happier with sets — bulk API endpoints, CSV writing, `INSERT INTO ... SELECT`-style handoffs. The default batch sizes encode the same idea: 1000 for the per-record method, 500 for the per-chunk one where each unit does more work.

Both are also available at the end of a scope chain, so your domain vocabulary carries through:

```cfm
model("User").active().findEach(batchSize=1000, callback=processUser);
```

## What they do for you that you'd forget

Three implementation details, all visible in `vendor/wheels/model/read.cfc`, that are the difference between these methods and the hand-rolled `page`/`perPage` loop you were about to write:

1. **One COUNT, not one per page.** The total is computed once up front and passed into every page's finder, so a 200-page walk doesn't re-run the count 200 times.
2. **The request-level query cache is opted out.** Wheels normally caches identical query results for the duration of a request — a great default that would quietly defeat batching by accumulating every processed page in memory until the request ends. The batch methods pass an internal flag to skip that cache per page. Your hand-rolled loop wouldn't.
3. **Deterministic order by default.** If you don't pass `order`, both methods order by the primary key ascending. Paging without a stable order is how records get skipped or processed twice; the default makes the walk consistent even when you forget.

## Sharp edge #1: don't mutate rows out of your own `where`

The pagination is page/offset-based over a live query. That means the classic offset trap applies: if your callback changes rows so they *stop matching the `where` clause* — deleting processed records, flipping `invoicedAt` from NULL to a date — the result set shrinks underneath the walk, pages shift left, and records slide past unprocessed.

Two clean ways out:

- **Make the work not change matching.** Track processing in a column the `where` doesn't reference, and reconcile afterward.
- **Collect keys first, then work the keys.** Use a cheap first pass (`select` just the primary key, `returnAs="struct"`) to snapshot the IDs, then process by key — the snapshot doesn't shift no matter what the callback does.

If your callback only *reads*, or updates columns the `where` never mentions, none of this applies — walk away happy.

## Sharp edge #2: the closure scope rule

The callbacks are CFML closures, and CFML closures cannot see the calling function's `var`-scoped locals. This compiles and silently counts nothing:

```cfm
// WRONG — local.sent is invisible inside the closure
var sent = 0;
model("User").findEach(callback = function(user) {
    user.sendRenewalReminder();
    sent++;   // not the sent you declared
});
```

The idiom is a shared struct, which closures capture by reference:

```cfm
// RIGHT
var stats = {sent: 0, skipped: 0};
model("User").findEach(callback = function(user) {
    if (user.optedOut) { stats.skipped++; return; }
    user.sendRenewalReminder();
    stats.sent++;
});
writeLog(text="renewal reminders: #stats.sent# sent, #stats.skipped# skipped", file="application");
```

This is the same closure-scope rule that bites in test specs and `each()` calls across CFML — the batch methods just give you a new place to meet it.

## Where batch processing wants to live

A 400,000-row walk doesn't belong in a web request, bounded memory or not — request timeouts and users don't share your patience. The natural homes:

- **A [background job](https://blog.wheels.dev/posts/background-jobs-without-redis)** — `findEach` inside a `wheels.Job`'s `perform()` is the canonical pairing: the job gets retries and backoff, the walk gets bounded memory.
- **A scheduled task or one-off script** invoking a protected code path — same pattern the [seeding](https://guides.wheels.dev/v4-0-0/basics/seeding/) and [migration](https://guides.wheels.dev/v4-0-0/basics/migrations/) programmatic surfaces use.

And a closing calibration: if the work can be expressed as *one SQL statement*, do that instead. `updateAll()` and `deleteAll()` exist precisely so you don't iterate what the database can do in a single set operation. The batch methods are for the middle ground — work that genuinely needs CFML per record or per chunk, at row counts where "just load it all" stops being a plan.

Finders, scopes, and the query builder are covered in [Beyond findAll](https://blog.wheels.dev/posts/beyond-findall-scopes-enums-query-builder); the model API reference for both methods is in the [guides](https://guides.wheels.dev/v4-0-0/basics/models-and-the-orm/).

