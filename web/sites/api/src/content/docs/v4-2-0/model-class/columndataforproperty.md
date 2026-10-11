---
title: columnDataForProperty()
description: "Returns a struct with data for the named property."
sidebar:
  label: columnDataForProperty()
  order: 0
---

## Signature

`columnDataForProperty()` — returns `any`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Returns a struct with data for the named property.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | Name of property to inspect. |

</div>

## Examples

<pre><code class='javascript'>// 1. Get all column metadata for a property
data = model(&quot;User&quot;).columnDataForProperty(&quot;email&quot;);
// Returns a struct like:
// { column: &quot;email&quot;, validationtype: &quot;string&quot;, label: &quot;Email&quot; }

// 2. Inspect metadata before using it
data = model(&quot;Product&quot;).columnDataForProperty(&quot;price&quot;);
if (isStruct(data)) {
    writeOutput(&quot;Column: &quot; &amp; data.column);
    writeOutput(&quot;Validation type: &quot; &amp; data.validationtype);
}

// 3. Handle the false return when the property does not exist on the model
data = model(&quot;User&quot;).columnDataForProperty(&quot;nonExistentProp&quot;);
if (!isStruct(data)) {
    writeOutput(&quot;Property not found on this model.&quot;);
}
</code></pre>
