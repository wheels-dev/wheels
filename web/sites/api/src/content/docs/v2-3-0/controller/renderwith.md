---
title: renderWith()
description: "Instructs the controller to render the data passed in to the format that is requested."
sidebar:
  label: renderWith()
  order: 0
---

## Signature

`renderWith()` — returns `any`

**Available in:** `controller`
**Category:** Rendering Functions

## Description

Instructs the controller to render the data passed in to the format that is requested.
If the format requested is <code>json</code> or <code>xml</code>, CFWheels will transform the data into that format automatically.
For other formats (or to override the automatic formatting), you can also create a view template in this format: <code>nameofaction.xml.cfm</code>, <code>nameofaction.json.cfm</code>, <code>nameofaction.pdf.cfm</code>, etc.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `data` | `any` | yes | — | Data to format and render. |
| `controller` | `string` | no | `[runtime expression]` | Controller to include the view page for. |
| `action` | `string` | no | `[runtime expression]` | Action to include the view page for. |
| `template` | `string` | no | — | A specific template to render. Prefix with a leading slash (`/`) if you need to build a path from the root `views` folder. |
| `layout` | `any` | no | — | The layout to wrap the content in. Prefix with a leading slash (`/`) if you need to build a path from the root `views` folder. Pass `false` to not load a layout at all. |
| `cache` | `any` | no | — | Number of minutes to cache the content for. |
| `returnAs` | `string` | no | — | Set to `string` to return the result instead of automatically sending it to the client. |
| `hideDebugInformation` | `boolean` | no | `false` | Set to `true` to hide the debug information at the end of the output. This is useful, for example, when you're testing XML output in an environment where the global setting for `showDebugInformation` is `true`. |
| `status` | `string` | no | `[runtime expression]` | Force request to return with specific HTTP status code. |

</div>

## Examples

<pre><code class='javascript'>// This will provide the formats defined in the `config()` function.
products = model(&quot;product&quot;).findAll();
renderWith(products);

// Provide a 403 status code for a json response (for example)
msg={
	&quot;status&quot; : &quot;Error&quot;,
	&quot;message&quot;: &quot;Not Authenticated&quot;
}
renderWith(data=msg, status=403)
</code></pre>
