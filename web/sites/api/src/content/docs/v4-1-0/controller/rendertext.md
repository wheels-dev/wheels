---
title: renderText()
description: "Instructs the controller to render specified text when it's finished processing the action."
sidebar:
  label: renderText()
  order: 0
---

## Signature

`renderText()` — returns `void`

**Available in:** `controller`
**Category:** Rendering Functions

## Description

Instructs the controller to render specified text when it's finished processing the action.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `text` | `string` | no | — | The text to render. |
| `status` | `any` | no | `[runtime expression]` | Force request to return with specific HTTP status code. |

</div>

## Examples

<pre><code class='javascript'>// 1. Render a simple text response to the client
renderText(&quot;Done!&quot;);

// 2. Render serialized JSON data to the client
products = model(&quot;Product&quot;).findAll();
renderText(serializeJSON(products));

// 3. Render a plain-text response with a custom HTTP status code
renderText(text=&quot;Not authorized&quot;, status=401);
</code></pre>
