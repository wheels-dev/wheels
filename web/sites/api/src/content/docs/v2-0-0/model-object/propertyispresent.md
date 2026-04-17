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

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | Name of property to inspect. |

## Examples

<pre>// Get an object, set a value and then see if the property exists
employee = model(&quot;employee&quot;).new();
employee.firstName = &quot;dude&quot;;
return employee.propertyIsPresent(&quot;firstName&quot;); // Returns true

employee.firstName = &quot;&quot;&gt;
return employee.propertyIsPresent(&quot;firstName&quot;); // Returns false</pre>
