---
title: afterCreate()
description: "Registers method(s) that should be called after a new object is created."
sidebar:
  label: afterCreate()
  order: 0
---

## Signature

`afterCreate()` — returns `void`

**Available in:** `model`
**Category:** Callback Functions

## Description

Registers method(s) that should be called after a new object is created.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names that should be called when this callback event occurs in an object's life cycle (can also be called with the `method` argument). |

</div>

## Examples

<pre><code class='javascript'>// 1. Register a single method to run after an object is created
// In models/User.cfc
component extends=&quot;Model&quot; {
    function config() {
        afterCreate(&quot;sendWelcomeEmail&quot;);
    }
    private function sendWelcomeEmail() {
        // send email to this.email
    }
}

// 2. Register multiple methods by passing a comma-delimited list
afterCreate(&quot;updateCache,notifyAdmin&quot;);

// 3. Register using the named `methods` argument
afterCreate(methods=&quot;syncToExternalApi&quot;);
</code></pre>
