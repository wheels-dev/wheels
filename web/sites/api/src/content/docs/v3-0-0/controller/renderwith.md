---
title: renderWith()
description: "Instructs the controller to render the given data in the format requested by the client. If the requested format is json or xml, Wheels automatically converts t"
sidebar:
  label: renderWith()
  order: 0
---

## Signature

`renderWith()` — returns `any`

**Available in:** `controller`
**Category:** Rendering Functions

## Description

Instructs the controller to render the given data in the format requested by the client. If the requested format is json or xml, Wheels automatically converts the data into the appropriate format. For other formats—or to override automatic formatting—you can create a view template matching the requested format, such as nameofaction.json.cfm, nameofaction.xml.cfm, or nameofaction.pdf.cfm. This function is especially useful in APIs, AJAX endpoints, or situations where you need to respond dynamically in multiple formats based on client preferences. You can also control caching, layout, HTTP status codes, and whether to return the result as a string for further processing.



## Parameters

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

## Examples

<pre><code class='javascript'>1. Render all products in the requested format (json, xml, etc.)
products = model(&quot;product&quot;).findAll();
renderWith(products);

2. Render a JSON error message with a 403 status code
msg = {
    &quot;status&quot; : &quot;Error&quot;,
    &quot;message&quot;: &quot;Not Authenticated&quot;
};
renderWith(data=msg, status=403);

3. Render with a custom layout
products = model(&quot;product&quot;).findAll();
renderWith(data=products, layout=&quot;/layouts/api&quot;);

4. Render a view template from a different controller
data = model(&quot;order&quot;).findAll();
renderWith(data=data, controller=&quot;orders&quot;, action=&quot;list&quot;);

5. Capture the output as a string instead of sending it to the client
output = renderWith(data=products, returnAs=&quot;string&quot;);
</code></pre>
