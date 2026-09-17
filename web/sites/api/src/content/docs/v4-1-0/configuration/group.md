---
title: group()
description: "Group routes together with shared attributes like path prefix, name prefix, and constraints without implying a controller package or namespace. Unlike <code>nam"
sidebar:
  label: group()
  order: 0
---

## Signature

`group()` — returns `struct`

**Available in:** `mapper`
**Category:** Routing

## Description

Group routes together with shared attributes like path prefix, name prefix, and constraints without implying a controller package or namespace. Unlike <code>namespace()</code> (which maps to a subfolder and URL prefix) or <code>package()</code> (which maps to a subfolder), <code>group()</code> is a pure organizational grouping mechanism.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | no | — | Name to prepend to child route names for use when building links, forms, and other URLs. |
| `path` | `string` | no | — | URL path prefix to apply to all child routes. |
| `constraints` | `struct` | no | — | Variable patterns (regex constraints) to apply to all child routes. |
| `callback` | `any` | no | — | A callback function to define nested routes within this group. If provided, the group is automatically closed when the callback completes. |

</div>

## Examples

<pre><code class='javascript'>&lt;cfscript&gt;

// 1. Group routes under a shared path prefix (open/close style)
mapper()
    .group(path=&quot;admin&quot;)
        // Route URL: /admin/dashboard
        .get(name=&quot;dashboard&quot;, to=&quot;dashboard##index&quot;)
        // Route URL: /admin/reports
        .get(name=&quot;reports&quot;, to=&quot;reports##index&quot;)
    .end()
.end();

// 2. Group with both a path prefix and a name prefix
mapper()
    .group(path=&quot;account&quot;, name=&quot;account&quot;)
        // Route name:  accountSettings
        // Example URL: /account/settings
        .get(name=&quot;settings&quot;, to=&quot;settings##show&quot;)

        // Route name:  accountBilling
        // Example URL: /account/billing
        .get(name=&quot;billing&quot;, to=&quot;billing##show&quot;)
    .end()
.end();

// 3. Group with regex constraints applied to all child routes
mapper()
    .group(path=&quot;products&quot;, constraints={id: &quot;\d+&quot;})
        // Only matches numeric :id segments
        .get(name=&quot;productShow&quot;, pattern=&quot;[id]&quot;, to=&quot;products##show&quot;)
        .put(name=&quot;productUpdate&quot;, pattern=&quot;[id]&quot;, to=&quot;products##update&quot;)
    .end()
.end();

// 4. Group using a callback function (auto-closes the group)
mapper()
    .group(
        path    = &quot;reports&quot;,
        name    = &quot;report&quot;,
        callback = function(mapper) {
            // Route name:  reportSales
            // Example URL: /reports/sales
            mapper.get(name=&quot;sales&quot;, to=&quot;reports##sales&quot;);

            // Route name:  reportExpenses
            // Example URL: /reports/expenses
            mapper.get(name=&quot;expenses&quot;, to=&quot;reports##expenses&quot;);
        }
    )
.end();

&lt;/cfscript&gt;
</code></pre>
