---
title: findByKey()
description: "Fetches the requested record by primary key and returns it as an object. Returns false if no record is found. You can override this behavior to return a cfquery"
sidebar:
  label: findByKey()
  order: 0
---

## Signature

`findByKey()` — returns `any`




## Description

Fetches the requested record by primary key and returns it as an object. Returns false if no record is found. You can override this behavior to return a cfquery result set instead, similar to what's described in the documentation for findOne().

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `key` | `any` | yes | — | Primary key value(s) of the record. Separate with comma if passing in multiple primary key values. Accepts a string, list, or a numeric value. |
| `select` | `string` | yes | — | Determines how the SELECT clause for the query used to return data will look. You can pass in a list of the properties (which map to columns) that you want returned from your table(s). If you don't set this argument at all, Wheels will select all properties from your table(s). If you specify a table name (e.g. users.email) or alias a column (e.g.fn AS firstName) in the list, then the entire list will be passed through unchanged and used in the SELECT clause of the query. By default, all column names in tables JOINed via the include argument will be prepended with the singular version of the included table name. |
| `include` | `string` | yes | — | Associations that should be included in the query using INNER or LEFT OUTER joins (which join type that is used depends on how the association has been set up in your model). If all included associations are set on the current model, you can specify them in a list (e.g. department,addresses,emails). You can build more complex include strings by using parentheses when the association is set on an included model, like album(artist(genre)), for example. These complex include strings only work when returnAs is set to query though. |
| `cache` | `any` | yes | — | If you want to cache the query, you can do so by specifying the number of minutes you want to cache the query for here. If you set it to true, the default cache time will be used (60 minutes). |
| `reload` | `boolean` | yes | `false` | Set to true to force Wheels to query the database even though an identical query may have been run in the same request. (The default in Wheels is to get the second query from the request-level cache.) |
| `parameterize` | `any` | yes | `true` | Set to true to use cfqueryparam on all columns, or pass in a list of property names to use cfqueryparam on those only. |
| `returnAs` | `string` | yes | `objects` | Set this to objects to return an array of objects. Set this to query to return a query result set. |
| `callbacks` | `boolean` | yes | `true` | You can set this argument to false to prevent running the execution of callbacks for a method call. |
| `includeSoftDeletes` | `boolean` | yes | `false` | You can set this argument to true to include soft-deleted records in the results. |

</div>

## Examples

<pre>&lt;!--- Getting the author with the primary key value `99` as an object ---&gt;
&lt;cfset auth = model(&quot;author&quot;).findByKey(99)&gt;

&lt;!--- Getting an author based on a form/URL value and then checking if it was found ---&gt;
&lt;cfset auth = model(&quot;author&quot;).findByKey(params.key)&gt;
&lt;cfif NOT IsObject(auth)&gt;
    &lt;cfset flashInsert(message=&quot;Author #params.key# was not found&quot;)&gt;
    &lt;cfset redirectTo(back=true)&gt;
&lt;/cfif&gt;

&lt;!--- If you have a `belongsTo` association setup from `comment` to `post`, you can do a scoped call. (The `post` method below will call `model(&quot;post&quot;).findByKey(comment.postId)` internally) ---&gt;
&lt;cfset comment = model(&quot;comment&quot;).findByKey(params.commentId)&gt;
&lt;cfset post = comment.post()&gt;</pre>
