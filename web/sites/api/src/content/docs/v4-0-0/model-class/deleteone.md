---
title: deleteOne()
description: "Gets an object based on conditions and deletes it."
sidebar:
  label: deleteOne()
  order: 0
---

## Signature

`deleteOne()` — returns `boolean`

**Available in:** `model`
**Category:** Delete Functions

## Description

Gets an object based on conditions and deletes it.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `where` | `string` | no | — | Maps to the `WHERE` clause of the query (or `HAVING` when necessary). The following operators are supported: `=`, `!=`, `<>`, `<`, `<=`, `>`, `>=`, `LIKE`, `NOT LIKE`, `IN`, `NOT IN`, `IS NULL`, `IS NOT NULL`, `AND`, and `OR` (note that the key words need to be written in upper case). You can also use parentheses to group statements. Nested queries not allowed. You do not need to specify the table name(s); Wheels will do that for you. |
| `order` | `string` | no | — | Maps to the `ORDER` BY clause of the query. You do not need to specify the table name(s); Wheels will do that for you. |
| `reload` | `boolean` | no | `false` | Set to `true` to force Wheels to query the database even though an identical query for this model may have been run in the same request. (The default in Wheels is to get the second query from the model's request-level cache.) |
| `transaction` | `string` | no | `[runtime expression]` | Set this to `commit` to update the database, `rollback` to run all the database queries but not commit them, or `none` to skip transaction handling altogether. |
| `callbacks` | `boolean` | no | `true` | Set to `false` to disable callbacks for this method. |
| `includeSoftDeletes` | `boolean` | no | `false` | Set to `true` to include soft-deleted records in the queries that this method runs. |
| `useIndex` | `struct` | no | `[runtime expression]` | If you want to specify table index hints, pass in a structure of index names using your model names as the structure keys. Eg: `{user="idx_users", post="idx_posts"}`. This feature is only supported by MySQL and SQL Server. |
| `softDelete` | `boolean` | no | `true` | Set to `false` to permanently delete a record, even if it has a soft delete column. |

</div>

