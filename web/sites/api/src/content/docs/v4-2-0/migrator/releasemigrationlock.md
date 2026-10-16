---
title: releaseMigrationLock()
description: "Removes the migration lock's lease row (#4209), for when the instance holding it is gone."
sidebar:
  label: releaseMigrationLock()
  order: 0
---

## Signature

`releaseMigrationLock()` — returns `struct`

**Available in:** `migrator`
**Category:** General Functions

## Description

Removes the migration lock's lease row (#4209), for when the instance holding it is gone.
Without <code>force</code> only an expired lease is removed; with it the row goes whoever holds it, and
a holder that is still running fails its next renewal with Wheels.MigrationLockLost. Returns
<code>lock</code>, the migrationLockStatus() from before the removal; <code>heldBy</code>, the owner holding the lock
after it ("" when free, another owner when an instance took it meanwhile); and <code>released</code>,
true when the lock is free afterwards.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `force` | `boolean` | no | `false` | Remove a lease that hasn't expired. |

</div>

