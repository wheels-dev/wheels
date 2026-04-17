---
title: removeIndex()
description: "Used to delete an index from a database table within a migration CFC. Indexes are typically added to improve query performance, but there are scenarios where an"
sidebar:
  label: removeIndex()
  order: 0
---

## Signature

`removeIndex()` — returns `void`

**Available in:** `migration`
**Category:** Migration Functions

## Description

Used to delete an index from a database table within a migration CFC. Indexes are typically added to improve query performance, but there are scenarios where an index becomes unnecessary or needs to be replaced. Using removeIndex() allows you to safely remove an index while maintaining database integrity. Only available in a migration CFC.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `table` | `string` | yes | — | The table name to perform the index operation on |
| `indexName` | `string` | yes | — | the name of the index to remove |

## Examples

<pre><code class='javascript'>1. Remove an index from the members table
removeIndex(table=&quot;members&quot;, indexName=&quot;members_username&quot;);

2. Remove an index from the orders table
removeIndex(table=&quot;orders&quot;, indexName=&quot;orders_createdAt_idx&quot;);

3. Remove multiple indexes in separate calls
removeIndex(table=&quot;products&quot;, indexName=&quot;products_name_idx&quot;);
removeIndex(table=&quot;products&quot;, indexName=&quot;products_category_idx&quot;);
</code></pre>
