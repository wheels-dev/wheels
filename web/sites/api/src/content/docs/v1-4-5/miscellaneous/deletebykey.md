---
title: deleteByKey()
description: "Finds the record with the supplied key and deletes it. Returns true on successful deletion of the row, false otherwise."
sidebar:
  label: deleteByKey()
  order: 0
---

## Signature

`deleteByKey()` — returns `any`




## Description

Finds the record with the supplied key and deletes it. Returns true on successful deletion of the row, false otherwise.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `key` | `any` | yes | — | Primary key value(s) of the record to fetch. Separate with comma if passing in multiple primary key values. Accepts a string, list, or a numeric value. |
| `reload` | `boolean` | yes | `false` | Set to true to force Wheels to query the database even though an identical query may have been run in the same request. (The default in Wheels is to get the second query from the request-level cache.) |
| `transaction` | `string` | yes | `[runtime expression]` | Set this to commit to update the database when the save has completed, rollback to run all the database queries but not commit them, or none to skip transaction handling altogether. |
| `callbacks` | `boolean` | yes | `true` | Set to false to disable callbacks for this operation. |
| `includeSoftDeletes` | `boolean` | yes | `false` | You can set this argument to true to include soft-deleted records in the results. |
| `softDelete` | `boolean` | yes | `true` | Set to false to permanently delete a record, even if it has a soft delete column. |

</div>

## Examples

<pre>deleteByKey(key [, reload, transaction, callbacks, includeSoftDeletes, softDelete ]) &lt;!--- Delete the user with the primary key value of `1` ---&gt;
&lt;cfset result = model(&quot;user&quot;).deleteByKey(1)&gt;</pre>
