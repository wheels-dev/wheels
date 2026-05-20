---
title: exists()
description: "Checks if a record exists in the table."
sidebar:
  label: exists()
  order: 0
---

## Signature

`exists()` — returns `boolean`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Checks if a record exists in the table.
You can pass in either a primary key value to the <code>key</code> argument or a string to the <code>where</code> argument.
If you don't pass in either of those, it will simply check if any record exists in the table.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `key` | `any` | no | — | Primary key value(s) of the record. Separate with comma if passing in multiple primary key values. Accepts a string, list, or a numeric value. |
| `where` | `string` | no | — | Maps to the `WHERE` clause of the query (or `HAVING` when necessary). The following operators are supported: `=`, `!=`, `<>`, `<`, `<=`, `>`, `>=`, `LIKE`, `NOT LIKE`, `IN`, `NOT IN`, `IS NULL`, `IS NOT NULL`, `AND`, and `OR` (note that the key words need to be written in upper case). You can also use parentheses to group statements. Nested queries not allowed. You do not need to specify the table name(s); Wheels will do that for you. |
| `reload` | `boolean` | no | `false` | Set to `true` to force Wheels to query the database even though an identical query for this model may have been run in the same request. (The default in Wheels is to get the second query from the model's request-level cache.) |
| `parameterize` | `any` | no | `true` | Set to `true` to use `cfqueryparam` on all columns, or pass in a list of property names to use `cfqueryparam` on those only. |
| `includeSoftDeletes` | `boolean` | no | — | Set to `true` to include soft-deleted records in the queries that this method runs. |

</div>

