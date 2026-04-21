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

<pre><code class='javascript'>// Render just the text &quot;Done!&quot; to the client
renderText(&quot;Done!&quot;);

// Render serialized product data to the client
products = model(&quot;product&quot;).findAll();
renderText(SerializeJson(products));</code></pre>
