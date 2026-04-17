---
title: filterChain()
description: "Returns an array of all the filters set on this controller in the order in which they will be executed."
sidebar:
  label: filterChain()
  order: 0
---

## Signature

`filterChain()` — returns `any`




## Description

Returns an array of all the filters set on this controller in the order in which they will be executed.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `type` | `string` | yes | `all` | Use this argument to return only before or after filters. |

## Examples

<pre>// Get filter chain
myFilterChain = filterChain();

// Get filter chain for after filters only
myFilterChain = filterChain(type=&quot;after&quot;);</pre>
