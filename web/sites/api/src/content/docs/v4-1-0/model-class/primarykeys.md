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

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `position` | `numeric` | no | `0` | If you are accessing a composite primary key, pass the position of a single key to fetch. |

</div>

## Examples

<pre><code class='javascript'>// 1. Get the name(s) of the primary key(s) for the User model (returns a comma-separated list for composite keys)
keyNames = model(&quot;User&quot;).primaryKeys();
// keyNames -&gt; &quot;id&quot;

// 2. Get the name of the first primary key in a model that uses a composite primary key (e.g., an OrderItem table keyed on orderId,productId)
firstKey = model(&quot;OrderItem&quot;).primaryKeys(1);
// firstKey -&gt; &quot;orderId&quot;

// 3. Get the second primary key in a composite key model
secondKey = model(&quot;OrderItem&quot;).primaryKeys(2);
// secondKey -&gt; &quot;productId&quot;
</code></pre>
