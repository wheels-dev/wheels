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

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names that should be called when this callback event occurs in an object's life cycle (can also be called with the `method` argument). |

</div>

## Examples

<pre><code class='javascript'>// 1. Call a single method after an object is deleted
// In models/Order.cfc
afterDelete(&quot;notifyWarehouse&quot;);

// 2. Call multiple methods after an object is deleted (comma-separated list)
// In models/User.cfc
afterDelete(&quot;removeFromSearchIndex,clearCachedData&quot;);

// 3. Register several after-delete callbacks individually for clarity
// In models/Article.cfc
afterDelete(&quot;logDeletion&quot;);
afterDelete(&quot;cleanupAttachments&quot;);
</code></pre>
