---
title: updateAll()
description: "Updates all properties for the records that match the <code>where</code> argument."
sidebar:
  label: updateAll()
  order: 0
---

## Signature

`updateAll()` — returns `numeric`

**Available in:** `model`
**Category:** Update Functions

## Description

Updates all properties for the records that match the <code>where</code> argument.
Property names and values can be passed in either using named arguments or as a struct to the <code>properties</code> argument.
By default, objects will not be instantiated and therefore callbacks and validations are not invoked.
You can change this behavior by passing in <code>instantiate=true</code>.
This method returns the number of records that were updated.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `where` | `string` | no | — | Maps to the `WHERE` clause of the query (or `HAVING` when necessary). The following operators are supported: `=`, `!=`, `<>`, `<`, `<=`, `>`, `>=`, `LIKE`, `NOT LIKE`, `IN`, `NOT IN`, `IS NULL`, `IS NOT NULL`, `AND`, and `OR` (note that the key words need to be written in upper case). You can also use parentheses to group statements. Nested queries not allowed. You do not need to specify the table name(s); Wheels will do that for you. |
| `include` | `string` | no | — | Associations that should be included in the query using `INNER` or `LEFT OUTER` joins (which join type that is used depends on how the association has been set up in your model). If all included associations are set on the current model, you can specify them in a list (e.g. `department,addresses,emails`). You can build more complex include strings by using parentheses when the association is set on an included model, like `album(artist(genre))`, for example. These complex `include` strings only work when `returnAs` is set to `query` though. |
| `properties` | `struct` | no | `[runtime expression]` | The properties you want to set on the object (can also be passed in as named arguments). |
| `reload` | `boolean` | no | `false` | Set to `true` to force Wheels to query the database even though an identical query for this model may have been run in the same request. (The default in Wheels is to get the second query from the model's request-level cache.) |
| `parameterize` | `any` | no | `true` | Set to `true` to use `cfqueryparam` on all columns, or pass in a list of property names to use `cfqueryparam` on those only. |
| `instantiate` | `boolean` | no | `false` | Whether or not to instantiate the object(s) first. When objects are not instantiated, any callbacks and validations set on them will be skipped. |
| `validate` | `boolean` | no | `true` | Set to `false` to skip validations for this operation. |
| `transaction` | `string` | no | `[runtime expression]` | Set this to `commit` to update the database, `rollback` to run all the database queries but not commit them, or `none` to skip transaction handling altogether. |
| `callbacks` | `boolean` | no | `true` | Set to `false` to disable callbacks for this method. |
| `useIndex` | `struct` | no | `[runtime expression]` | If you want to specify table index hints, pass in a structure of index names using your model names as the structure keys. Eg: `{user="idx_users", post="idx_posts"}`. This feature is only supported by MySQL and SQL Server. |
| `includeSoftDeletes` | `boolean` | no | `false` | Set to `true` to include soft-deleted records in the queries that this method runs. |

## Examples

<pre><code class='javascript'>1. Update all posts that are unpublished
recordsUpdated = model(&quot;post&quot;).updateAll(
 published=1,
 publishedAt=Now(),
 where=&quot;published=0&quot;
)

2. Scoped update for a hasMany association (removing all comments)
post = model(&quot;post&quot;).findByKey(params.postId);
post.removeAllComments(); 
// Internally calls: model(&quot;comment&quot;).updateAll(postId=&quot;&quot;, where=&quot;postId=#post.id#&quot;)

3. Update all users and force validations and callbacks
recordsUpdated = model(&quot;user&quot;).updateAll(
 properties={isActive=true},
 instantiate=true,
 validate=true
)

4. Using index hints for MySQL
recordsUpdated = model(&quot;user&quot;).updateAll(
 properties={isVerified=true},
 where=&quot;isVerified=0&quot;,
 useIndex={user=&quot;idx_users_isVerified&quot;}
)
</code></pre>
