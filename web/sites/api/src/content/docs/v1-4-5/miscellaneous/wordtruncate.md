---
title: wordTruncate()
description: "Truncates text to the specified length of words and replaces the remaining characters with the specified truncate string (which defaults to \"...\")."
sidebar:
  label: wordTruncate()
  order: 0
---

## Signature

`wordTruncate()` — returns `any`




## Description

Truncates text to the specified length of words and replaces the remaining characters with the specified truncate string (which defaults to "...").

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `text` | `string` | yes | — | The text to truncate. |
| `length` | `numeric` | yes | `5` | Number of words to truncate the text to. |
| `truncateString` | `string` | yes | `...` | String to replace the last characters with. |

</div>

## Examples

<pre>#wordTruncate(text=&quot;Wheels is a framework for ColdFusion&quot;, length=4)#
-&gt; CFWheels is a framework...

#truncate(text=&quot;Wheels is a framework for ColdFusion&quot;, truncateString=&quot; (more)&quot;)#
-&gt; CFWheels is a framework for (more)</pre>
