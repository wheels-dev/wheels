---
title: insertAll()
description: "Inserts multiple records into the database in a single batch operation."
sidebar:
  label: insertAll()
  order: 0
---

## Signature

`insertAll()` — returns `struct`

**Available in:** `model`
**Category:** Create Functions

## Description

Inserts multiple records into the database in a single batch operation.
Accepts an array of structs where each struct represents a record to insert.
All structs must have the same set of keys (property names).
Batches in groups of 1000 to avoid database parameter limits.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `records` | `array` | yes | — | Array of structs, each containing property name/value pairs to insert. |
| `timestamps` | `boolean` | no | `true` | Set to `false` to skip automatic `createdAt`/`updatedAt` timestamping. |
| `transaction` | `string` | no | `[runtime expression]` | Set this to `commit` to update the database, `rollback` to run all the database queries but not commit them, or `none` to skip transaction handling altogether. |
| `parameterize` | `any` | no | `true` | Set to `true` to use `cfqueryparam` on all columns, or pass in a list of property names to use `cfqueryparam` on those only. |

</div>

