---
title: beforeValidation()
description: "Registers method(s) that should be called before an object is validated."
sidebar:
  label: beforeValidation()
  order: 0
---

## Signature

`beforeValidation()` — returns `any`




## Description

Registers method(s) that should be called before an object is validated.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | yes | — | See documentation for afterNew. |

</div>

## Examples

<pre>&lt;!--- Instruct CFWheels to call the `fixObj` method ---&gt;
&lt;cfset beforeValidation(&quot;fixObj&quot;)&gt;</pre>
