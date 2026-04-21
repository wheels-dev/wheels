---
title: findOne()
description: "Fetches the first record found based on the WHERE and ORDER BY clauses. With the default settings (i.e. the returnAs argument set to object), a model object wil"
sidebar:
  label: findOne()
  order: 0
---

## Signature

`findOne()` — returns `any`




## Description

Fetches the first record found based on the WHERE and ORDER BY clauses. With the default settings (i.e. the returnAs argument set to object), a model object will be returned if the record is found and the boolean value false if not. Instead of using the where argument, you can create cleaner code by making use of a concept called dynamic finders.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `key` | `any` | yes | — | This argument maps to the WHERE clause of the query. The following operators are supported: =, !=, <>, <, <=, >, >=, LIKE, NOT LIKE, IN, NOT IN, IS NULL, IS NOT NULL, AND, and OR. (Note that the key words need to be written in upper case.) You can also use parentheses to group statements. You do not need to specify the table name(s); Wheels will do that for you. |
| `order` | `string` | yes | — | Maps to the ORDER BY clause of the query. You do not need to specify the table name(s); Wheels will do that for you. |
| `select` | `string` | yes | — | Determines how the SELECT clause for the query used to return data will look. You can pass in a list of the properties (which map to columns) that you want returned from your table(s). If you don't set this argument at all, Wheels will select all properties from your table(s). If you specify a table name (e.g. users.email) or alias a column (e.g.fn AS firstName) in the list, then the entire list will be passed through unchanged and used in the SELECT clause of the query. By default, all column names in tables JOINed via the include argument will be prepended with the singular version of the included table name. |
| `include` | `string` | yes | — | Associations that should be included in the query using INNER or LEFT OUTER joins (which join type that is used depends on how the association has been set up in your model). If all included associations are set on the current model, you can specify them in a list (e.g. department,addresses,emails). You can build more complex include strings by using parentheses when the association is set on an included model, like album(artist(genre)), for example. These complex include strings only work when returnAs is set to query though. |
| `cache` | `any` | yes | — | If you want to cache the query, you can do so by specifying the number of minutes you want to cache the query for here. If you set it to true, the default cache time will be used (60 minutes). |
| `reload` | `boolean` | yes | `false` | Set to true to force Wheels to query the database even though an identical query may have been run in the same request. (The default in Wheels is to get the second query from the request-level cache.) |
| `parameterize` | `any` | yes | `true` | Set to true to use cfqueryparam on all columns, or pass in a list of property names to use cfqueryparam on those only. |
| `returnAs` | `string` | yes | `objects` | Set this to objects to return an array of objects. Set this to query to return a query result set. |
| `includeSoftDeletes` | `boolean` | yes | `false` | You can set this argument to true to include soft-deleted records in the results. |

</div>

## Examples

<pre>findOne([ where, order, select, include, cache, reload, parameterize, returnAs, includeSoftDeletes ]) &lt;!--- Getting the most recent order as an object from the database ---&gt;
&lt;cfset order = model(&quot;order&quot;).findOne(order=&quot;datePurchased DESC&quot;)&gt;

&lt;!--- Using a dynamic finder to get the first person with the last name `Smith`. Same as calling `model(&quot;user&quot;).findOne(where&quot;lastName='Smith'&quot;)` ---&gt;
&lt;cfset person = model(&quot;user&quot;).findOneByLastName(&quot;Smith&quot;)&gt;

&lt;!--- Getting a specific user using a dynamic finder. Same as calling `model(&quot;user&quot;).findOne(where&quot;email='someone@somewhere.com' AND password='mypass'&quot;)` ---&gt;
&lt;cfset user = model(&quot;user&quot;).findOneByEmailAndPassword(&quot;someone@somewhere.com,mypass&quot;)&gt;

&lt;!--- If you have a `hasOne` association setup from `user` to `profile`, you can do a scoped call. (The `profile` method below will call `model(&quot;profile&quot;).findOne(where=&quot;userId=#user.id#&quot;)` internally) ---&gt;
&lt;cfset user = model(&quot;user&quot;).findByKey(params.userId)&gt;
&lt;cfset profile = user.profile()&gt;

&lt;!--- If you have a `hasMany` association setup from `post` to `comment`, you can do a scoped call. (The `findOneComment` method below will call `model(&quot;comment&quot;).findOne(where=&quot;postId=#post.id#&quot;)` internally) ---&gt;
&lt;cfset post = model(&quot;post&quot;).findByKey(params.postId)&gt;
&lt;cfset comment = post.findOneComment(where=&quot;text='I Love Wheels!'&quot;)&gt;</pre>
