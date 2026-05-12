---
title: afterSave()
description: "Registers method(s) that should be called after an object is saved."
sidebar:
  label: afterSave()
  order: 0
---

## Signature

`afterSave()` — returns `void`

**Available in:** `model`
**Category:** Callback Functions

## Description

Registers method(s) that should be called after an object is saved.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names that should be called when this callback event occurs in an object's life cycle (can also be called with the `method` argument). |

</div>

## Examples

<pre>// Instruct CFWheels to call the `fixObj` method after an object has been saved.
afterSave(&quot;fixObj&quot;);
</pre>
