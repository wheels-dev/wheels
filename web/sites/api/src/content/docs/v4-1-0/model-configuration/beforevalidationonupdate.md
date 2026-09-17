---
title: beforeValidationOnUpdate()
description: "Registers method(s) that should be called before an existing object is validated."
sidebar:
  label: beforeValidationOnUpdate()
  order: 0
---

## Signature

`beforeValidationOnUpdate()` — returns `void`

**Available in:** `model`
**Category:** Callback Functions

## Description

Registers method(s) that should be called before an existing object is validated.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names that should be called when this callback event occurs in an object's life cycle (can also be called with the `method` argument). |

</div>

## Examples

<pre><code class='javascript'>// 1. Register a single method to run before an existing object is validated on update
// Called inside the model's config() function
beforeValidationOnUpdate(&quot;sanitizeFields&quot;);

// 2. Register multiple methods as a comma-delimited list
beforeValidationOnUpdate(&quot;sanitizeFields,enforceBusinessRules&quot;);

// 3. Use the `method` argument alias for a single callback
beforeValidationOnUpdate(method=&quot;normalizeEmail&quot;);
</code></pre>
