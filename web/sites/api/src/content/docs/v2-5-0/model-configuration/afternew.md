---
title: afterNew()
description: "Registers method(s) that should be called after a new object has been initialized (which is usually done with the <code>new</code> method)."
sidebar:
  label: afterNew()
  order: 0
---

## Signature

`afterNew()` — returns `void`

**Available in:** `model`
**Category:** Callback Functions

## Description

Registers method(s) that should be called after a new object has been initialized (which is usually done with the <code>new</code> method).



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names that should be called when this callback event occurs in an object's life cycle (can also be called with the `method` argument). |

## Examples

<pre><code class='javascript'>// Instruct CFWheels to call the `fixObj` method after a new object has been created.
afterNew(&quot;fixObj&quot;);
</code></pre>
