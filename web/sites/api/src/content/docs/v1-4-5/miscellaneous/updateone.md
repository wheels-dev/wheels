---
title: updateOne()
description: "Gets an object based on the arguments used and updates it with the supplied properties. Returns true if an object was found and updated successfully, false othe"
sidebar:
  label: updateOne()
  order: 0
---

## Signature

`updateOne()` — returns `any`




## Description

Gets an object based on the arguments used and updates it with the supplied properties. Returns true if an object was found and updated successfully, false otherwise.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `where` | `string` | yes | — | This argument maps to the WHERE clause of the query. The following operators are supported: =, !=, <>, <, <=, >, >=, LIKE, NOT LIKE, IN, NOT IN, IS NULL, IS NOT NULL, AND, and `OR. (Note that the key words need to be written in upper case.) You can also use parentheses to group statements. You do not need to specify the table name(s); Wheels will do that for you. |
| `order` | `string` | yes | — | Maps to the ORDER BY clause of the query. You do not need to specify the table name(s); Wheels will do that for you. |
| `properties` | `struct` | yes | `[runtime expression]` | The properties you want to set on the object (can also be passed in as named arguments). |
| `reload` | `boolean` | yes | `false` | Set to true to force Wheels to query the database even though an identical query may have been run in the same request. (The default in Wheels is to get the second query from the request-level cache.) |
| `validate` | `any` | no | — |  |
| `transaction` | `string` | yes | `[runtime expression]` | Set this to commit to update the database when the save has completed, rollback to run all the database queries but not commit them, or none to skip transaction handling altogether. |
| `callbacks` | `boolean` | yes | `true` | Set to false to disable callbacks for this operation. |
| `includeSoftDeletes` | `boolean` | yes | `false` | You can set this argument to true to include soft-deleted records in the results. |

## Examples

<pre>updateOne([ where, order, properties, reload, validate, transaction, callbacks, includeSoftDeletes ]) &lt;!--- Sets the `new` property to `1` on the most recently released product ---&gt;
&lt;cfset result = model(&quot;product&quot;).updateOne(order=&quot;releaseDate DESC&quot;, new=1)&gt;

&lt;!--- If you have a `hasOne` association setup from `user` to `profile`, you can do a scoped call. (The `removeProfile` method below will call `model(&quot;profile&quot;).updateOne(where=&quot;userId=#aUser.id#&quot;, userId=&quot;&quot;)` internally.) ---&gt;
&lt;cfset aUser = model(&quot;user&quot;).findByKey(params.userId)&gt;
&lt;cfset aUser.removeProfile()&gt;</pre>
