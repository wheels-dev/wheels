---
title: beforeCreate()
description: "Registers method(s) that should be called before a new object is created."
sidebar:
  label: beforeCreate()
  order: 0
---

## Signature

`beforeCreate()` — returns `void`

**Available in:** `model`
**Category:** Callback Functions

## Description

Registers method(s) that should be called before a new object is created.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names that should be called when this callback event occurs in an object's life cycle (can also be called with the `method` argument). |

</div>

## Examples

<pre><code class='javascript'>// 1. Register a single callback method to run before a new object is created
// Defined inside the model's config() function
beforeCreate(&quot;setDefaults&quot;);

// 2. Register multiple callback methods to run in sequence before creation
beforeCreate(&quot;generateSlug,stampCreatedBy&quot;);

// 3. Register callbacks using the named argument
beforeCreate(methods=&quot;generateToken,normalizeEmail&quot;);
</code></pre>
