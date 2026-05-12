---
title: obfuscateParam()
description: "Obfuscates a value. Typically used for hiding primary key values when passed along in the URL."
sidebar:
  label: obfuscateParam()
  order: 0
---

## Signature

`obfuscateParam()` — returns `string`

**Available in:** `controller`, `model`, `migrator`
**Category:** Miscellaneous Functions

## Description

Obfuscates a value. Typically used for hiding primary key values when passed along in the URL.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `param` | `any` | yes | — | The value to obfuscate. |

</div>

## Examples

<pre>// Obfuscate the primary key value `99`
newValue = obfuscateParam(99);</pre>
