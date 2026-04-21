---
title: renderPage()
description: "Instructs the controller which view template and layout to render when it's finished processing the action. Note that when passing values for controller and/or"
sidebar:
  label: renderPage()
  order: 0
---

## Signature

`renderPage()` — returns `any`




## Description

Instructs the controller which view template and layout to render when it's finished processing the action. Note that when passing values for controller and/or action, this function does not execute the actual action but rather just loads the corresponding view template.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `controller` | `string` | yes | — | Controller to include the view page for. |
| `action` | `string` | yes | — | Action to include the view page for. |
| `template` | `string` | yes | — | A specific template to render. Prefix with a leading slash / if you need to build a path from the root views folder. |
| `layout` | `any` | yes | — | The layout to wrap the content in. Prefix with a leading slash / if you need to build a path from the root views folder. Pass false to not load a layout at all. |
| `cache` | `any` | yes | — | Number of minutes to cache the content for. |
| `returnAs` | `string` | yes | — | Set to string to return the result instead of automatically sending it to the client. |
| `hideDebugInformation` | `boolean` | yes | `false` | Set to true to hide the debug information at the end of the output. This is useful when you're testing XML output in an environment where the global setting for showDebugInformation is true. |

</div>

## Examples

<pre>// Render a view page for a different action within the same controller
renderPage(action=&quot;edit&quot;);

// Render a view page for a different action within a different controller
renderPage(controller=&quot;blog&quot;, action=&quot;new&quot;);

// Another way to render the blog/new template from within a different controller
renderPage(template=&quot;/blog/new&quot;);

// Render the view page for the current action but without a layout and cache it for 60 minutes
renderPage(layout=false, cache=60);

// Load a layout from a different folder within `views`
renderPage(layout=&quot;/layouts/blog&quot;);

// Don''t render the view immediately but rather return and store in a variable for further processing
myView = renderPage(returnAs=&quot;string&quot;);</pre>
