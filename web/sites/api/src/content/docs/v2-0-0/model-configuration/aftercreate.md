---
title: afterCreate()
description: "Registers method(s) that should be called after a new object is created."
sidebar:
  label: afterCreate()
  order: 0
---

## Signature

`afterCreate()` — returns `void`

**Available in:** `model`
**Category:** Callback Functions

## Description

Registers method(s) that should be called after a new object is created.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names that should be called when this callback event occurs in an object's life cycle (can also be called with the `method` argument). |

## Examples

<pre>// Instruct CFWheels to call the `fixObj` method after an object has been created.
afterCreate(&quot;fixObj&quot;);
</pre>
