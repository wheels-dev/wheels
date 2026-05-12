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
| `where` | `string` | no | — | Maps to the `WHERE` clause of the query (or `HAVING` when necessary). The following operators are supported: `=`, `!=`, `<>`, `<`, `<=`, `>`, `>=`, `LIKE`, `NOT LIKE`, `IN`, `NOT IN`, `IS NULL`, `IS NOT NULL`, `AND`, and `OR` (note that the key words need to be written in upper case). You can also use parentheses to group statements. You do not need to specify the table name(s); CFWheels will do that for you. |
| `order` | `string` | no | — | Maps to the `ORDER` BY clause of the query. You do not need to specify the table name(s); CFWheels will do that for you. |
| `properties` | `struct` | no | `[runtime expression]` | The properties you want to set on the object (can also be passed in as named arguments). |
| `reload` | `boolean` | no | `false` | Set to `true` to force CFWheels to query the database even though an identical query for this model may have been run in the same request. (The default in CFWheels is to get the second query from the model's request-level cache.) |
| `validate` | `boolean` | no | `true` | Set to `false` to skip validations for this operation. |
| `transaction` | `string` | no | `[runtime expression]` | Set this to `commit` to update the database, `rollback` to run all the database queries but not commit them, or `none` to skip transaction handling altogether. |
| `callbacks` | `boolean` | no | `true` | Set to `false` to disable callbacks for this method. |
| `includeSoftDeletes` | `boolean` | no | `false` |  |

</div>

## Examples

<pre><code class='javascript'>// Sets the `new` property to `1` on the most recently released product
result = model(&quot;product&quot;).updateOne(order=&quot;releaseDate DESC&quot;, new=1);

// If you have a `hasOne` association setup from `user` to `profile`, you can do a scoped call. (The `removeProfile` method below will call `model(&quot;profile&quot;).updateOne(where=&quot;userId=#aUser.id#&quot;, userId=&quot;&quot;)` internally.)
aUser = model(&quot;user&quot;).findByKey(params.userId);
aUser.removeProfile();</code></pre>
