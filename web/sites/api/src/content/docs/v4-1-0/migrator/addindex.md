---
title: addIndex()
description: "Add database index on a table column"
sidebar:
  label: addIndex()
  order: 0
---

## Signature

`addIndex()` — returns `void`

**Available in:** `migration`
**Category:** Migration Functions

## Description

Add database index on a table column
Only available in a migration CFC



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `table` | `string` | yes | — | The table name to perform the index operation on |
| `columnNames` | `string` | no | — | One or more column names to index, comma separated |
| `unique` | `boolean` | no | `false` | If true will create a unique index constraint |
| `indexName` | `string` | no | — | The name of the index to add: Defaults to table name + underscore + first column name |

</div>

## Examples

<pre><code class='javascript'>// 1. Add a basic index on a single column
addIndex(table=&quot;users&quot;, columnNames=&quot;email&quot;);

// 2. Add a unique index to enforce uniqueness on a column
addIndex(table=&quot;members&quot;, columnNames=&quot;username&quot;, unique=true);

// 3. Add a composite index on multiple columns
addIndex(table=&quot;orders&quot;, columnNames=&quot;customerId,createdAt&quot;);

// 4. Add an index with a custom index name
// (defaults to tableName_firstColumnName, e.g. &quot;posts_publishedAt&quot;)
addIndex(table=&quot;posts&quot;, columnNames=&quot;publishedAt&quot;, indexName=&quot;idx_posts_published&quot;);
</code></pre>
