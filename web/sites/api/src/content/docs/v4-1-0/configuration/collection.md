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

<pre><code class='javascript'>&lt;cfscript&gt;

// 1. Add a search route acting on the photos collection (GET /photos/search)
mapper()
    .resources(name=&quot;photos&quot;, nested=true)
        .collection()
            .get(&quot;search&quot;)
        .end()
    .end()
.end();

// 2. Add multiple collection routes (GET /articles/featured, POST /articles/bulk-delete)
mapper()
    .resources(name=&quot;articles&quot;, nested=true)
        .collection()
            .get(&quot;featured&quot;)
            .post(&quot;bulkDelete&quot;)
        .end()
    .end()
.end();

&lt;/cfscript&gt;
</code></pre>
