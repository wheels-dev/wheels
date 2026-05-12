---
title: setResponse()
description: "Allows you to manually set the content that Wheels will send back to the client for a given request. Unlike <code>renderView()</code> or <code>renderText()</cod"
sidebar:
  label: setResponse()
  order: 0
---

## Signature

`setResponse()` — returns `void`

**Available in:** `controller`
**Category:** Rendering Functions

## Description

Allows you to manually set the content that Wheels will send back to the client for a given request. Unlike <code>renderView()</code> or <code>renderText()</code>, which automatically generate output from templates or data, <code>setResponse()</code> gives you full control over the response content.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `content` | `string` | yes | — | The content to send to the client. |

</div>

## Examples

<pre><code class='javascript'>1. Sending plain text
function myAction() {
    setResponse(&quot;This is a custom response sent directly to the client.&quot;);
}

2. Sending JSON content
function getUserData() {
    user = model(&quot;user&quot;).findByKey(1);
    
    // Convert the user object to JSON
    jsonData = serializeJson(user);
    
    // Set the JSON response
    setResponse(jsonData);
}
cfheader(name=&quot;Content-Type&quot;, value=&quot;application/json&quot;);

3. Sending HTML content
function showCustomHtml() {
    htmlContent = &quot;&lt;h1&gt;Welcome!&lt;/h1&gt;&lt;p&gt;This is a custom HTML response.&lt;/p&gt;&quot;;
    setResponse(htmlContent);
}</code></pre>
