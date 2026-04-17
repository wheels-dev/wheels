---
title: beforeValidationOnCreate()
description: "Registers method(s) that should be called before a new object is validated."
sidebar:
  label: beforeValidationOnCreate()
  order: 0
---

## Signature

`beforeValidationOnCreate()` — returns `any`




## Description

Registers method(s) that should be called before a new object is validated.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | yes | — | See documentation for afterNew. |

## Examples

<pre>&lt;!--- Instruct CFWheels to call the `fixObj` method ---&gt;
&lt;cfset beforeValidationOnCreate(&quot;fixObj&quot;)&gt;</pre>
