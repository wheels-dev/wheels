---
title: obfuscateParam()
description: "Obfuscates a value. Typically used for hiding primary key values when passed along in the URL."
sidebar:
  label: obfuscateParam()
  order: 0
---

## Signature

`obfuscateParam()` — returns `any`




## Description

Obfuscates a value. Typically used for hiding primary key values when passed along in the URL.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `param` | `any` | yes | — | Value to obfuscate. |

</div>

## Examples

<pre>obfuscateParam(param) &lt;!--- Obfuscate the primary key value `99` ---&gt;
&lt;cfset newValue = obfuscateParam(99)&gt;</pre>
