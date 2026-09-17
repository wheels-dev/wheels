---
title: afterUpdate()
description: "Registers method(s) that should be called after an existing object is updated."
sidebar:
  label: afterUpdate()
  order: 0
---

## Signature

`afterUpdate()` — returns `void`

**Available in:** `model`
**Category:** Callback Functions

## Description

Registers method(s) that should be called after an existing object is updated.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names that should be called when this callback event occurs in an object's life cycle (can also be called with the `method` argument). |

</div>

## Examples

<pre><code class='javascript'>// 1. Register a single method to run after an object is updated
// In models/User.cfc
component extends=&quot;Model&quot; {
    function config() {
        afterUpdate(&quot;clearCache&quot;);
    }
    private function clearCache() {
        // invalidate cached data for this user
    }
}

// 2. Register multiple methods by passing a comma-delimited list
afterUpdate(&quot;clearCache,notifyAuditLog&quot;);

// 3. Register using the named `methods` argument
afterUpdate(methods=&quot;syncToSearchIndex&quot;);
</code></pre>
