---
title: afterDelete()
description: "Registers method(s) that should be called after an object is deleted."
sidebar:
  label: afterDelete()
  order: 0
---

## Signature

`afterDelete()` — returns `void`

**Available in:** `model`
**Category:** Callback Functions

## Description

Registers method(s) that should be called after an object is deleted.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names that should be called when this callback event occurs in an object's life cycle (can also be called with the `method` argument). |

## Examples

<pre>// Instruct CFWheels to call the `fixObj` method after an object has been deleted.
afterDelete(&quot;fixObj&quot;);
</pre>
