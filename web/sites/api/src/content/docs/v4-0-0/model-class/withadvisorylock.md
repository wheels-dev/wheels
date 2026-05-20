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
Support varies by database:
- PostgreSQL: Full support via pg_advisory_lock/pg_advisory_unlock
- MySQL: Full support via GET_LOCK/RELEASE_LOCK
- SQL Server: Full support via sp_getapplock/sp_releaseapplock
- SQLite: No-op (file-level locking only)
- CockroachDB: Not supported (throws error, use forUpdate() instead)
- H2: Not supported (throws error)
- Oracle: Not supported by default (requires DBMS_LOCK package setup)



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | A unique name for the lock. Different callers using the same name will contend for the same lock. |
| `timeout` | `numeric` | no | `10` | Maximum number of seconds to wait when acquiring the lock (supported by MySQL and SQL Server). |
| `callback` | `any` | yes | — | A function or closure to execute while holding the lock. Its return value is returned by this method. |

</div>

