---
title: count()
description: "Returns the number of rows that match the arguments (or all rows if no arguments are passed in)."
sidebar:
  label: count()
  order: 0
---

## Signature

`count()` — returns `any`

**Available in:** `model`
**Category:** Statistics Functions

## Description

Returns the number of rows that match the arguments (or all rows if no arguments are passed in).
Uses the SQL function <code>COUNT</code>.
If no records can be found to perform the calculation on, <code>0</code> is returned.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `where` | `string` | no | — | Maps to the `WHERE` clause of the query (or `HAVING` when necessary). The following operators are supported: `=`, `!=`, `<>`, `<`, `<=`, `>`, `>=`, `LIKE`, `NOT LIKE`, `IN`, `NOT IN`, `IS NULL`, `IS NOT NULL`, `AND`, and `OR` (note that the key words need to be written in upper case). You can also use parentheses to group statements. You do not need to specify the table name(s); CFWheels will do that for you. |
| `include` | `string` | no | — | Associations that should be included in the query using `INNER` or `LEFT OUTER` joins (which join type that is used depends on how the association has been set up in your model). If all included associations are set on the current model, you can specify them in a list (e.g. `department,addresses,emails`). You can build more complex include strings by using parentheses when the association is set on an included model, like `album(artist(genre))`, for example. These complex `include` strings only work when `returnAs` is set to `query` though. |
| `parameterize` | `any` | no | `true` | Set to `true` to use `cfqueryparam` on all columns, or pass in a list of property names to use `cfqueryparam` on those only. |
| `includeSoftDeletes` | `boolean` | no | `false` | Set to `true` to include soft-deleted records in the queries that this method runs. |
| `group` | `string` | no | — | Maps to the `GROUP BY` clause of the query. You do not need to specify the table name(s); CFWheels will do that for you. |

## Examples

<pre><code class='javascript'>// Count how many authors there are in the table
authorCount = model(&quot;author&quot;).count();

// Count how many authors that have a last name starting with an &quot;A&quot;
authorOnACount = model(&quot;author&quot;).count(where=&quot;lastName LIKE 'A%'&quot;);

// Count how many authors that have written books starting with an &quot;A&quot;
authorWithBooksOnACount = model(&quot;author&quot;).count(include=&quot;books&quot;, where=&quot;booktitle LIKE 'A%'&quot;);

// Count the number of comments on a specific post (a `hasMany` association from `post` to `comment` is required)
// The `commentCount` method will call `model(&quot;comment&quot;).count(where=&quot;postId=#post.id#&quot;)` internally
aPost = model(&quot;post&quot;).findByKey(params.postId);
amount = aPost.commentCount();</code></pre>
