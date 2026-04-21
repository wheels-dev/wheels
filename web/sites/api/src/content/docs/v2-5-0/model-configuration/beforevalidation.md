---
title: beforeValidation()
description: "Registers method(s) that should be called before an object is validated."
sidebar:
  label: beforeValidation()
  order: 0
---

## Signature

`beforeValidation()` — returns `void`

**Available in:** `model`
**Category:** Callback Functions

## Description

Registers method(s) that should be called before an object is validated.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names that should be called when this callback event occurs in an object's life cycle (can also be called with the `method` argument). |

</div>

## Examples

<pre><code class='javascript'>// Instruct CFWheels to call the `fixObj` method
beforeValidation(&quot;fixObj&quot;);</code></pre>
