---
title: member()
description: "Scope routes within a nested resource which require use of the primary key as part of the URL pattern;"
sidebar:
  label: member()
  order: 0
---

## Signature

`member()` — returns `struct`

**Available in:** `mapper`
**Category:** Routing

## Description

Scope routes within a nested resource which require use of the primary key as part of the URL pattern;
A member route will require an ID, because it acts on a member.
photos/1/preview is an example of a member route, because it acts on (and displays) a single object.




## Examples

<pre><code class='javascript'>&lt;cfscript&gt;

// 1. Add a preview route acting on a single photo (GET /photos/1/preview)
mapper()
    .resources(name=&quot;photos&quot;, nested=true)
        .member()
            .get(&quot;preview&quot;)
        .end()
    .end()
.end();

// 2. Add multiple member routes (GET /articles/1/publish, DELETE /articles/1/archive)
mapper()
    .resources(name=&quot;articles&quot;, nested=true)
        .member()
            .get(&quot;publish&quot;)
            .delete(&quot;archive&quot;)
        .end()
    .end()
.end();

&lt;/cfscript&gt;
</code></pre>
