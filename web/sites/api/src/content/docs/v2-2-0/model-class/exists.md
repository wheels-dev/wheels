---
title: exists()
description: "Checks if a record exists in the table."
sidebar:
  label: exists()
  order: 0
---

## Signature

`exists()` — returns `boolean`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Checks if a record exists in the table.
You can pass in either a primary key value to the <code>key</code> argument or a string to the <code>where</code> argument.
If you don't pass in either of those, it will simply check if any record exists in the table.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `key` | `any` | no | — | Primary key value(s) of the record. Separate with comma if passing in multiple primary key values. Accepts a string, list, or a numeric value. |
| `where` | `string` | no | — | Maps to the `WHERE` clause of the query (or `HAVING` when necessary). The following operators are supported: `=`, `!=`, `<>`, `<`, `<=`, `>`, `>=`, `LIKE`, `NOT LIKE`, `IN`, `NOT IN`, `IS NULL`, `IS NOT NULL`, `AND`, and `OR` (note that the key words need to be written in upper case). You can also use parentheses to group statements. You do not need to specify the table name(s); CFWheels will do that for you. |
| `reload` | `boolean` | no | `false` | Set to `true` to force CFWheels to query the database even though an identical query for this model may have been run in the same request. (The default in CFWheels is to get the second query from the model's request-level cache.) |
| `parameterize` | `any` | no | `true` | Set to `true` to use `cfqueryparam` on all columns, or pass in a list of property names to use `cfqueryparam` on those only. |
| `includeSoftDeletes` | `boolean` | no | — | Set to `true` to include soft-deleted records in the queries that this method runs. |

</div>

## Examples

<pre><code class='javascript'>// Checking if Joe exists in the database
result = model(&quot;user&quot;).exists(where=&quot;firstName = 'Joe'&quot;);

// Checking if a specific user exists based on a primary key valued passed in through the URL/form in an if statement
if (model(&quot;user&quot;).exists(keyparams.key))
{
	// Do something
}

// If you have a `belongsTo` association setup from `comment` to `post`, you can do a scoped call. (The `hasPost` method below will call `model(&quot;post&quot;).exists(comment.postId)` internally.)
comment = model(&quot;comment&quot;).findByKey(params.commentId);
commentHasAPost = comment.hasPost();

// If you have a `hasOne` association setup from `user` to `profile`, you can do a scoped call. (The `hasProfile` method below will call `model(&quot;profile&quot;).exists(where=&quot;userId=#user.id#&quot;)` internally.)
user = model(&quot;user&quot;).findByKey(params.userId);
userHasProfile = user.hasProfile();

// If you have a `hasMany` association setup from `post` to `comment`, you can do a scoped call. (The `hasComments` method below will call `model(&quot;comment&quot;).exists(where=&quot;postid=#post.id#&quot;)` internally.)
post = model(&quot;post&quot;).findByKey(params.postId);
postHasComments = post.hasComments();</code></pre>
