---
title: flashIsEmpty()
description: "Returns whether or not the Flash is empty."
sidebar:
  label: flashIsEmpty()
  order: 0
---

## Signature

`flashIsEmpty()` — returns `boolean`

**Available in:** `controller`
**Category:** Flash Functions

## Description

Returns whether or not the Flash is empty.




## Examples

<pre><code class='javascript'>// 1. Check whether the Flash is empty before rendering a notice area
if (!flashIsEmpty()) {
    writeOutput(flash(&quot;notice&quot;));
}

// 2. Insert a message and confirm the Flash is no longer empty
flashInsert(notice=&quot;Record saved successfully.&quot;);
empty = flashIsEmpty();
// empty -&gt; false

// 3. After clearing the Flash, confirm it is empty again
flashClear();
empty = flashIsEmpty();
// empty -&gt; true
</code></pre>
