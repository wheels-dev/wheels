---
title: flashIsEmpty()
description: "The flashIsEmpty() function checks whether the Flash scope contains any keys. It returns true if the Flash is empty and false if it contains one or more keys. T"
sidebar:
  label: flashIsEmpty()
  order: 0
---

## Signature

`flashIsEmpty()` — returns `boolean`

**Available in:** `controller`
**Category:** Flash Functions

## Description

The flashIsEmpty() function checks whether the Flash scope contains any keys. It returns true if the Flash is empty and false if it contains one or more keys. This is useful for conditionally displaying messages or deciding whether to process Flash data before reading or clearing it.




## Examples

<pre><code class='javascript'>1. Check if the Flash is empty
if (flashIsEmpty()) {
    writeOutput(&quot;No messages to display.&quot;);
} else {
    writeOutput(&quot;There are messages in Flash.&quot;);
}

2. Use before reading a specific key
if (!flashIsEmpty() &amp;&amp; structKeyExists(flash(), &quot;notice&quot;)) {
    writeOutput(flash(&quot;notice&quot;));
}

3. Typical flow: after clearing Flash
flashClear();
writeOutput(flashIsEmpty()); // true
</code></pre>
