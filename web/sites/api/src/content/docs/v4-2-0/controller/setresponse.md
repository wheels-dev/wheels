---
title: setResponse()
description: "Sets content that Wheels will send to the client in response to the request."
sidebar:
  label: setResponse()
  order: 0
---

## Signature

`setResponse()` — returns `void`

**Available in:** `controller`
**Category:** Rendering Functions

## Description

Sets content that Wheels will send to the client in response to the request.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `content` | `string` | yes | — | The content to send to the client. |

</div>

## Examples

<pre><code class='javascript'>// 1. Override the response body with a plain string
setResponse(&quot;Maintenance mode active. Please try again later.&quot;);

// 2. Modify an already-rendered response in an after filter
// (e.g. append a debug comment to every HTML response)
private void function appendDebugComment() {
    current = response();
    setResponse(current &amp; &quot;&lt;!-- rendered at #Now()# --&gt;&quot;);
}

// 3. Replace the response with serialized data after a renderView() call
// (useful in tests or custom middleware-style filters)
setResponse(serializeJSON({status: &quot;ok&quot;, timestamp: Now()}));
</code></pre>
