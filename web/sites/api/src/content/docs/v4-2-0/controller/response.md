---
title: response()
description: "Returns content that Wheels will send to the client in response to the request."
sidebar:
  label: response()
  order: 0
---

## Signature

`response()` — returns `string`

**Available in:** `controller`
**Category:** Rendering Functions

## Description

Returns content that Wheels will send to the client in response to the request.




## Examples

<pre><code class='javascript'>// 1. Get the current response content (empty string if nothing has been rendered yet)
content = response();

// 2. Use in a controller test to verify rendered output
// (Wheels populates the response after renderView, renderText, or renderPartial runs)
renderText(&quot;Hello, world!&quot;);
assert(&quot;response() eq 'Hello, world!'&quot;);

// 3. Inspect and modify the response before it is sent to the client
currentContent = response();
if (FindNoCase(&quot;&lt;!-- debug --&gt;&quot;, currentContent)) {
    setResponse(Replace(currentContent, &quot;&lt;!-- debug --&gt;&quot;, &quot;&quot;, &quot;all&quot;));
}
</code></pre>
