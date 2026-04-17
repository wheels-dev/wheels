---
title: properties()
description: "Returns a structure of all the properties with their names as keys and the values of the property as values."
sidebar:
  label: properties()
  order: 0
---

## Signature

`properties()` — returns `struct`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Returns a structure of all the properties with their names as keys and the values of the property as values.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `returnIncluded` | `boolean` | no | `true` | Whether to return nested properties or not. |

## Examples

<pre><code class='javascript'>// Get a structure of all the properties for an object
user = model(&quot;user&quot;).findByKey(1);
props = user.properties();</code></pre>
