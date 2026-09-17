---
title: updateOne()
description: "Gets an object based on the arguments used and updates it with the supplied <code>properties</code>."
sidebar:
  label: updateOne()
  order: 0
---

## Signature

`updateOne()` — returns `boolean`

**Available in:** `model`
**Category:** Update Functions

## Description

Gets an object based on the arguments used and updates it with the supplied <code>properties</code>.
Returns <code>true</code> if an object was found and updated successfully, <code>false</code> otherwise.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `where` | `string` | no | — | Maps to the `WHERE` clause of the query (or `HAVING` when necessary). The following operators are supported: `=`, `!=`, `<>`, `<`, `<=`, `>`, `>=`, `LIKE`, `NOT LIKE`, `IN`, `NOT IN`, `IS NULL`, `IS NOT NULL`, `AND`, and `OR` (note that the key words need to be written in upper case). You can also use parentheses to group statements. Nested queries not allowed. You do not need to specify the table name(s); Wheels will do that for you. |
| `order` | `string` | no | — | Maps to the `ORDER` BY clause of the query. You do not need to specify the table name(s); Wheels will do that for you. |
| `properties` | `struct` | no | `[runtime expression]` | The properties you want to set on the object (can also be passed in as named arguments). |
| `reload` | `boolean` | no | `false` | Set to `true` to force Wheels to query the database even though an identical query for this model may have been run in the same request. (The default in Wheels is to get the second query from the model's request-level cache.) |
| `validate` | `boolean` | no | `true` | Set to `false` to skip validations for this operation. |
| `useIndex` | `struct` | no | `[runtime expression]` | If you want to specify table index hints, pass in a structure of index names using your model names as the structure keys. Eg: `{user="idx_users", post="idx_posts"}`. This feature is only supported by MySQL and SQL Server. |
| `transaction` | `string` | no | `[runtime expression]` | Set this to `commit` to update the database, `rollback` to run all the database queries but not commit them, or `none` to skip transaction handling altogether. |
| `callbacks` | `boolean` | no | `true` | Set to `false` to disable callbacks for this method. |
| `includeSoftDeletes` | `boolean` | no | `false` |  |

</div>

## Examples

<pre><code class='javascript'>// 1. Update the most recently released product by setting its `featured` flag
result = model(&quot;Product&quot;).updateOne(order=&quot;releaseDate DESC&quot;, featured=1);

// 2. Update a specific record matching a `where` clause
result = model(&quot;Order&quot;).updateOne(where=&quot;status='pending' AND createdAt &lt; '#DateAdd('d', -7, Now())#'&quot;, status=&quot;expired&quot;);

// 3. Skip validations when updating, e.g. to force a status change
result = model(&quot;Article&quot;).updateOne(where=&quot;status='draft'&quot;, order=&quot;createdAt ASC&quot;, status=&quot;published&quot;, validate=false);

// 4. Scoped call via a `hasOne` association (calls `updateOne` internally)
// Given `hasOne(name=&quot;profile&quot;)` on the User model:
aUser = model(&quot;User&quot;).findByKey(params.userId);
aUser.removeProfile();
</code></pre>
