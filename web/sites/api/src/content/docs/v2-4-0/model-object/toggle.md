---
title: toggle()
description: "Assigns to the property specified the opposite of the property's current boolean value."
sidebar:
  label: toggle()
  order: 0
---

## Signature

`toggle()` — returns `boolean`

**Available in:** `model`
**Category:** CRUD Functions

## Description

Assigns to the property specified the opposite of the property's current boolean value.
Throws an error if the property cannot be converted to a boolean value.
Returns this object if save called internally is <code>false</code>.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — |  |
| `save` | `boolean` | no | `true` | Argument to decide whether save the property after it has been toggled. |

</div>

## Examples

<pre><code class='javascript'>// Get an object, and toggle a boolean property
user = model(&quot;user&quot;).findByKey(58);
isSuccess = user.toggle(&quot;isActive&quot;); // returns whether the object was saved properly

// You can also use a dynamic helper for this
isSuccess = user.toggleIsActive();</code></pre>
