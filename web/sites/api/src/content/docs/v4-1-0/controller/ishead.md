---
title: isHead()
description: "Returns whether the request was a <code>HEAD</code> request or not."
sidebar:
  label: isHead()
  order: 0
---

## Signature

`isHead()` — returns `boolean`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

Returns whether the request was a <code>HEAD</code> request or not.




## Examples

<pre><code class='javascript'>// 1. Respond to a HEAD request by rendering nothing
if (isHead()) {
    renderNothing();
}

// 2. Restrict an action to HEAD requests only
if (!isHead()) {
    renderText(&quot;Method not allowed&quot;);
}

// 3. Store the result to use in a conditional
requestIsHead = isHead();
// requestIsHead -&gt; true when the HTTP method is HEAD, false otherwise
</code></pre>
