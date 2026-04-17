---
title: primaryKeys()
description: "Alias for <code>primaryKey()</code>."
sidebar:
  label: primaryKeys()
  order: 0
---

## Signature

`primaryKeys()` — returns `string`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Alias for <code>primaryKey()</code>.
Use this for better readability when you're accessing multiple primary keys.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `position` | `numeric` | no | `0` | If you are accessing a composite primary key, pass the position of a single key to fetch. |

## Examples

<pre><code class='javascript'>1. Get the primary key of a simple table
// Employees table has &quot;id&quot; as primary key
keyNames = model(&quot;employee&quot;).primaryKeys();
// Returns: &quot;id&quot;

2. Composite primary keys (order_products table with order_id + product_id)
keys = model(&quot;orderProduct&quot;).primaryKeys();
// Returns: &quot;order_id,product_id&quot;

3. Get only the first key in a composite primary key
firstKey = model(&quot;orderProduct&quot;).primaryKeys(position=1);
// Returns: &quot;order_id&quot;

4. Get only the second key in a composite primary key
secondKey = model(&quot;orderProduct&quot;).primaryKeys(position=2);
// Returns: &quot;product_id&quot;

5. Using alias for clarity in multi-key situations
// This makes it more obvious the table has multiple keys
keys = model(&quot;orderProduct&quot;).primaryKeys();
// Easier to read than using model(&quot;orderProduct&quot;).primaryKey()
</code></pre>
