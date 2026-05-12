---
title: setFilterChain()
description: "Use this function if you need a more low level way of setting the entire filter chain for a controller."
sidebar:
  label: setFilterChain()
  order: 0
---

## Signature

`setFilterChain()` — returns `void`

**Available in:** `controller`
**Category:** Configuration Functions

## Description

Use this function if you need a more low level way of setting the entire filter chain for a controller.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `chain` | `array` | yes | — | An array of structs, each of which represent an `argumentCollection` that get passed to the `filters` function. This should represent the entire filter chain that you want to use for this controller. |

</div>

## Examples

<pre><code class='javascript'>// Set filter chain directly in an array.
setFilterChain([
	{through=&quot;restrictAccess&quot;},
	{through=&quot;isLoggedIn, checkIPAddress&quot;, except=&quot;home, login&quot;},
	{type=&quot;after&quot;, through=&quot;logConversion&quot;, only=&quot;thankYou&quot;}
]);
</code></pre>
