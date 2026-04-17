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

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `key` | `any` | yes | — | Primary key value(s) of the record. Separate with comma if passing in multiple primary key values. Accepts a string, list, or a numeric value. |
| `select` | `string` | no | — | Determines how the `SELECT` clause for the query used to return data will look. You can pass in a list of the properties (which map to columns) that you want returned from your table(s). If you don't set this argument at all, CFWheels will select all properties from your table(s). If you specify a table name (e.g. `users.email`) or alias a column (e.g. `fn AS firstName`) in the list, then the entire list will be passed through unchanged and used in the `SELECT` clause of the query. By default, all column names in tables joined via the `include` argument will be prepended with the singular version of the included table name. |
| `include` | `string` | no | — | Associations that should be included in the query using `INNER` or `LEFT OUTER` joins (which join type that is used depends on how the association has been set up in your model). If all included associations are set on the current model, you can specify them in a list (e.g. `department,addresses,emails`). You can build more complex include strings by using parentheses when the association is set on an included model, like `album(artist(genre))`, for example. These complex `include` strings only work when `returnAs` is set to `query` though. |
| `handle` | `string` | no | `query` | Handle to use for the query. This is used to set the name of the query in the debug output (which otherwise defaults to `userFindOneQuery` for example). |
| `cache` | `any` | no | — | If you want to cache the query, you can do so by specifying the number of minutes you want to cache the query for here. If you set it to `true`, the default cache time will be used (60 minutes). |
| `reload` | `boolean` | no | `false` | Set to `true` to force CFWheels to query the database even though an identical query for this model may have been run in the same request. (The default in CFWheels is to get the second query from the model's request-level cache.) |
| `parameterize` | `any` | no | `true` | Set to `true` to use `cfqueryparam` on all columns, or pass in a list of property names to use `cfqueryparam` on those only. |
| `returnAs` | `string` | no | `object` | Set to `objects` to return an array of objects, set to `structs` to return an array of structs, or set to `query` to return a query result set. |
| `callbacks` | `boolean` | no | `true` | Set to `false` to disable callbacks for this method. |
| `includeSoftDeletes` | `boolean` | no | `false` | Set to `true` to include soft-deleted records in the queries that this method runs. |

## Examples

<pre><code class='javascript'>// Getting the author with the primary key value `99` as an object
auth = model(&quot;author&quot;).findByKey(99);

// Getting an author based on a form/URL value and then checking if it was found
auth = model(&quot;author&quot;).findByKey(params.key);
if(!isObject(auth)){
    flashInsert(message=&quot;Author #params.key# was not found&quot;);
    redirectTo(back=true);
}

// If you have a `belongsTo` association setup from `comment` to `post`, you can do a scoped call. (The `post` method below will call `model(&quot;post&quot;).findByKey(comment.postId)` internally)
comment = model(&quot;comment&quot;).findByKey(params.commentId);
post = comment.post();</code></pre>
