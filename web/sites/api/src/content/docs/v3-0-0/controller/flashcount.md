---
title: flashCount()
description: "The flashCount() function returns the number of keys currently stored in the Flash scope. This is useful to check whether there are any flash messages or tempor"
sidebar:
  label: flashCount()
  order: 0
---

## Signature

`flashCount()` — returns `numeric`

**Available in:** `controller`
**Category:** Flash Functions

## Description

The flashCount() function returns the number of keys currently stored in the Flash scope. This is useful to check whether there are any flash messages or temporary data before attempting to read or display them. It helps in conditionally rendering notifications or determining if the Flash is empty.




## Examples

<pre><code class='javascript'>1. Get the number of items in Flash
count = flashCount();

2. Check if there are any flash messages before displaying
if (flashCount() &gt; 0) {
    writeOutput(&quot;You have &quot; &amp; flashCount() &amp; &quot; messages in Flash.&quot;);
}

3. Only display notice if Flash is not empty
if (flashCount() &gt; 0 &amp;&amp; structKeyExists(flash(), &quot;notice&quot;)) {
    writeOutput(flash(&quot;notice&quot;));
}
</code></pre>
