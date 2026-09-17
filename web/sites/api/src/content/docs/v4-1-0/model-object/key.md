---
title: key()
description: "Returns the value of the primary key for the object."
sidebar:
  label: key()
  order: 0
---

## Signature

`key()` — returns `string`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Returns the value of the primary key for the object.
If you have a single primary key named id, then <code>someObject.key()</code> is functionally equivalent to <code>someObject.id</code>.
This method is more useful when you do dynamic programming and don't know the name of the primary key or when you use composite keys (in which case it's convenient to use this method to get a list of both key values returned).



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `$persisted` | `boolean` | no | `false` |  |
| `$returnTickCountWhenNew` | `boolean` | no | `false` |  |

</div>

## Examples

<pre><code class='javascript'>// 1. Get the primary key value of a found object
employee = model(&quot;Employee&quot;).findByKey(params.key);
writeOutput(employee.key());
// -&gt; 42

// 2. Use key() when you don't know the primary key column name (dynamic programming)
obj = model(params.modelName).findByKey(params.id);
if (IsObject(obj)) {
	writeOutput(&quot;Found record with key: &quot; &amp; obj.key());
}

// 3. Composite primary key — key() returns a comma-delimited list of both values
orderItem = model(&quot;OrderItem&quot;).findByKey(key=&quot;1,5&quot;);
writeOutput(orderItem.key());
// -&gt; 1,5 (orderId and productId combined)
</code></pre>
