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

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names that should be called when this callback event occurs in an object's life cycle (can also be called with the `method` argument). |

</div>

## Examples

<pre><code class='javascript'>// 1. Call a single method after a new object is initialized
// In models/User.cfc
component extends=&quot;Model&quot; {
    function config() {
        afterNew(&quot;setDefaults&quot;);
    }
    private function setDefaults() {
        this.role = &quot;member&quot;;
        this.active = true;
    }
}

// 2. Call multiple methods after a new object is initialized (comma-delimited list)
afterNew(&quot;setDefaults,generateToken&quot;);

// 3. Use the `method` argument alias instead of `methods`
afterNew(method=&quot;setDefaults&quot;);
</code></pre>
