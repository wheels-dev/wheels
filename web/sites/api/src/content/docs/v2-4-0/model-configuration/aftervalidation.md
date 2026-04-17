---
title: afterValidation()
description: "Registers method(s) that should be called after an object is validated."
sidebar:
  label: afterValidation()
  order: 0
---

## Signature

`afterValidation()` — returns `void`

**Available in:** `model`
**Category:** Callback Functions

## Description

Registers method(s) that should be called after an object is validated.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names that should be called when this callback event occurs in an object's life cycle (can also be called with the `method` argument). |

## Examples

<pre><code class='javascript'>// Instruct CFWheels to call the `fixObj` method after an object has been validated.
afterValidation(&quot;fixObj&quot;);
</code></pre>
