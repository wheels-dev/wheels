---
title: beforeUpdate()
description: "Registers method(s) that should be called before an existing object is updated."
sidebar:
  label: beforeUpdate()
  order: 0
---

## Signature

`beforeUpdate()` — returns `void`

**Available in:** `model`
**Category:** Callback Functions

## Description

Registers method(s) that should be called before an existing object is updated.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names that should be called when this callback event occurs in an object's life cycle (can also be called with the `method` argument). |

</div>

## Examples

<pre><code class='javascript'>// 1. Call a single method before every update
// In models/User.cfc
component extends=&quot;Model&quot; {
    function config() {
        beforeUpdate(&quot;stampUpdatedBy&quot;);
    }

    private function stampUpdatedBy() {
        this.updatedBy = session.userId;
    }
}

// 2. Register multiple callback methods as a comma-delimited list
component extends=&quot;Model&quot; {
    function config() {
        beforeUpdate(&quot;validateOwnership,recalculateTotals&quot;);
    }
}

// 3. Use the `method` argument alias to register a single callback
component extends=&quot;Model&quot; {
    function config() {
        beforeUpdate(method=&quot;fixObj&quot;);
    }
}
</code></pre>
