---
title: propertyIsBlank()
description: "Returns <code>true</code> if the specified property doesn't exist on the model or is an empty string."
sidebar:
  label: propertyIsBlank()
  order: 0
---

## Signature

`propertyIsBlank()` — returns `boolean`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Returns <code>true</code> if the specified property doesn't exist on the model or is an empty string.
This method is the inverse of <code>propertyIsPresent()</code>.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | Name of property to inspect. |

</div>

## Examples

<pre><code class='javascript'>1. Basic usage
user = model(&quot;user&quot;).new();
isBlank = user.propertyIsBlank(&quot;firstName&quot;); // returns true if firstName is not set

2. Property exists but is empty
user = model(&quot;user&quot;).new(firstName=&quot;&quot;);
isBlank = user.propertyIsBlank(&quot;firstName&quot;); // true

3. Property exists with value
user = model(&quot;user&quot;).new(firstName=&quot;Joe&quot;);
isBlank = user.propertyIsBlank(&quot;firstName&quot;); // false

4. Checking property that doesn’t exist on the model
isBlank = user.propertyIsBlank(&quot;nonexistentProperty&quot;); // true

5. Using in validation logic
if (user.propertyIsBlank(&quot;email&quot;)) {
    writeOutput(&quot;Email is required.&quot;);
}
</code></pre>
