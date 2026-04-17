---
title: accessibleProperties()
description: "Use this method to specify which properties can be set through mass assignment."
sidebar:
  label: accessibleProperties()
  order: 0
---

## Signature

`accessibleProperties()` — returns `void`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Use this method to specify which properties can be set through mass assignment.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `properties` | `string` | no | — | Property name (or list of property names) that are allowed to be altered through mass assignment. |

## Examples

<pre><code class='javascript'>// Make `isActive` the only property that can be set through mass assignment operations like `updateAll()`.
config() {
	accessibleProperties(&quot;isActive&quot;);
}
</code></pre>
