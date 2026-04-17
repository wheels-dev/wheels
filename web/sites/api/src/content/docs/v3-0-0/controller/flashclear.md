---
title: flashClear()
description: "The flashClear() function removes all keys and values from the Flash scope. This is useful when you want to reset or clear out any temporary messages or data th"
sidebar:
  label: flashClear()
  order: 0
---

## Signature

`flashClear()` — returns `void`

**Available in:** `controller`
**Category:** Flash Functions

## Description

The flashClear() function removes all keys and values from the Flash scope. This is useful when you want to reset or clear out any temporary messages or data that were carried over from a previous request. After calling flashClear(), the Flash will be empty for the remainder of the request and any future requests until new values are inserted.




## Examples

<pre><code class='javascript'>1. Clear all flash values at the start of an action
flashClear();

2. Clear messages after they've been displayed
notice = flash(&quot;notice&quot;);
if (len(notice)) {
    writeOutput(notice);
    flashClear(); // reset Flash so it doesn't show again
}

3. Use before redirecting if you want to ensure no old flash values remain
flashClear();
redirectTo(action=&quot;index&quot;);
</code></pre>
