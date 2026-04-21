---
title: deobfuscateParam()
description: "Deobfuscates a value."
sidebar:
  label: deobfuscateParam()
  order: 0
---

## Signature

`deobfuscateParam()` — returns `any`




## Description

Deobfuscates a value.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `param` | `string` | yes | — | Value to deobfuscate. |

</div>

## Examples

<pre>deobfuscateParam(param) &lt;!--- Get the original value from an obfuscated one ---&gt;
&lt;cfset originalValue = deobfuscateParam(&quot;b7ab9a50&quot;)&gt;</pre>
