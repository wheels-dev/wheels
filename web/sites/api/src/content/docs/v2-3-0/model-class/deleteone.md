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

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `where` | `string` | no | — | Maps to the `WHERE` clause of the query (or `HAVING` when necessary). The following operators are supported: `=`, `!=`, `<>`, `<`, `<=`, `>`, `>=`, `LIKE`, `NOT LIKE`, `IN`, `NOT IN`, `IS NULL`, `IS NOT NULL`, `AND`, and `OR` (note that the key words need to be written in upper case). You can also use parentheses to group statements. You do not need to specify the table name(s); CFWheels will do that for you. |
| `order` | `string` | no | — | Maps to the `ORDER` BY clause of the query. You do not need to specify the table name(s); CFWheels will do that for you. |
| `reload` | `boolean` | no | `false` | Set to `true` to force CFWheels to query the database even though an identical query for this model may have been run in the same request. (The default in CFWheels is to get the second query from the model's request-level cache.) |
| `transaction` | `string` | no | `[runtime expression]` | Set this to `commit` to update the database, `rollback` to run all the database queries but not commit them, or `none` to skip transaction handling altogether. |
| `callbacks` | `boolean` | no | `true` | Set to `false` to disable callbacks for this method. |
| `includeSoftDeletes` | `boolean` | no | `false` | Set to `true` to include soft-deleted records in the queries that this method runs. |
| `softDelete` | `boolean` | no | `true` | Set to `false` to permanently delete a record, even if it has a soft delete column. |

## Examples

<pre><code class='javascript'>// Delete the user that signed up last.
result = model(&quot;user&quot;).deleteOne(order=&quot;signupDate DESC&quot;);

// If you have a `hasOne` association setup from `user` to `profile` you can do a scoped call (the `deleteProfile` method below will call `model(&quot;profile&quot;).deleteOne(where=&quot;userId=#aUser.id#&quot;)` internally).
aUser = model(&quot;user&quot;).findByKey(params.userId);
aUser.deleteProfile();
</code></pre>
