---
title: beforeValidationOnUpdate()
description: "Registers method(s) that should be called before an existing object is validated."
sidebar:
  label: beforeValidationOnUpdate()
  order: 0
---

## Signature

`beforeValidationOnUpdate()` — returns `any`




## Description

Registers method(s) that should be called before an existing object is validated.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | yes | — | See documentation for afterNew. |

## Examples

<pre>&lt;!--- Instruct CFWheels to call the `fixObj` method ---&gt;
&lt;cfset beforeValidationOnUpdate(&quot;fixObj&quot;)&gt;</pre>
