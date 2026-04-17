---
title: beforeUpdate()
description: "Registers method(s) that should be called before an existing object is updated."
sidebar:
  label: beforeUpdate()
  order: 0
---

## Signature

`beforeUpdate()` — returns `void`

**Available in:** `model`
**Category:** Callback Functions

## Description

Registers method(s) that should be called before an existing object is updated.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names that should be called when this callback event occurs in an object's life cycle (can also be called with the `method` argument). |

## Examples

<pre><code class='javascript'>// Instruct CFWheels to call the `fixObj` method
beforeUpdate(&quot;fixObj&quot;);</code></pre>
