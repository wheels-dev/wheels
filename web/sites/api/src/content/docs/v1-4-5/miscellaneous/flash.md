---
title: flash()
description: "Returns the value of a specific key in the Flash (or the entire Flash as a struct if no key is passed in)."
sidebar:
  label: flash()
  order: 0
---

## Signature

`flash()` — returns `any`




## Description

Returns the value of a specific key in the Flash (or the entire Flash as a struct if no key is passed in).

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `key` | `string` | yes | — | The key to get the value for. |

</div>

## Examples

<pre>// Get the current value of notice in the Flash
notice = flash(&quot;notice&quot;);

// Get the entire Flash as a struct
flashContents = flash();</pre>
