---
title: filterChain()
description: "The filterChain() function returns an array of all filters that are set on the current controller in the order they will be executed. By default, it includes bo"
sidebar:
  label: filterChain()
  order: 0
---

## Signature

`filterChain()` — returns `array`

**Available in:** `controller`
**Category:** Configuration Functions

## Description

The filterChain() function returns an array of all filters that are set on the current controller in the order they will be executed. By default, it includes both before and after filters, but you can specify the type argument if you want to return only one type. For example, setting type="after" will return only the filters that run after the controller action.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `type` | `string` | no | `all` | Use this argument to return only before or after filters. |

</div>

## Examples

<pre><code class='javascript'>1. Get filter chain.
myFilterChain = filterChain();

2. Get filter chain for after filters only.
myFilterChain = filterChain(type=&quot;after&quot;);
</code></pre>
