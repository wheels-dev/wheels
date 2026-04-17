---
title: afterInitialization()
description: "Registers method(s) that should be called after an object has been initialized."
sidebar:
  label: afterInitialization()
  order: 0
---

## Signature

`afterInitialization()` — returns `void`

**Available in:** `model`
**Category:** Callback Functions

## Description

Registers method(s) that should be called after an object has been initialized.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names that should be called when this callback event occurs in an object's life cycle (can also be called with the `method` argument). |

## Examples

<pre><code class='javascript'>// Instruct CFWheels to call the `fixObj` method after an object has been initialized (i.e. after creating it or fetching it with a finder method).
afterInitialization(&quot;fixObj&quot;);
</code></pre>
