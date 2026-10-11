---
title: migrationLockStatus()
description: "Reports who holds the migration lock (#4209): <code>held</code>, <code>expired</code> (its lease ran out, so the"
sidebar:
  label: migrationLockStatus()
  order: 0
---

## Signature

`migrationLockStatus()` — returns `struct`

**Available in:** `migrator`
**Category:** General Functions

## Description

Reports who holds the migration lock (#4209): <code>held</code>, <code>expired</code> (its lease ran out, so the
next migration takes it over), <code>owner</code>, <code>host</code>, <code>heldForSeconds</code> and <code>expiresInSeconds</code>
(negative once expired). A missing lock table means nothing holds it.




