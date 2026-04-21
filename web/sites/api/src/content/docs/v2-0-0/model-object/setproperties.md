---
title: setProperties()
description: "Allows you to set all the properties of an object at once by passing in a structure with keys matching the property names."
sidebar:
  label: setProperties()
  order: 0
---

## Signature

`setProperties()` — returns `void`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Allows you to set all the properties of an object at once by passing in a structure with keys matching the property names.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `properties` | `struct` | no | `[runtime expression]` | The properties you want to set on the object (can also be passed in as named arguments). |

</div>

## Examples

<pre>// Update the properties of the object with the params struct containing the values of a form post
user = model(&quot;user&quot;).findByKey(1);
user.setProperties(params.user);</pre>
