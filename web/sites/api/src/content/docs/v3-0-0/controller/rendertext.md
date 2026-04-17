---
title: renderText()
description: "Instructs the controller to output plain text as the response when an action completes. Unlike rendering a view or partial, this sends the specified text direct"
sidebar:
  label: renderText()
  order: 0
---

## Signature

`renderText()` — returns `void`

**Available in:** `controller`
**Category:** Rendering Functions

## Description

Instructs the controller to output plain text as the response when an action completes. Unlike rendering a view or partial, this sends the specified text directly to the client. This is especially useful for APIs, AJAX responses, or simple status messages. You can also provide an HTTP status code to control the response status.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `text` | `string` | no | — | The text to render. |
| `status` | `any` | no | `[runtime expression]` | Force request to return with specific HTTP status code. |

## Examples

<pre><code class='javascript'>1. Render a simple message
renderText(&quot;Done!&quot;);

2. Render serialized product data as JSON
products = model(&quot;product&quot;).findAll();
renderText(SerializeJson(products));

3. Render a message with a custom HTTP status code
renderText(text=&quot;Unauthorized access&quot;, status=401);

4. Use in an API endpoint
function checkStatus() {
    if (someCondition()) {
        renderText(text=&quot;OK&quot;, status=200);
    } else {
        renderText(text=&quot;Error&quot;, status=500);
    }
}
</code></pre>
