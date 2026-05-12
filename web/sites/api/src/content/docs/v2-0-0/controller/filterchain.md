---
title: filterChain()
description: "Returns an array of all the filters set on current controller in the order in which they will be executed."
sidebar:
  label: filterChain()
  order: 0
---

## Signature

`filterChain()` — returns `array`

**Available in:** `controller`
**Category:** Configuration Functions

## Description

Returns an array of all the filters set on current controller in the order in which they will be executed.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `type` | `string` | no | `all` | Use this argument to return only before or after filters. |

</div>

## Examples

<pre>// Get filter chain.
myFilterChain = filterChain();

// Get filter chain for after filters only.
myFilterChain = filterChain(type=&quot;after&quot;);
</pre>
