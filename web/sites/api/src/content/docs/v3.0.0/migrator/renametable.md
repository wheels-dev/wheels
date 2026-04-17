---
title: renameTable()
description: "Used to change the name of an existing database table within a migration CFC. This is helpful when you want to standardize table names, correct naming mistakes,"
sidebar:
  label: renameTable()
  order: 0
---

## Signature

`renameTable()` — returns `void`

**Available in:** `migration`
**Category:** Migration Functions

## Description

Used to change the name of an existing database table within a migration CFC. This is helpful when you want to standardize table names, correct naming mistakes, or improve clarity in your database schema. This operation preserves all the existing data, indexes, and constraints in the table while updating its name. Only available in a migration CFC.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `oldName` | `string` | yes | — | Name the old table |
| `newName` | `string` | yes | — | New name for the table |

## Examples

<pre><code class='javascript'>1. Rename the users table
renameTable(oldName=&quot;users&quot;, newName=&quot;app_users&quot;);

2. Rename the orders table
renameTable(oldName=&quot;orders&quot;, newName=&quot;customer_orders&quot;);

3. Rename multiple tables in separate migration calls
renameTable(oldName=&quot;products_old&quot;, newName=&quot;products&quot;);
renameTable(oldName=&quot;temp_data&quot;, newName=&quot;archived_data&quot;);
</code></pre>
