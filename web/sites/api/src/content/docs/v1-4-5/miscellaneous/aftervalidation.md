---
title: afterValidation()
description: "Registers method(s) that should be called after an object is validated."
sidebar:
  label: afterValidation()
  order: 0
---

## Signature

`afterValidation()` — returns `any`




## Description

Registers method(s) that should be called after an object is validated.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | yes | — | See documentation for afterNew. |

## Examples

<pre>&lt;!--- Instruct CFWheels to call the `fixObj` method ---&gt;
&lt;cfset afterValidation(&quot;fixObj&quot;)&gt;</pre>
