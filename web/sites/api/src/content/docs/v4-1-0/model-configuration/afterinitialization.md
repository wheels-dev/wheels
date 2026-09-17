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

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names that should be called when this callback event occurs in an object's life cycle (can also be called with the `method` argument). |

</div>

## Examples

<pre><code class='javascript'>// 1. Call a single method after any object is initialized (whether new or fetched from the database)
afterInitialization(&quot;fixObj&quot;);

// 2. Call multiple methods after initialization by passing a comma-delimited list
afterInitialization(&quot;setDefaults,fixObj&quot;);
</code></pre>
