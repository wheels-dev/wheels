---
title: deobfuscateParam()
description: "Deobfuscates a value."
sidebar:
  label: deobfuscateParam()
  order: 0
---

## Signature

`deobfuscateParam()` — returns `string`

**Available in:** `controller`, `model`, `migrator`
**Category:** Miscellaneous Functions

## Description

Deobfuscates a value.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `param` | `string` | yes | — | The value to deobfuscate. |

</div>

## Examples

<pre>// Get the original value from an obfuscated one
originalValue = deobfuscateParam(&quot;b7ab9a50&quot;);</pre>
