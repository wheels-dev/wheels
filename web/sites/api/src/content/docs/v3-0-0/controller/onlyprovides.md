---
title: onlyProvides()
description: "Use this in an individual controller action to define which formats the action will respond with."
sidebar:
  label: onlyProvides()
  order: 0
---

## Signature

`onlyProvides()` — returns `void`

**Available in:** `controller`
**Category:** Provides Functions

## Description

Use this in an individual controller action to define which formats the action will respond with.
This can be used to define provides behavior in individual actions or to override a global setting set with <code>provides</code> in the controller's <code>config()</code>.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `formats` | `string` | no | — | Formats to instruct the controller to provide. Valid values are `html` (the default), `xml`, `json`, `csv`, `pdf`, and `xls`. |
| `action` | `string` | no | `[runtime expression]` | Name of action, defaults to current. |

</div>

## Examples

<pre><code class='javascript'>1. Restrict an action to HTML only
function show() {
    // This action will only respond with HTML
    onlyProvides(&quot;html&quot;);
}

2. Restrict an action to JSON and XML
function data() {
    // Only allow JSON or XML responses
    onlyProvides(&quot;json,xml&quot;);
}

3. Override global provides setting
component extends=&quot;Controller&quot; {

    function config() {
        // Globally allow HTML and JSON
        provides(&quot;html,json&quot;);
    }

    function exportCsv() {
        // Override global, allow only CSV for this action
        onlyProvides(&quot;csv&quot;);

        orders = model(&quot;order&quot;).findAll();
    }
}
</code></pre>
