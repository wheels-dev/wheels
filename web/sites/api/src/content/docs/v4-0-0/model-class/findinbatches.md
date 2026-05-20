---
title: findInBatches()
description: "Processes large result sets in batches without loading everything into memory at once."
sidebar:
  label: findInBatches()
  order: 0
---

## Signature

`findInBatches()` — returns `void`

**Available in:** `model`
**Category:** Read Functions

## Description

Processes large result sets in batches without loading everything into memory at once.
The callback receives a query result set (or array of objects/structs) for each batch.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `batchSize` | `numeric` | no | `500` | Number of records per batch. Defaults to 500. |
| `callback` | `any` | yes | — | A function/closure to call for each batch. Receives a single argument: the batch (query, array of objects, or array of structs depending on `returnAs`). |
| `where` | `string` | no | — | Maps to the `WHERE` clause of the query (or `HAVING` when necessary). The following operators are supported: `=`, `!=`, `<>`, `<`, `<=`, `>`, `>=`, `LIKE`, `NOT LIKE`, `IN`, `NOT IN`, `IS NULL`, `IS NOT NULL`, `AND`, and `OR` (note that the key words need to be written in upper case). You can also use parentheses to group statements. Nested queries not allowed. You do not need to specify the table name(s); Wheels will do that for you. |
| `order` | `string` | no | — | Maps to the `ORDER` BY clause of the query. You do not need to specify the table name(s); Wheels will do that for you. |
| `include` | `string` | no | — | Associations that should be included in the query using `INNER` or `LEFT OUTER` joins (which join type that is used depends on how the association has been set up in your model). If all included associations are set on the current model, you can specify them in a list (e.g. `department,addresses,emails`). You can build more complex include strings by using parentheses when the association is set on an included model, like `album(artist(genre))`, for example. These complex `include` strings only work when `returnAs` is set to `query` though. |
| `select` | `string` | no | — | Determines how the `SELECT` clause for the query used to return data will look. You can pass in a list of the properties (which map to columns) that you want returned from your table(s). If you don't set this argument at all, Wheels will select all properties from your table(s). If you specify a table name (e.g. `users.email`) or alias a column (e.g. `fn AS firstName`) in the list, then the entire list will be passed through unchanged and used in the `SELECT` clause of the query. By default, all column names in tables joined via the `include` argument will be prepended with the singular version of the included table name. |
| `parameterize` | `any` | no | — | Set to `true` to use `cfqueryparam` on all columns, or pass in a list of property names to use `cfqueryparam` on those only. |
| `includeSoftDeletes` | `boolean` | no | `false` | Set to `true` to include soft-deleted records in the queries that this method runs. |
| `returnAs` | `string` | no | `query` | Set to "query" (default), "objects", or "structs" for the batch format. |

</div>

