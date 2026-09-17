---
title: beforeValidation()
description: "Registers method(s) that should be called before an object is validated."
sidebar:
  label: beforeValidation()
  order: 0
---

## Signature

`beforeValidation()` — returns `void`

**Available in:** `model`
**Category:** Callback Functions

## Description

Registers method(s) that should be called before an object is validated.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names that should be called when this callback event occurs in an object's life cycle (can also be called with the `method` argument). |

</div>

## Examples

<pre><code class='javascript'>// 1. Register a single method to run before any validation
// In models/User.cfc
component extends=&quot;Model&quot; {
    function config() {
        beforeValidation(&quot;normalizeEmail&quot;);
        validatesPresenceOf(&quot;email&quot;);
    }

    private function normalizeEmail() {
        this.email = LCase(Trim(this.email));
    }
}

// 2. Register multiple methods to run before validation using a comma-delimited list
// In models/Article.cfc
component extends=&quot;Model&quot; {
    function config() {
        beforeValidation(&quot;stripTags,setSlug&quot;);
        validatesPresenceOf(properties=&quot;title,slug&quot;);
    }

    private function stripTags() {
        this.title = ReReplace(this.title, &quot;&lt;[^&gt;]*&gt;&quot;, &quot;&quot;, &quot;all&quot;);
    }

    private function setSlug() {
        if (!Len(this.slug)) {
            this.slug = LCase(ReReplace(Trim(this.title), &quot;\s+&quot;, &quot;-&quot;, &quot;all&quot;));
        }
    }
}

// 3. Register callbacks across multiple calls (they are stacked in order)
// In models/Product.cfc
component extends=&quot;Model&quot; {
    function config() {
        beforeValidation(&quot;trimFields&quot;);
        beforeValidation(&quot;setDefaults&quot;);
    }

    private function trimFields() {
        this.name = Trim(this.name);
    }

    private function setDefaults() {
        if (!Len(this.status)) {
            this.status = &quot;draft&quot;;
        }
    }
}
</code></pre>
