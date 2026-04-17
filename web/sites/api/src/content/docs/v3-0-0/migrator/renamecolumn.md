---
title: renameColumn()
description: "Used to change the name of an existing column in a database table within a migration CFC. This is useful when you need to standardize column names, correct nami"
sidebar:
  label: renameColumn()
  order: 0
---

## Signature

`renameColumn()` — returns `void`

**Available in:** `migration`
**Category:** Migration Functions

## Description

Used to change the name of an existing column in a database table within a migration CFC. This is useful when you need to standardize column names, correct naming mistakes, or improve clarity in your database schema. Renaming a column preserves the existing data and column type while updating the schema. Only available in a migration CFC.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `table` | `string` | yes | — | The table containing the column to rename |
| `columnName` | `string` | yes | — | The column name to rename |
| `newColumnName` | `string` | yes | — | The new column name |

## Examples

<pre><code class='javascript'>1. Rename a column in the users table
renameColumn(table=&quot;users&quot;, columnName=&quot;username&quot;, newColumnName=&quot;user_name&quot;);

2. Rename a column in the orders table
renameColumn(table=&quot;orders&quot;, columnName=&quot;createdAt&quot;, newColumnName=&quot;order_created_at&quot;);

3. Rename multiple columns in separate migration calls
renameColumn(table=&quot;products&quot;, columnName=&quot;oldPrice&quot;, newColumnName=&quot;price_old&quot;);
renameColumn(table=&quot;products&quot;, columnName=&quot;discountRate&quot;, newColumnName=&quot;discount_percent&quot;);
</code></pre>
