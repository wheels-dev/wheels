---
title: flashClear()
description: "Deletes everything from the Flash."
sidebar:
  label: flashClear()
  order: 0
---

## Signature

`flashClear()` — returns `void`

**Available in:** `controller`
**Category:** Flash Functions

## Description

Deletes everything from the Flash.




## Examples

<pre><code class='javascript'>// 1. Clear all flash data
flashClear();

// 2. Insert some messages, then clear them all before redirecting
flashInsert(notice=&quot;Record saved.&quot;);
flashInsert(warning=&quot;Check your settings.&quot;);
// Oops — wipe everything and start fresh
flashClear();
// flash() is now an empty struct: {}

// 3. Clear flash conditionally inside a controller action
function checkout() {
    if (!isLoggedIn()) {
        flashClear();
        flashInsert(error=&quot;You must be logged in to check out.&quot;);
        redirectTo(action=&quot;login&quot;);
    }
}
</code></pre>
