---
title: findByKey()
description: "Fetches the requested record by primary key and returns it as an object."
sidebar:
  label: findByKey()
  order: 0
---

## Signature

`findByKey()` — returns `any`

**Available in:** `model`
**Category:** Read Functions

## Description

Fetches the requested record by primary key and returns it as an object.
Returns <code>false</code> if no record is found.
You can override this behavior to return a <code>cfquery</code> result set instead, similar to what's described in the documentation for <code>findOne()</code>.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `key` | `any` | yes | — | Primary key value(s) of the record. Separate with comma if passing in multiple primary key values. Accepts a string, list, or a numeric value. |
| `select` | `string` | no | — | Determines how the `SELECT` clause for the query used to return data will look. You can pass in a list of the properties (which map to columns) that you want returned from your table(s). If you don't set this argument at all, Wheels will select all properties from your table(s). If you specify a table name (e.g. `users.email`) or alias a column (e.g. `fn AS firstName`) in the list, then the entire list will be passed through unchanged and used in the `SELECT` clause of the query. By default, all column names in tables joined via the `include` argument will be prepended with the singular version of the included table name. |
| `includeCalculated` | `string` | no | — | List of calculated property names (declared via `property(name="...", sql="...", select=false)`) to additively opt into this finder's `SELECT` clause. Unlike `select`, this does not replace the default column list — the named calculated properties are merged on top of all default columns, so the rest of the record is still returned. Useful for pulling a `select=false` computed property back in on a single finder without spelling out every other column. Unknown names throw `Wheels.CalculatedPropertyNotFound` in `development`/`testing` and are ignored in `production`. |
| `include` | `string` | no | — | Associations that should be included in the query using `INNER` or `LEFT OUTER` joins (which join type that is used depends on how the association has been set up in your model). If all included associations are set on the current model, you can specify them in a list (e.g. `department,addresses,emails`). You can build more complex include strings by using parentheses when the association is set on an included model, like `album(artist(genre))`, for example. These complex `include` strings only work when `returnAs` is set to `query` though. |
| `handle` | `string` | no | `query` | Handle to use for the query. This is used to set the name of the query in the debug output (which otherwise defaults to `userFindOneQuery` for example). |
| `cache` | `any` | no | — | If you want to cache the query, you can do so by specifying the number of minutes you want to cache the query for here. If you set it to `true`, the default cache time will be used (60 minutes). |
| `reload` | `boolean` | no | `false` | Set to `true` to force Wheels to query the database even though an identical query for this model may have been run in the same request. (The default in Wheels is to get the second query from the model's request-level cache.) |
| `parameterize` | `any` | no | `true` | Set to `true` to use `cfqueryparam` on all columns, or pass in a list of property names to use `cfqueryparam` on those only. |
| `returnAs` | `string` | no | `object` | Set to `objects` to return an array of objects, set to `structs` to return an array of structs, set to `query` to return a query result set, or set to 'sql' to return the executed SQL query as a string. |
| `callbacks` | `boolean` | no | `true` | Set to `false` to disable callbacks for this method. |
| `includeSoftDeletes` | `boolean` | no | `false` | Set to `true` to include soft-deleted records in the queries that this method runs. |
| `dataSource` | `string` | no | `[runtime expression]` | Override the default datasource |

</div>

## Examples

<pre><code class='javascript'>// 1. Get the author with the primary key value `99` as an object
auth = model(&quot;author&quot;).findByKey(99);

// 2. Get an author based on a form/URL value and handle the not-found case
auth = model(&quot;author&quot;).findByKey(params.key);
if (!isObject(auth)) {
    flashInsert(message=&quot;Author #params.key# was not found&quot;);
    redirectTo(back=true);
}

// 3. Fetch only selected columns for a record
user = model(&quot;user&quot;).findByKey(key=params.id, select=&quot;id,firstName,email&quot;);

// 4. Include a belongsTo association when fetching by key
order = model(&quot;order&quot;).findByKey(key=params.orderId, include=&quot;customer&quot;);

// 5. Cache the lookup for 10 minutes and include soft-deleted records
product = model(&quot;product&quot;).findByKey(key=params.id, cache=10, includeSoftDeletes=true);

// 6. Use a scoped call via a belongsTo association (calls `model(&quot;post&quot;).findByKey(comment.postId)` internally)
comment = model(&quot;comment&quot;).findByKey(params.commentId);
post = comment.post();
</code></pre>
