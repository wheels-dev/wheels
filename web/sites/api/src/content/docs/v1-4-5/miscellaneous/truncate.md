---
title: truncate()
description: "Truncates text to the specified length and replaces the last characters with the specified truncate string (which defaults to \"...\")."
sidebar:
  label: truncate()
  order: 0
---

## Signature

`truncate()` — returns `any`




## Description

Truncates text to the specified length and replaces the last characters with the specified truncate string (which defaults to "...").

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `text` | `string` | yes | — | The text to truncate. |
| `length` | `numeric` | yes | `30` | Length to truncate the text to. |
| `truncateString` | `string` | yes | `...` | String to replace the last characters with. |

</div>

## Examples

<pre>#truncate(text=&quot;Wheels is a framework for ColdFusion&quot;, length=20)#
-&gt; CFWheels is a frame...

#truncate(text=&quot;Wheels is a framework for ColdFusion&quot;, truncateString=&quot; (more)&quot;)#
-&gt; CFWheels is a framework f (more)</pre>
