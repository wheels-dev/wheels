---
title: constraints()
description: "Set variable patterns to use for matching."
sidebar:
  label: constraints()
  order: 0
---

## Signature

`constraints()` — returns `struct`

**Available in:** `mapper`
**Category:** Routing

## Description

Set variable patterns to use for matching.




## Examples

<pre><code class='javascript'>&lt;cfscript&gt;

mapper()
    // 1. Constrain a dynamic segment to digits only
    .constraints(id=&quot;[0-9]+&quot;)
        .resources(name=&quot;articles&quot;)
    .end()

    // 2. Constrain multiple segments — numeric id and lowercase-only slug
    .constraints(id=&quot;[0-9]+&quot;, slug=&quot;[a-z\-]+&quot;)
        .get(name=&quot;article&quot;, to=&quot;articles##show&quot;)
        .get(name=&quot;articleBySlug&quot;, to=&quot;articles##showBySlug&quot;)
    .end()
.end();

&lt;/cfscript&gt;
</code></pre>
