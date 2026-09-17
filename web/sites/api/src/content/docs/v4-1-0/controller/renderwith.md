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
If the format requested is <code>json</code> or <code>xml</code>, Wheels will transform the data into that format automatically.
For other formats (or to override the automatic formatting), you can also create a view template in this format: <code>nameofaction.xml.cfm</code>, <code>nameofaction.json.cfm</code>, <code>nameofaction.pdf.cfm</code>, etc.
Per-action format restrictions set with <code>onlyProvides()</code> are enforced here (since 4.0.4):
when the requested format is not acceptable for the action, <code>renderWith()</code> falls back to
rendering the <code>html</code> view — even when <code>html</code> itself is not in the <code>onlyProvides()</code> list.



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

<pre><code class='javascript'>// 1. Render a query using the format defined in the controller's `config()` function.
// Wheels automatically serializes to JSON or XML when those formats are requested.
products = model(&quot;Product&quot;).findAll();
renderWith(products);

// 2. Return a JSON error payload with a specific HTTP status code.
msg = {
	&quot;status&quot;: &quot;Error&quot;,
	&quot;message&quot;: &quot;Not Authenticated&quot;
};
renderWith(data=msg, status=403);

// 3. Render a struct as JSON and return the result as a string instead of sending it to the client.
payload = {&quot;id&quot;: 1, &quot;name&quot;: &quot;Alice&quot;};
jsonString = renderWith(data=payload, returnAs=&quot;string&quot;);

// 4. Render with a custom XML template for the current action
// (looks for a view file named `show.xml.cfm` in the current controller's views folder).
user = model(&quot;User&quot;).findByKey(params.key);
renderWith(data=user, layout=false, hideDebugInformation=true);

// 5. Render data using a specific template from outside the current controller's views folder.
report = model(&quot;Order&quot;).findAll(select=&quot;id,total,createdAt&quot;);
renderWith(data=report, template=&quot;/reports/summary&quot;, layout=false);
</code></pre>
