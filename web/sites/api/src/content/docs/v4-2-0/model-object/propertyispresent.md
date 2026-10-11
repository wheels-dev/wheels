---
title: propertyIsPresent()
description: "Returns <code>true</code> if the specified property exists on the model and is not a blank string."
sidebar:
  label: propertyIsPresent()
  order: 0
---

## Signature

`propertyIsPresent()` — returns `boolean`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Returns <code>true</code> if the specified property exists on the model and is not a blank string.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | Name of property to inspect. |

</div>

## Examples

<pre><code class='javascript'>// 1. Check if a non-blank property is present
employee = model(&quot;Employee&quot;).new();
employee.firstName = &quot;Jane&quot;;
writeOutput(employee.propertyIsPresent(&quot;firstName&quot;)); // true

// 2. Returns false when the property is an empty string
employee = model(&quot;Employee&quot;).new();
employee.firstName = &quot;&quot;;
writeOutput(employee.propertyIsPresent(&quot;firstName&quot;)); // false

// 3. Returns false when the property does not exist on the object
employee = model(&quot;Employee&quot;).new();
writeOutput(employee.propertyIsPresent(&quot;nonExistentField&quot;)); // false
</code></pre>
