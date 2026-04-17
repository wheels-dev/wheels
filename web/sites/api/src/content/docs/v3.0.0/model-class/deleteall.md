---
title: deleteAll()
description: "Deletes all records that match the <code>where</code> argument."
sidebar:
  label: deleteAll()
  order: 0
---

## Signature

`deleteAll()` — returns `numeric`

**Available in:** `model`
**Category:** Delete Functions

## Description

Deletes all records that match the <code>where</code> argument.
By default, objects will not be instantiated and therefore callbacks and validations are not invoked.
You can change this behavior by passing in <code>instantiate=true</code>.
Returns the number of records that were deleted.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `where` | `string` | no | — | Maps to the `WHERE` clause of the query (or `HAVING` when necessary). The following operators are supported: `=`, `!=`, `<>`, `<`, `<=`, `>`, `>=`, `LIKE`, `NOT LIKE`, `IN`, `NOT IN`, `IS NULL`, `IS NOT NULL`, `AND`, and `OR` (note that the key words need to be written in upper case). You can also use parentheses to group statements. Nested queries not allowed. You do not need to specify the table name(s); Wheels will do that for you. |
| `include` | `string` | no | — | Associations that should be included in the query using `INNER` or `LEFT OUTER` joins (which join type that is used depends on how the association has been set up in your model). If all included associations are set on the current model, you can specify them in a list (e.g. `department,addresses,emails`). You can build more complex include strings by using parentheses when the association is set on an included model, like `album(artist(genre))`, for example. These complex `include` strings only work when `returnAs` is set to `query` though. |
| `reload` | `boolean` | no | `false` | Set to `true` to force Wheels to query the database even though an identical query for this model may have been run in the same request. (The default in Wheels is to get the second query from the model's request-level cache.) |
| `parameterize` | `any` | no | `true` | Set to `true` to use `cfqueryparam` on all columns, or pass in a list of property names to use `cfqueryparam` on those only. |
| `instantiate` | `boolean` | no | `false` | Whether or not to instantiate the object(s) first. When objects are not instantiated, any callbacks and validations set on them will be skipped. |
| `transaction` | `string` | no | `[runtime expression]` | Set this to `commit` to update the database, `rollback` to run all the database queries but not commit them, or `none` to skip transaction handling altogether. |
| `callbacks` | `boolean` | no | `true` | Set to `false` to disable callbacks for this method. |
| `useIndex` | `struct` | no | `[runtime expression]` | If you want to specify table index hints, pass in a structure of index names using your model names as the structure keys. Eg: `{user="idx_users", post="idx_posts"}`. This feature is only supported by MySQL and SQL Server. |
| `includeSoftDeletes` | `boolean` | no | `false` | Set to `true` to include soft-deleted records in the queries that this method runs. |
| `softDelete` | `boolean` | no | `true` | Set to `false` to permanently delete a record, even if it has a soft delete column. |

## Examples

<pre><code class='javascript'>Example 1: Delete inactive users (skip callbacks and validations)
&lt;cfscript&gt;
recordsDeleted = model("user").deleteAll(where="inactive=1", instantiate=false);
writeOutput("Deleted #recordsDeleted# inactive users.");
&lt;/cfscript&gt;

Deletes all users where inactive=1.

Objects are not instantiated, so callbacks and validations are skipped.

Example 2: Scoped delete using an association
&lt;cfscript&gt;
post = model("post").findByKey(params.postId);

// Deletes all comments associated with this post
howManyDeleted = post.deleteAllComments();
writeOutput("Deleted #howManyDeleted# comments for this post.");
&lt;/cfscript&gt;

Assumes a hasMany association from post → comment.

Internally calls model("comment").deleteAll(where="postId=#post.id#").

Example 3: Delete and run callbacks
&lt;cfscript&gt;
recordsDeleted = model("user").deleteAll(where="inactive=1", instantiate=true, callbacks=true);
&lt;/cfscript&gt;

Deletes the records after instantiating the objects.

Any beforeDelete or afterDelete callbacks are triggered.</code></pre>
