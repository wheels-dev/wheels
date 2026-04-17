---
title: collection()
description: "Defines a collection route in your Wheels application. Collection routes operate on a set of resources and do not require an id, unlike member routes which act"
sidebar:
  label: collection()
  order: 0
---

## Signature

`collection()` — returns `struct`

**Available in:** `mapper`
**Category:** Routing

## Description

Defines a collection route in your Wheels application. Collection routes operate on a set of resources and do not require an id, unlike member routes which act on a single resource. This is useful when building actions that retrieve, filter, or display multiple objects, such as search pages, listings, or batch operations.




## Examples

<pre><code class='javascript'>
&lt;cfscript&gt;

mapper()
    // Create a route like `photos/search`
    .resources(name=&quot;photos&quot;, nested=true)
        .collection()
            .get(&quot;search&quot;)
        .end()
    .end()
.end();

&lt;/cfscript&gt;
</code></pre>
