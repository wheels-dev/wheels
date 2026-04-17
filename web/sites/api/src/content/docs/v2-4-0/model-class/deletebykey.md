---
title: deleteByKey()
description: "Finds the record with the supplied key and deletes it."
sidebar:
  label: deleteByKey()
  order: 0
---

## Signature

`deleteByKey()` — returns `boolean`

**Available in:** `model`
**Category:** Delete Functions

## Description

Finds the record with the supplied key and deletes it.
Returns <code>true</code> on successful deletion of the row, <code>false</code> otherwise.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `key` | `any` | yes | — | Primary key value(s) of the record to fetch. Separate with comma if passing in multiple primary key values. Accepts a string, list, or a numeric value. |
| `reload` | `boolean` | no | `false` | Set to `true` to force CFWheels to query the database even though an identical query for this model may have been run in the same request. (The default in CFWheels is to get the second query from the model's request-level cache.) |
| `transaction` | `string` | no | `[runtime expression]` | Set this to `commit` to update the database, `rollback` to run all the database queries but not commit them, or `none` to skip transaction handling altogether. |
| `callbacks` | `boolean` | no | `true` | Set to `false` to disable callbacks for this method. |
| `includeSoftDeletes` | `boolean` | no | `false` | Set to `true` to include soft-deleted records in the queries that this method runs. |
| `softDelete` | `boolean` | no | `true` | Set to `false` to permanently delete a record, even if it has a soft delete column. |

## Examples

<pre><code class='javascript'>// Delete the user with the primary key value of `1`.
result = model(&quot;user&quot;).deleteByKey(1);
</code></pre>
