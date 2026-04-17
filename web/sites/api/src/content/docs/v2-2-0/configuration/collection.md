---
title: collection()
description: "A collection route doesn't require an id because it acts on a collection of objects."
sidebar:
  label: collection()
  order: 0
---

## Signature

`collection()` — returns `struct`

**Available in:** `mapper`
**Category:** Routing

## Description

A collection route doesn't require an id because it acts on a collection of objects.
photos/search is an example of a collection route, because it acts on (and displays) a collection of objects.




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
