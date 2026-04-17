---
title: deleteAll()
description: "Deletes all records that match the where argument. By default, objects will not be instantiated and therefore callbacks and validations are not invoked. You can"
sidebar:
  label: deleteAll()
  order: 0
---

## Signature

`deleteAll()` — returns `any`




## Description

Deletes all records that match the where argument. By default, objects will not be instantiated and therefore callbacks and validations are not invoked. You can change this behavior by passing in instantiate=true. Returns the number of records that were deleted.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `where` | `string` | yes | — | This argument maps to the WHERE clause of the query. The following operators are supported: =, !=, <>, <, <=, >, >=, LIKE, NOT LIKE, IN, NOT IN, IS NULL, IS NOT NULL, AND, and OR. (Note that the key words need to be written in upper case.) You can also use parentheses to group statements. You do not need to specify the table name(s); Wheels will do that for you. |
| `include` | `string` | yes | — | Associations that should be included in the query using INNER or LEFT OUTER joins (which join type that is used depends on how the association has been set up in your model). If all included associations are set on the current model, you can specify them in a list (e.g. department,addresses,emails). You can build more complex include strings by using parentheses when the association is set on an included model, like album(artist(genre)), for example. These complex include strings only work when returnAs is set to query though. |
| `reload` | `boolean` | yes | `false` | Set to true to force Wheels to query the database even though an identical query may have been run in the same request. (The default in Wheels is to get the second query from the request-level cache.) |
| `parameterize` | `any` | yes | `true` | Set to true to use cfqueryparam on all columns, or pass in a list of property names to use cfqueryparam on those only. |
| `instantiate` | `boolean` | yes | `false` | Whether or not to instantiate the object(s) first. When objects are not instantiated, any callbacks and validations set on them will be skipped. |
| `transaction` | `string` | yes | `[runtime expression]` | Set this to commit to update the database when the save has completed, rollback to run all the database queries but not commit them, or none to skip transaction handling altogether. |
| `callbacks` | `boolean` | yes | `true` | Set to false to disable callbacks for this operation. |
| `includeSoftDeletes` | `boolean` | yes | `false` | You can set this argument to true to include soft-deleted records in the results. |
| `softDelete` | `boolean` | yes | `true` | Set to false to permanently delete a record, even if it has a soft delete column. |

## Examples

<pre>deleteAll([ where, include, reload, parameterize, instantiate, transaction, callbacks, includeSoftDeletes, softDelete ]) &lt;!--- Delete all inactive users without instantiating them (will skip validation and callbacks) ---&gt;
&lt;cfset recordsDeleted = model(&quot;user&quot;).deleteAll(where=&quot;inactive=1&quot;, instantiate=false)&gt;

&lt;!--- If you have a `hasMany` association setup from `post` to `comment`, you can do a scoped call. (The `deleteAllComments` method below will call `model(&quot;comment&quot;).deleteAll(where=&quot;postId=#post.id#&quot;)` internally.) ---&gt;
&lt;cfset post = model(&quot;post&quot;).findByKey(params.postId)&gt;
&lt;cfset howManyDeleted = post.deleteAllComments()&gt;</pre>
