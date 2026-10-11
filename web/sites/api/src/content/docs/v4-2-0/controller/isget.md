---
title: isGet()
description: "Returns whether the request was a normal <code>GET</code> request or not."
sidebar:
  label: isGet()
  order: 0
---

## Signature

`isGet()` — returns `boolean`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

Returns whether the request was a normal <code>GET</code> request or not.




## Examples

<pre><code class='javascript'>// 1. Only allow GET requests in an action
if (!isGet()) {
    redirectTo(action = &quot;index&quot;);
}

// 2. Respond differently depending on the HTTP method
if (isGet()) {
    // Render the form for display
    user = model(&quot;User&quot;).findByKey(params.key);
} else {
    // Handle a non-GET submission
    renderNothing();
}

// 3. Store the result to use in a conditional
requestIsGet = isGet();
// requestIsGet -&gt; true (for a normal page request), false otherwise
</code></pre>
