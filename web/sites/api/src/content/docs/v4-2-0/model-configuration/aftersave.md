---
title: afterSave()
description: "Registers method(s) that should be called after an object is saved."
sidebar:
  label: afterSave()
  order: 0
---

## Signature

`afterSave()` — returns `void`

**Available in:** `model`
**Category:** Callback Functions

## Description

Registers method(s) that should be called after an object is saved.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names that should be called when this callback event occurs in an object's life cycle (can also be called with the `method` argument). |

</div>

## Examples

<pre><code class='javascript'>// 1. Register a single callback method to run after an object is saved (both create and update)
// In models/User.cfc
component extends=&quot;Model&quot; {
    function config() {
        afterSave(&quot;sendWelcomeEmail&quot;);
    }

    private function sendWelcomeEmail() {
        // called automatically each time a User is saved
    }
}

// 2. Register multiple callback methods using a comma-delimited list
component extends=&quot;Model&quot; {
    function config() {
        afterSave(&quot;updateSearchIndex,notifyAdmins&quot;);
    }
}

// 3. Register multiple callbacks by calling afterSave() more than once
component extends=&quot;Model&quot; {
    function config() {
        afterSave(&quot;updateSearchIndex&quot;);
        afterSave(&quot;notifyAdmins&quot;);
    }
}
</code></pre>
