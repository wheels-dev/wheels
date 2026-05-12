---
title: beforeValidationOnCreate()
description: "Registers method(s) that should be called before a new object is validated."
sidebar:
  label: beforeValidationOnCreate()
  order: 0
---

## Signature

`beforeValidationOnCreate()` — returns `void`

**Available in:** `model`
**Category:** Callback Functions

## Description

Registers method(s) that should be called before a new object is validated.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names that should be called when this callback event occurs in an object's life cycle (can also be called with the `method` argument). |

</div>

## Examples

<pre>// Instruct CFWheels to call the `fixObj` method
beforeValidationOnCreate(&quot;fixObj&quot;);</pre>
