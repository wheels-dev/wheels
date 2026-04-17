---
title: afterValidationOnUpdate()
description: "Registers method(s) that should be called after an existing object is validated."
sidebar:
  label: afterValidationOnUpdate()
  order: 0
---

## Signature

`afterValidationOnUpdate()` — returns `any`




## Description

Registers method(s) that should be called after an existing object is validated.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | yes | — | See documentation for afterNew. |

## Examples

<pre>&lt;!--- Instruct CFWheels to call the `fixObj` method ---&gt;
&lt;cfset afterValidationOnUpdate(&quot;fixObj&quot;)&gt;</pre>
