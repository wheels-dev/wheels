---
title: primaryKey()
description: "Returns the name of the primary key for this model's table."
sidebar:
  label: primaryKey()
  order: 0
---

## Signature

`primaryKey()` — returns `string`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Returns the name of the primary key for this model's table.
This is determined through database introspection.
If composite primary keys have been used, they will both be returned in a list.
This function is also aliased as <code>primaryKeys()</code>.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `position` | `numeric` | no | `0` | If you are accessing a composite primary key, pass the position of a single key to fetch. |

</div>

## Examples

<pre><code class='javascript'>// 1. Get the name of the primary key for the `employee` model (maps to the `employees` table by default)
keyName = model(&quot;employee&quot;).primaryKey();
// keyName -&gt; &quot;id&quot;

// 2. Get all primary key column names for a model with a composite primary key
keys = model(&quot;orderItem&quot;).primaryKey();
// keys -&gt; &quot;orderId,productId&quot;

// 3. Get only the first key of a composite primary key using the `position` argument
firstKey = model(&quot;orderItem&quot;).primaryKey(1);
// firstKey -&gt; &quot;orderId&quot;

// 4. Use the `primaryKeys()` alias (preferred for readability with composite keys)
keys = model(&quot;orderItem&quot;).primaryKeys();
// keys -&gt; &quot;orderId,productId&quot;
</code></pre>
