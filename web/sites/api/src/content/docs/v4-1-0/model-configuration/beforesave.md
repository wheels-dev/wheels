---
title: beforeSave()
description: "Registers method(s) that should be called before an object is saved."
sidebar:
  label: beforeSave()
  order: 0
---

## Signature

`beforeSave()` — returns `void`

**Available in:** `model`
**Category:** Callback Functions

## Description

Registers method(s) that should be called before an object is saved.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names that should be called when this callback event occurs in an object's life cycle (can also be called with the `method` argument). |

</div>

## Examples

<pre><code class='javascript'>// 1. Call a single method before every save (create or update)
// In models/User.cfc
component extends=&quot;Model&quot; {
    function config() {
        beforeSave(&quot;normalizeEmail&quot;);
    }

    private function normalizeEmail() {
        this.email = LCase(Trim(this.email));
    }
}

// 2. Register multiple callback methods as a comma-delimited list
component extends=&quot;Model&quot; {
    function config() {
        beforeSave(&quot;stripWhitespace,generateSlug&quot;);
    }
}

// 3. Use the `method` argument alias to register a single callback
component extends=&quot;Model&quot; {
    function config() {
        beforeSave(method=&quot;sanitizeContent&quot;);
    }
}
</code></pre>
