---
title: renameSystemTables()
description: "F15 Phase 2: rename legacy <code>c_o_r_e_*</code> system tables to <code>wheels_*</code>."
sidebar:
  label: renameSystemTables()
  order: 0
---

## Signature

`renameSystemTables()` — returns `struct`

**Available in:** `migrator`
**Category:** General Functions

## Description

F15 Phase 2: rename legacy <code>c_o_r_e_*</code> system tables to <code>wheels_*</code>.
Public API for the <code>wheels migrate rename-system-tables</code> CLI command.
Reads the current schema, generates per-adapter rename SQL, and
(unless <code>dryRun</code> is true) executes it inside a transaction. After
a successful rename, updates <code>application.wheels.{levelsTableName,
migratorTableName}</code> to the new names so the running app picks them
up without a restart.
Result struct:
- success: boolean
- renamed: array of "old -> new" strings (empty if no-op)
- skipped: human message when there's nothing to do
- errors: array of error messages (when success=false)
- sql: array of SQL statements that would run / did run
Refuses to run (returns success=false) when both <code>c_o_r_e_*</code> AND
<code>wheels_*</code> versions of either table coexist — that's a partial-
rename state which warrants manual cleanup, not silent destruction.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `dryRun` | `boolean` | no | `false` | When true, returns the SQL that would run without executing. |

</div>

