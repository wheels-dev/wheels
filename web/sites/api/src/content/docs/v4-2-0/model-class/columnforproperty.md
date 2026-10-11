---
title: columnForProperty()
description: "Returns the column name mapped for the named model property."
sidebar:
  label: columnForProperty()
  order: 0
---

## Signature

`columnForProperty()` — returns `any`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Returns the column name mapped for the named model property.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | Name of property to inspect. |

</div>

## Examples

<pre><code class='javascript'>// 1. Get the column name mapped to a model property
col = model(&quot;User&quot;).columnForProperty(&quot;firstName&quot;);
// col -&gt; &quot;first_name&quot;

// 2. Check the column for a property before building a raw SQL fragment
col = model(&quot;Order&quot;).columnForProperty(&quot;placedAt&quot;);
if (col != false) {
    writeOutput(&quot;Column in the database: &quot; &amp; col);
}

// 3. Returns false when the property does not exist on the model
col = model(&quot;User&quot;).columnForProperty(&quot;nonExistentProperty&quot;);
// col -&gt; false
</code></pre>
