---
title: afterValidationOnCreate()
description: "Registers method(s) that should be called after a new object is validated."
sidebar:
  label: afterValidationOnCreate()
  order: 0
---

## Signature

`afterValidationOnCreate()` — returns `any`




## Description

Registers method(s) that should be called after a new object is validated.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | yes | — | See documentation for afterNew. |

## Examples

<pre>&lt;!--- Instruct CFWheels to call the `fixObj` method ---&gt;
&lt;cfset afterValidationOnCreate(&quot;fixObj&quot;)&gt;</pre>
