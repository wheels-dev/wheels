---
title: hasProperty()
description: "Returns <code>true</code> if the specified property name exists on the model."
sidebar:
  label: hasProperty()
  order: 0
---

## Signature

`hasProperty()` — returns `boolean`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Returns <code>true</code> if the specified property name exists on the model.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | Name of property to inspect. |

</div>

## Examples

<pre><code class='javascript'>// Get an object, set a value and then see if the property exists
employee = model(&quot;employee&quot;).new();
employee.firstName = &quot;dude&quot;;
employee.hasProperty(&quot;firstName&quot;); // returns true

// This is also a dynamic method that you could do
employee.hasFirstName();

</code></pre>
