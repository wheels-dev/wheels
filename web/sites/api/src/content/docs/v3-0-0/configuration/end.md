---
title: end()
description: "Call this to end a nested routing block or the entire route configuration. This method is chained on a sequence of routing mapper method calls started by <code>"
sidebar:
  label: end()
  order: 0
---

## Signature

`end()` — returns `struct`

**Available in:** `mapper`
**Category:** Routing

## Description

Call this to end a nested routing block or the entire route configuration. This method is chained on a sequence of routing mapper method calls started by <code>mapper()</code>.




## Examples

<pre><code class='javascript'>&lt;cfscript&gt;

mapper()
    .namespace(&quot;admin&quot;)
        .resources(&quot;products&quot;)
    .end() // Ends the `namespace` block.

    .scope(package=&quot;public&quot;)
        .resources(name=&quot;products&quot;, nested=true)
          .resources(&quot;variations&quot;)
        .end() // Ends the nested `resources` block.
    .end() // Ends the `scope` block.
.end(); // Ends the `mapper` block.

&lt;/cfscript&gt;</code></pre>
