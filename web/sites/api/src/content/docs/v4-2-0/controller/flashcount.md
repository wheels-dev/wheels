---
title: flashCount()
description: "Returns how many keys exist in the Flash."
sidebar:
  label: flashCount()
  order: 0
---

## Signature

`flashCount()` — returns `numeric`

**Available in:** `controller`
**Category:** Flash Functions

## Description

Returns how many keys exist in the Flash.




## Examples

<pre><code class='javascript'>// 1. Check how many keys are currently in the Flash
count = flashCount();
// count -&gt; 0 (Flash is empty), or a positive integer when keys exist

// 2. Only render a Flash notice section when there is something to show
if (flashCount()) {
    writeOutput(&quot;You have &quot; &amp; flashCount() &amp; &quot; flash message(s).&quot;);
}

// 3. Use alongside flashIsEmpty() — flashCount() powers the isEmpty check
flashInsert(notice=&quot;Saved successfully&quot;, warning=&quot;Check your email&quot;);
count = flashCount();
// count -&gt; 2
</code></pre>
