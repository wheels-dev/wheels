---
title: wordTruncate()
description: "Truncates text to the specified length of words and replaces the remaining characters with the specified truncate string (which defaults to \"...\")."
sidebar:
  label: wordTruncate()
  order: 0
---

## Signature

`wordTruncate()` — returns `string`

**Available in:** `controller`, `model`, `migrator`
**Category:** String Functions

## Description

Truncates text to the specified length of words and replaces the remaining characters with the specified truncate string (which defaults to "...").



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `text` | `string` | yes | — | The text to truncate. |
| `length` | `numeric` | no | `5` | Number of words to truncate the text to. |
| `truncateString` | `string` | no | `...` | String to replace the last characters with. |

</div>

## Examples

<pre>&lt;!--- Outputs &quot;CFWheels is a framework...&quot; ---&gt;
#wordTruncate(text=&quot;CFWheels is a framework for ColdFusion&quot;, length=4)#</pre>
