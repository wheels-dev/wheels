---
title: withAdvisoryLock()
description: "Executes a callback while holding a database advisory lock."
sidebar:
  label: withAdvisoryLock()
  order: 0
---

## Signature

`withAdvisoryLock()` — returns `any`

**Available in:** `model`
**Category:** Locking Functions

## Description

Executes a callback while holding a database advisory lock.
The lock is automatically released when the callback completes, even if an exception is thrown.
Advisory locks are database-level locks that don't lock rows or tables. They are useful for
coordinating exclusive access to shared resources across application instances.
Callers in one application wait on an application-server lock first, so only one of them
holds the database lock at a time. The release is verified: if it ran on a pooled database
session other than the one holding the lock, it is retried for up to 5 seconds, then
<code>Wheels.AdvisoryLockReleaseFailed</code> is thrown naming the lock.
Support varies by database:
- PostgreSQL: Full support via pg_advisory_lock/pg_advisory_unlock
- MySQL: Full support via GET_LOCK/RELEASE_LOCK
- SQL Server: Full support via sp_getapplock/sp_releaseapplock, owned by the database session, so
no transaction is needed
- SQLite: No-op (file-level locking only)
- CockroachDB: Not supported (throws error, use forUpdate() instead)
- H2: Not supported (throws error)
- Oracle: Not supported by default (requires DBMS_LOCK package setup)


The lock is always released, including when the callback ends the request with <code>abort</code>, <code>redirectTo()</code> or <code>cflocation</code>: the release runs in a <code>finally</code>, which executes on those paths (measured on Lucee, Adobe and BoxLang). The one case not covered is a request killed without running its <code>finally</code> — the engine's request-timeout cutting the request off, or a JVM crash — after which a session-scoped lock (MySQL / SQL Server) frees only when its pooled connection is closed; a PostgreSQL transaction-scoped lock still frees when that connection's transaction is rolled back on return to the pool.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | A unique name for the lock. Different callers using the same name will contend for the same lock. |
| `timeout` | `numeric` | no | `10` | Maximum number of seconds to wait for the lock in all: first for another caller in this application, then for the database lock with the time that is left (at least one second), so the wait is about `timeout` at most. |
| `callback` | `any` | yes | — | A function or closure to execute while holding the lock. Its return value is returned by this method. |
| `transaction` | `boolean` | no | `false` | When `true`, acquire the lock, run the callback, and release the lock on one connection pinned by a transaction, so the lock genuinely covers the callback's own queries (#4198). On PostgreSQL the lock is transaction-scoped and auto-releases when the transaction ends; on MySQL and SQL Server it is a session lock released before the transaction closes. The callback then runs inside a transaction: its writes commit or roll back together, and a `transaction()` inside it nests. Recommended for short critical sections; avoid for long-running callbacks, which would hold their row locks and a pooled connection — and block PostgreSQL VACUUM — for the whole call. Supported on PostgreSQL, MySQL, and SQL Server; `true` on any other database throws. Defaults to `false` (the session-scoped behaviour). |

</div>

## Examples

<pre><code class='javascript'>// 1. Prevent duplicate processing of a background job
model(&quot;Job&quot;).withAdvisoryLock(name=&quot;process-nightly-report&quot;, callback=function() {
    job = model(&quot;Job&quot;).findOneByNameAndStatus(name=&quot;nightly-report&quot;, status=&quot;pending&quot;);
    if (isObject(job)) {
        job.process();
    }
});

// 2. Serialize access to a shared external resource with a custom timeout
result = model(&quot;Payment&quot;).withAdvisoryLock(
    name=&quot;payment-gateway-sync&quot;,
    timeout=30,
    callback=function() {
        return model(&quot;Payment&quot;).syncWithGateway();
    }
);

// 3. Ensure only one instance assigns the next batch of records
model(&quot;Task&quot;).withAdvisoryLock(name=&quot;task-batch-assignment&quot;, callback=function() {
    tasks = model(&quot;Task&quot;).findAll(
        conditions=&quot;assignedTo IS NULL&quot;,
        maxRows=10,
        returnAs=&quot;objects&quot;
    );
    for (task in tasks) {
        task.update(assignedTo=getCurrentWorkerID());
    }
});
</code></pre>
