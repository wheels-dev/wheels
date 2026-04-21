---
title: primaryKey()
description: "Returns the name of the primary key column for the table mapped to a given model. Wheels determines this automatically by introspecting the database. If the tab"
sidebar:
  label: primaryKey()
  order: 0
---

## Signature

`primaryKey()` — returns `string`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Returns the name of the primary key column for the table mapped to a given model. Wheels determines this automatically by introspecting the database. If the table uses a single primary key, the function returns that key’s name as a string. For tables with composite primary keys, the function will return a list of all keys. You can optionally pass in the position argument to retrieve a specific key from a composite set. This function is also available as the alias <code>primaryKeys()</code>.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `position` | `numeric` | no | `0` | If you are accessing a composite primary key, pass the position of a single key to fetch. |

</div>

## Examples

<pre><code class='javascript'>1. Get the primary key of a simple table
// For employees table with id as primary key
keyName = model(&quot;employee&quot;).primaryKey();
// Returns: &quot;id&quot;

2. Alias usage
keyName = model(&quot;employee&quot;).primaryKeys();
// Returns: &quot;id&quot;

3. Composite primary key table (e.g., order_products with order_id + product_id)
keys = model(&quot;orderProduct&quot;).primaryKey();
// Returns: &quot;order_id,product_id&quot;

4. Fetching just the first key in a composite set
firstKey = model(&quot;orderProduct&quot;).primaryKey(position=1);
// Returns: &quot;order_id&quot;

5. Fetching the second key in a composite set
secondKey = model(&quot;orderProduct&quot;).primaryKey(position=2);
// Returns: &quot;product_id&quot;
</code></pre>
