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

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `where` | `string` | no | — | Maps to the `WHERE` clause of the query (or `HAVING` when necessary). The following operators are supported: `=`, `!=`, `<>`, `<`, `<=`, `>`, `>=`, `LIKE`, `NOT LIKE`, `IN`, `NOT IN`, `IS NULL`, `IS NOT NULL`, `AND`, and `OR` (note that the key words need to be written in upper case). You can also use parentheses to group statements. Nested queries not allowed. You do not need to specify the table name(s); Wheels will do that for you. |
| `order` | `string` | no | — | Maps to the `ORDER` BY clause of the query. You do not need to specify the table name(s); Wheels will do that for you. |
| `select` | `string` | no | — | Determines how the `SELECT` clause for the query used to return data will look. You can pass in a list of the properties (which map to columns) that you want returned from your table(s). If you don't set this argument at all, Wheels will select all properties from your table(s). If you specify a table name (e.g. `users.email`) or alias a column (e.g. `fn AS firstName`) in the list, then the entire list will be passed through unchanged and used in the `SELECT` clause of the query. By default, all column names in tables joined via the `include` argument will be prepended with the singular version of the included table name. |
| `includeCalculated` | `string` | no | — | List of calculated property names (declared via `property(name="...", sql="...", select=false)`) to additively opt into this finder's `SELECT` clause. Unlike `select`, this does not replace the default column list — the named calculated properties are merged on top of all default columns, so the rest of the record is still returned. Useful for pulling a `select=false` computed property back in on a single finder without spelling out every other column. Unknown names throw `Wheels.CalculatedPropertyNotFound` in `development`/`testing` and are ignored in `production`. |
| `include` | `string` | no | — | Associations that should be included in the query using `INNER` or `LEFT OUTER` joins (which join type that is used depends on how the association has been set up in your model). If all included associations are set on the current model, you can specify them in a list (e.g. `department,addresses,emails`). You can build more complex include strings by using parentheses when the association is set on an included model, like `album(artist(genre))`, for example. These complex `include` strings only work when `returnAs` is set to `query` though. |
| `handle` | `string` | no | `query` | Handle to use for the query. This is used to set the name of the query in the debug output (which otherwise defaults to `userFindOneQuery` for example). |
| `cache` | `any` | no | — | If you want to cache the query, you can do so by specifying the number of minutes you want to cache the query for here. If you set it to `true`, the default cache time will be used (60 minutes). |
| `reload` | `boolean` | no | `false` | Set to `true` to force Wheels to query the database even though an identical query for this model may have been run in the same request. (The default in Wheels is to get the second query from the model's request-level cache.) |
| `parameterize` | `any` | no | `true` | Set to `true` to use `cfqueryparam` on all columns, or pass in a list of property names to use `cfqueryparam` on those only. |
| `returnAs` | `string` | no | `object` | Set to `objects` to return an array of objects, set to `structs` to return an array of structs, set to `query` to return a query result set, or set to 'sql' to return the executed SQL query as a string. |
| `includeSoftDeletes` | `boolean` | no | `false` | Set to `true` to include soft-deleted records in the queries that this method runs. |
| `useIndex` | `struct` | no | `[runtime expression]` | If you want to specify table index hints, pass in a structure of index names using your model names as the structure keys. Eg: `{user="idx_users", post="idx_posts"}`. This feature is only supported by MySQL and SQL Server. |
| `dataSource` | `string` | no | `[runtime expression]` | Override the default datasource |

</div>

## Examples

<pre><code class='javascript'>// 1. Get the most recent order as an object from the database
order = model(&quot;Order&quot;).findOne(order=&quot;datePurchased DESC&quot;);

// 2. Use a where clause to find the first user with a specific email address
user = model(&quot;User&quot;).findOne(where=&quot;email='someone@example.com'&quot;);

// 3. Use a dynamic finder to get the first person with the last name Smith.
// Equivalent to: model(&quot;User&quot;).findOne(where=&quot;lastName='Smith'&quot;)
person = model(&quot;User&quot;).findOneByLastName(&quot;Smith&quot;);

// 4. Use a dynamic finder to match on two columns.
// Equivalent to: model(&quot;User&quot;).findOne(where=&quot;email='someone@example.com' AND password='mypass'&quot;)
user = model(&quot;User&quot;).findOneByEmailAndPassword(&quot;someone@example.com&quot;, &quot;mypass&quot;);

// 5. Return false when no matching record is found (the default returnAs=&quot;object&quot; behavior)
user = model(&quot;User&quot;).findOne(where=&quot;email='unknown@example.com'&quot;);
if (!isObject(user)) {
    writeOutput(&quot;No user found.&quot;);
}

// 6. Return as a query result set instead of an object
userQuery = model(&quot;User&quot;).findOne(where=&quot;role='admin'&quot;, returnAs=&quot;query&quot;);

// 7. Use a scoped call via a hasOne association from User to Profile.
// The profile() method calls model(&quot;Profile&quot;).findOne(where=&quot;userId=#user.id#&quot;) internally.
user = model(&quot;User&quot;).findByKey(params.userId);
profile = user.profile();

// 8. Use a scoped call via a hasMany association from Post to Comment.
// The findOneComment() method calls model(&quot;Comment&quot;).findOne(where=&quot;postId=#post.id#&quot;) internally.
post = model(&quot;Post&quot;).findByKey(params.postId);
comment = post.findOneComment(where=&quot;approved=1&quot;);
</code></pre>
