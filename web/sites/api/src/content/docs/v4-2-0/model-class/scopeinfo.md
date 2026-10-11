---
title: scopeInfo()
description: "Returns a struct containing all named scope definitions for this model."
sidebar:
  label: scopeInfo()
  order: 0
---

## Signature

`scopeInfo()` — returns `struct`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Returns a struct containing all named scope definitions for this model.
Each key is the scope name, and the value is a struct with query fragment keys like <code>where</code>, <code>order</code>, <code>select</code>, <code>include</code>.




## Examples

<pre><code class='javascript'>// 1. Inspect all named scopes defined on a model
info = model(&quot;Article&quot;).scopeInfo();
// info -&gt; {
//   active:    { where: &quot;status = 'active'&quot; },
//   recent:    { where: &quot;publishedAt &gt; ?&quot;, order: &quot;publishedAt DESC&quot; },
//   published: { where: &quot;status = 'published'&quot;, order: &quot;publishedAt DESC&quot; }
// }

// 2. Check whether a specific scope is defined before using it
info = model(&quot;User&quot;).scopeInfo();
if (structKeyExists(info, &quot;admins&quot;)) {
    admins = model(&quot;User&quot;).admins().findAll();
}

// 3. List all scope names registered on a model
info = model(&quot;Post&quot;).scopeInfo();
writeOutput(structKeyList(info));
// -&gt; &quot;featured,archived,byDate&quot;
</code></pre>
