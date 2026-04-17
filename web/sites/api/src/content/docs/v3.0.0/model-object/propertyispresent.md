---
title: propertyIsPresent()
description: "Returns <code>true</code> if the specified property exists on the model and is not a blank string. This is the inverse of propertyIsBlank() which checks that a"
sidebar:
  label: propertyIsPresent()
  order: 0
---

## Signature

`propertyIsPresent()` — returns `boolean`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Returns <code>true</code> if the specified property exists on the model and is not a blank string. This is the inverse of propertyIsBlank() which checks that a property is either missing or empty.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | Name of property to inspect. |

## Examples

<pre><code class='javascript'>1. Property exists with a value
employee = model(&quot;employee&quot;).new();
employee.firstName = &quot;Dude&quot;;
writeOutput(employee.propertyIsPresent(&quot;firstName&quot;)); // true

2. Property exists but is blank
employee.firstName = &quot;&quot;;
writeOutput(employee.propertyIsPresent(&quot;firstName&quot;)); // false

3. Property does not exist on the model
writeOutput(employee.propertyIsPresent(&quot;nonexistentProperty&quot;)); // false

4. Conditional logic
if (!employee.propertyIsPresent(&quot;email&quot;)) {
    writeOutput(&quot;Email is required.&quot;);
}
</code></pre>
