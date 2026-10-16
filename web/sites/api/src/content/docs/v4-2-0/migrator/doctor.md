---
title: doctor()
description: "Returns a comprehensive health report on the migrator state. Pure"
sidebar:
  label: doctor()
  order: 0
---

## Signature

`doctor()` — returns `struct`

**Available in:** `migrator`
**Category:** General Functions

## Description

Returns a comprehensive health report on the migrator state. Pure
read — no mutation. Used by <code>wheels migrate doctor</code> to surface
orphans, gaps, and pending migrations in one pass.
Result struct:
- healthy: boolean — true iff no orphans AND no pending
- currentVersion: string — highest applied version (may be orphan)
- orphans: array — DB versions with no matching file
- pending: array — local files not yet applied
- summary: struct with .total, .applied, .pending, .orphan counts
- message: human-readable one-paragraph summary
See issue #2780 / PR #2798 for the orphan detection foundation.




