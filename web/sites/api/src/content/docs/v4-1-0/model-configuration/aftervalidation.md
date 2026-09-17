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

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names that should be called when this callback event occurs in an object's life cycle (can also be called with the `method` argument). |

</div>

## Examples

<pre><code class='javascript'>// 1. Call a single method after an object is validated
afterValidation(&quot;fixObj&quot;);

// 2. Call multiple methods after an object is validated (comma-delimited list)
afterValidation(&quot;sanitizeFields,logValidationResult&quot;);

// 3. Use the singular `method` alias for clarity
afterValidation(method=&quot;trimWhitespace&quot;);
</code></pre>
