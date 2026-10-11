---
title: isOptions()
description: "Returns whether the request was an <code>OPTIONS</code> request or not."
sidebar:
  label: isOptions()
  order: 0
---

## Signature

`isOptions()` — returns `boolean`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

Returns whether the request was an <code>OPTIONS</code> request or not.




## Examples

<pre><code class='javascript'>// 1. Respond to a CORS preflight OPTIONS request
if (isOptions()) {
    header(name = &quot;Access-Control-Allow-Methods&quot;, value = &quot;GET, POST, PUT, DELETE&quot;);
    renderNothing();
    return;
}

// 2. Restrict an action to only handle OPTIONS requests
if (!isOptions()) {
    redirectTo(action = &quot;index&quot;);
}

// 3. Store the result to use in a conditional
requestIsOptions = isOptions();
// requestIsOptions -&gt; true when the HTTP method is OPTIONS, false otherwise
</code></pre>
