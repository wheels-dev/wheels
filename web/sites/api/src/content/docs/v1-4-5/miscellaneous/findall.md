---
title: findAll()
description: "Returns records from the database table mapped to this model according to the arguments passed in (use the where argument to decide which records to get, use th"
sidebar:
  label: findAll()
  order: 0
---

## Signature

`findAll()` — returns `any`




## Description

Returns records from the database table mapped to this model according to the arguments passed in (use the where argument to decide which records to get, use the order argument to set the order in which those records should be returned, and so on). The records will be returned as either a cfquery result set, an array of objects, or an array of structs (depending on what the returnAs argument is set to).

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `where` | `string` | yes | — | This argument maps to the WHERE clause of the query. The following operators are supported: =, !=, <>, <, <=, >, >=, LIKE, NOT LIKE, IN, NOT IN, IS NULL, IS NOT NULL, AND, and OR (note that the key words need to be written in upper case). You can also use parentheses to group statements. You do not need to specify the table name(s); CFWheels will do that for you. Instead of using the where argument, you can create cleaner code by making use of a concept called Dynamic Finders. |
| `order` | `string` | yes | — | Maps to the ORDER BY clause of the query. You do not need to specify the table name(s); Wheels will do that for you. |
| `group` | `string` | yes | — | Maps to the GROUP BY clause of the query. You do not need to specify the table name(s); CFWheels will do that for you. |
| `select` | `string` | yes | — | Determines how the SELECT clause for the query used to return data will look. You can pass in a list of the properties (which map to columns) that you want returned from your table(s). If you don't set this argument at all, Wheels will select all properties from your table(s). If you specify a table name (e.g. users.email) or alias a column (e.g.fn AS firstName) in the list, then the entire list will be passed through unchanged and used in the SELECT clause of the query. By default, all column names in tables JOINed via the include argument will be prepended with the singular version of the included table name. |
| `distinct` | `boolean` | yes | `false` | Whether to add the DISTINCT keyword to your SELECT clause. Wheels will, when necessary, add this automatically (when using pagination and a hasMany association is used in the include argument, to name one example). |
| `include` | `string` | yes | — | Associations that should be included in the query using INNER or LEFT OUTER joins (which join type that is used depends on how the association has been set up in your model). If all included associations are set on the current model, you can specify them in a list (e.g. department,addresses,emails). You can build more complex include strings by using parentheses when the association is set on an included model, like album(artist(genre)), for example. These complex include strings only work when returnAs is set to query though. |
| `maxRows` | `numeric` | yes | `-1` | Maximum number of records to retrieve. Passed on to the maxRows cfquery attribute. The default, -1, means that all records will be retrieved. |
| `page` | `numeric` | yes | `0` | If you want to paginate records, you can do so by specifying a page number here. For example, getting records 11-20 would be page number 2 when perPage is kept at the default setting (10 records per page). The default, 0, means that records won't be paginated and that the perPage, count, and handle arguments will be ignored. |
| `perPage` | `numeric` | yes | `10` | When using pagination, you can specify how many records you want to fetch per page here. This argument is only used when the page argument has been passed in. |
| `count` | `numeric` | yes | `0` | When using pagination and you know in advance how many records you want to paginate through, you can pass in that value here. Doing so will prevent Wheels from running a COUNT query to get this value. This argument is only used when the page argument has been passed in. |
| `handle` | `string` | yes | `query` | Handle to use for the query in pagination. This is useful when you're paginating multiple queries and need to reference them in the paginationLinks() function, for example. This argument is only used when the page argument has been passed in. |
| `cache` | `any` | yes | — | If you want to cache the query, you can do so by specifying the number of minutes you want to cache the query for here. If you set it to true, the default cache time will be used (60 minutes). |
| `reload` | `boolean` | yes | `false` | Set to true to force CFWheels to query the database even though an identical query may have been run in the same request. (The default in CFWheels is to get the second query from the request-level cache.) |
| `parameterize` | `any` | yes | `true` | Set to true to use cfqueryparam on all columns, or pass in a list of property names to use cfqueryparam on those only. |
| `returnAs` | `string` | yes | `query` | Set to objects to return an array of objects, set to structs to return an array of structs, or set to query to return a query result set. |
| `returnIncluded` | `boolean` | yes | `true` | When returnAs is set to objects, you can set this argument to false to prevent returning objects fetched from associations specified in the include argument. This is useful when you only need to include associations for use in the WHERE clause only and want to avoid the performance hit that comes with object creation. |
| `callbacks` | `boolean` | yes | `true` | You can set this argument to false to prevent running the execution of callbacks for a method call. |
| `includeSoftDeletes` | `boolean` | yes | `false` | You can set this argument to true to include soft-deleted records in the results. |

## Examples

<pre>&lt;!--- Getting only 5 users and ordering them randomly ---&gt; &lt;cfset fiveRandomUsers = model(&quot;user&quot;).findAll(maxRows=5, order=&quot;random&quot;)&gt; &lt;!--- Including an association (which in this case needs to be setup as a `belongsTo` association to `author` on the `article` model first) ---&gt; &lt;cfset articles = model(&quot;article&quot;).findAll( include=&quot;author&quot;, where=&quot;published=1&quot;, order=&quot;createdAt DESC&quot; )&gt; &lt;!--- Similar to the above but using the association in the opposite direction (which needs to be setup as a `hasMany` association to `article` on the `author` model) ---&gt; &lt;cfset bobsArticles = model(&quot;author&quot;).findAll( include=&quot;articles&quot;, where=&quot;firstName='Bob'&quot; )&gt; &lt;!--- Using pagination (getting records 26-50 in this case) and a more complex way to include associations (a song `belongsTo` an album, which in turn `belongsTo` an artist) ---&gt; &lt;cfset songs = model(&quot;song&quot;).findAll( include=&quot;album(artist)&quot;, page=2, perPage=25 )&gt; &lt;!--- Using a dynamic finder to get all books released a certain year. Same as calling model(&quot;book&quot;).findOne(where=&quot;releaseYear=#params.year#&quot;) ---&gt; &lt;cfset books = model(&quot;book&quot;).findAllByReleaseYear(params.year)&gt; &lt;!--- Getting all books of a certain type from a specific year by using a dynamic finder. Same as calling model(&quot;book&quot;).findAll( where=&quot;releaseYear=#params.year# AND type='#params.type#'&quot; ) ---&gt; &lt;cfset books = model(&quot;book&quot;).findAllByReleaseYearAndType( &quot;#params.year#,#params.type#&quot; )&gt; &lt;!--- If you have a `hasMany` association setup from `post` to `comment`, you can do a scoped call. (The `comments` method below will call `model(&quot;comment&quot;).findAll(where=&quot;postId=#post.id#&quot;)` internally) ---&gt; &lt;cfset post = model(&quot;post&quot;).findByKey(params.postId)&gt; &lt;cfset comments = post.comments()&gt;</pre>
