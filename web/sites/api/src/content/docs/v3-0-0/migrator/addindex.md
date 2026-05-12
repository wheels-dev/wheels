---
title: addIndex()
description: "Adds a database index on one or more columns of a table. Indexes speed up queries that filter, sort, or join on those columns. This function is only available i"
sidebar:
  label: addIndex()
  order: 0
---

## Signature

`addIndex()` — returns `void`

**Available in:** `migration`
**Category:** Migration Functions

## Description

Adds a database index on one or more columns of a table. Indexes speed up queries that filter, sort, or join on those columns. This function is only available inside a migration CFC and is part of the Wheels migrator API.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `table` | `string` | yes | — | The table name to perform the index operation on |
| `columnNames` | `string` | no | — | One or more column names to index, comma separated |
| `unique` | `boolean` | no | `false` | If true will create a unique index constraint |
| `indexName` | `string` | no | `[runtime expression]` | The name of the index to add: Defaults to table name + underscore + first column name |

</div>

## Examples

<pre><code class='javascript'>1. Add a unique index on a single column
addIndex(
    table=&quot;members&quot;,
    columnNames=&quot;username&quot;,
    unique=true
);

Ensures username values in members are unique.

2. Add a non-unique index for faster queries
addIndex(
    table=&quot;orders&quot;,
    columnNames=&quot;createdAt&quot;
);

Speeds up queries filtering or ordering by createdAt.

3. Add a composite index (multiple columns)
addIndex(
    table=&quot;posts&quot;,
    columnNames=&quot;authorId,createdAt&quot;
);

Optimizes queries that filter or sort on both authorId and createdAt.

4. Add an index with a custom name
addIndex(
    table=&quot;comments&quot;,
    columnNames=&quot;postId&quot;,
    indexName=&quot;idx_comments_postId&quot;
);

Creates index with a custom name instead of default comments_postId.

5. Composite unique index
addIndex(
    table=&quot;enrollments&quot;,
    columnNames=&quot;studentId,courseId&quot;,
    unique=true,
    indexName=&quot;unique_enrollments&quot;
);

Prevents the same studentId and courseId pair from being inserted more than once.</code></pre>
