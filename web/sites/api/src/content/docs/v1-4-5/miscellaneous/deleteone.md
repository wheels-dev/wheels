---
title: deleteOne()
description: "Gets an object based on conditions and deletes it."
sidebar:
  label: deleteOne()
  order: 0
---

## Signature

`deleteOne()` — returns `any`




## Description

Gets an object based on conditions and deletes it.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `where` | `string` | yes | — | This argument maps to the WHERE clause of the query. The following operators are supported: =, !=, <>, <, <=, >, >=, LIKE, NOT LIKE, IN, NOT IN, IS NULL, IS NOT NULL, AND, and `OR. (Note that the key words need to be written in upper case.) You can also use parentheses to group statements. You do not need to specify the table name(s); Wheels will do that for you. |
| `order` | `string` | yes | — | Maps to the ORDER BY clause of the query. You do not need to specify the table name(s); Wheels will do that for you. |
| `reload` | `boolean` | yes | `false` | Set to true to force Wheels to query the database even though an identical query may have been run in the same request. (The default in Wheels is to get the second query from the request-level cache.) |
| `transaction` | `string` | yes | `[runtime expression]` | Set this to commit to update the database when the save has completed, rollback to run all the database queries but not commit them, or none to skip transaction handling altogether. |
| `callbacks` | `boolean` | yes | `true` | Set to false to disable callbacks for this operation. |
| `includeSoftDeletes` | `boolean` | yes | `false` | You can set this argument to true to include soft-deleted records in the results. |
| `softDelete` | `boolean` | yes | `true` | Set to false to permanently delete a record, even if it has a soft delete column. |

</div>

## Examples

<pre>deleteOne([ where, order, reload, transaction, callbacks, includeSoftDeletes, softDelete ]) &lt;!--- Delete the user that signed up last ---&gt;
&lt;cfset result = model(&quot;user&quot;).deleteOne(order=&quot;signupDate DESC&quot;)&gt;

&lt;!--- If you have a `hasOne` association setup from `user` to `profile` you can do a scoped call (the `deleteProfile` method below will call `model(&quot;profile&quot;).deleteOne(where=&quot;userId=#aUser.id#&quot;)` internally) ---&gt;
&lt;cfset aUser = model(&quot;user&quot;).findByKey(params.userId)&gt;
&lt;cfset aUser.deleteProfile()&gt;</pre>
