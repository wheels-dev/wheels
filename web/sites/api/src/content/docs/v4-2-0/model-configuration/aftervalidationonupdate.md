---
title: afterValidationOnUpdate()
description: "Registers method(s) that should be called after an existing object is validated."
sidebar:
  label: afterValidationOnUpdate()
  order: 0
---

## Signature

`afterValidationOnUpdate()` — returns `void`

**Available in:** `model`
**Category:** Callback Functions

## Description

Registers method(s) that should be called after an existing object is validated.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names that should be called when this callback event occurs in an object's life cycle (can also be called with the `method` argument). |

</div>

## Examples

<pre><code class='javascript'>// 1. Call a single method after an existing object is validated on update
// In models/User.cfc:
component extends=&quot;Model&quot; {
    function config() {
        afterValidationOnUpdate(&quot;stampUpdatedBy&quot;);
    }

    private function stampUpdatedBy() {
        this.updatedBy = request.currentUserId;
    }
}

// 2. Register multiple methods to run after an existing object is validated on update
component extends=&quot;Model&quot; {
    function config() {
        afterValidationOnUpdate(&quot;normalizeSlug,logValidation&quot;);
    }

    private function normalizeSlug() {
        this.slug = LCase(Replace(this.title, &quot; &quot;, &quot;-&quot;, &quot;all&quot;));
    }

    private function logValidation() {
        // custom logging logic here
    }
}
</code></pre>
