---
title: protectedProperties()
description: "Use this method to specify which properties cannot be set through mass assignment."
sidebar:
  label: protectedProperties()
  order: 0
---

## Signature

`protectedProperties()` — returns `void`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Use this method to specify which properties cannot be set through mass assignment.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `properties` | `string` | no | — | Property name (or list of property names) that are not allowed to be altered through mass assignment. |

</div>

## Examples

<pre><code class='javascript'>// In `models/User.cfc`, `firstName` and `lastName` cannot be changed through mass assignment operations like `updateAll()`.
function config(){
	protectedProperties(&quot;firstName,lastName&quot;);
}
</code></pre>
