---
title: upsertAll()
description: "Inserts or updates multiple records in a single batch operation (upsert)."
sidebar:
  label: upsertAll()
  order: 0
---

## Signature

`upsertAll()` — returns `struct`

**Available in:** `model`
**Category:** Create Functions

## Description

Inserts or updates multiple records in a single batch operation (upsert).
Uses database-specific conflict resolution syntax (e.g., <code>ON CONFLICT ... DO UPDATE</code> for PostgreSQL/SQLite).
The <code>uniqueBy</code> argument specifies which properties form the unique constraint for conflict detection.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `records` | `array` | yes | — | Array of structs, each containing property name/value pairs. |
| `uniqueBy` | `string` | yes | — | Comma-delimited list of property names that form the unique constraint for conflict detection. |
| `timestamps` | `boolean` | no | `true` | Set to `false` to skip automatic `createdAt`/`updatedAt` timestamping. |
| `transaction` | `string` | no | `[runtime expression]` | Set this to `commit` to update the database, `rollback` to run all the database queries but not commit them, or `none` to skip transaction handling altogether. |
| `parameterize` | `any` | no | `true` | Set to `true` to use `cfqueryparam` on all columns, or pass in a list of property names to use `cfqueryparam` on those only. |

</div>

