---
title: findOne()
description: "Fetches the first record found based on the <code>WHERE</code> and <code>ORDER BY</code> clauses."
sidebar:
  label: findOne()
  order: 0
---

## Signature

`findOne()` — returns `any`

**Available in:** `model`
**Category:** Read Functions

## Description

Fetches the first record found based on the <code>WHERE</code> and <code>ORDER BY</code> clauses.
With the default settings (i.e. the <code>returnAs</code> argument set to <code>object</code>), a model object will be returned if the record is found and the boolean value <code>false</code> if not.
Instead of using the <code>where</code> argument, you can create cleaner code by making use of a concept called Dynamic Finders.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `where` | `string` | no | — | Maps to the `WHERE` clause of the query (or `HAVING` when necessary). The following operators are supported: `=`, `!=`, `<>`, `<`, `<=`, `>`, `>=`, `LIKE`, `NOT LIKE`, `IN`, `NOT IN`, `IS NULL`, `IS NOT NULL`, `AND`, and `OR` (note that the key words need to be written in upper case). You can also use parentheses to group statements. You do not need to specify the table name(s); CFWheels will do that for you. |
| `order` | `string` | no | — | Maps to the `ORDER` BY clause of the query. You do not need to specify the table name(s); CFWheels will do that for you. |
| `select` | `string` | no | — | Determines how the `SELECT` clause for the query used to return data will look. You can pass in a list of the properties (which map to columns) that you want returned from your table(s). If you don't set this argument at all, CFWheels will select all properties from your table(s). If you specify a table name (e.g. `users.email`) or alias a column (e.g. `fn AS firstName`) in the list, then the entire list will be passed through unchanged and used in the `SELECT` clause of the query. By default, all column names in tables joined via the `include` argument will be prepended with the singular version of the included table name. |
| `include` | `string` | no | — | Associations that should be included in the query using `INNER` or `LEFT OUTER` joins (which join type that is used depends on how the association has been set up in your model). If all included associations are set on the current model, you can specify them in a list (e.g. `department,addresses,emails`). You can build more complex include strings by using parentheses when the association is set on an included model, like `album(artist(genre))`, for example. These complex `include` strings only work when `returnAs` is set to `query` though. |
| `handle` | `string` | no | `query` | Handle to use for the query. This is used to set the name of the query in the debug output (which otherwise defaults to `userFindOneQuery` for example). |
| `cache` | `any` | no | — | If you want to cache the query, you can do so by specifying the number of minutes you want to cache the query for here. If you set it to `true`, the default cache time will be used (60 minutes). |
| `reload` | `boolean` | no | `false` | Set to `true` to force CFWheels to query the database even though an identical query for this model may have been run in the same request. (The default in CFWheels is to get the second query from the model's request-level cache.) |
| `parameterize` | `any` | no | `true` | Set to `true` to use `cfqueryparam` on all columns, or pass in a list of property names to use `cfqueryparam` on those only. |
| `returnAs` | `string` | no | `object` | Set to `objects` to return an array of objects, set to `structs` to return an array of structs, or set to `query` to return a query result set. |
| `includeSoftDeletes` | `boolean` | no | `false` | Set to `true` to include soft-deleted records in the queries that this method runs. |
| `useIndex` | `struct` | no | `[runtime expression]` | If you want to specify table index hints, pass in a structure of index names using your model names as the structure keys. Eg: `{user="idx_users", post="idx_posts"}`. This feature is only supported by MySQL and SQL Server. |

## Examples

<pre><code class='javascript'>// Getting the most recent order as an object from the database
order = model(&quot;order&quot;).findOne(order=&quot;datePurchased DESC&quot;);

// Using a dynamic finder to get the first person with the last name `Smith`. Same as calling `model(&quot;user&quot;).findOne(where&quot;lastName='Smith'&quot;)`
person = model(&quot;user&quot;).findOneByLastName(&quot;Smith&quot;);

// Getting a specific user using a dynamic finder. Same as calling `model(&quot;user&quot;).findOne(where&quot;email='someone@somewhere.com' AND password='mypass'&quot;)`
user = model(&quot;user&quot;).findOneByEmailAndPassword(&quot;someone@somewhere.com,mypass&quot;);

// If you have a `hasOne` association setup from `user` to `profile`, you can do a scoped call. (The `profile` method below will call `model(&quot;profile&quot;).findOne(where=&quot;userId=#user.id#&quot;)` internally)
user = model(&quot;user&quot;).findByKey(params.userId);
profile = user.profile();

// If you have a `hasMany` association setup from `post` to `comment`, you can do a scoped call. (The `findOneComment` method below will call `model(&quot;comment&quot;).findOne(where=&quot;postId=#post.id#&quot;)` internally)
post = model(&quot;post&quot;).findByKey(params.postId);
comment = post.findOneComment(where=&quot;text='I Love Wheels!'&quot;);</code></pre>
