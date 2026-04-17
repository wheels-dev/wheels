---
title: beforeValidationOnUpdate()
description: "Registers method(s) that should be called before an existing object is validated."
sidebar:
  label: beforeValidationOnUpdate()
  order: 0
---

## Signature

`beforeValidationOnUpdate()` — returns `void`

**Available in:** `model`
**Category:** Callback Functions

## Description

Registers method(s) that should be called before an existing object is validated.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names that should be called when this callback event occurs in an object's life cycle (can also be called with the `method` argument). |

## Examples

<pre>// Instruct CFWheels to call the `fixObj` method
beforeValidationOnUpdate(&quot;fixObj&quot;);</pre>
