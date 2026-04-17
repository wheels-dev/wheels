---
title: renderView()
description: "Instructs the controller which view template and layout to render when it's finished processing the action."
sidebar:
  label: renderView()
  order: 0
---

## Signature

`renderView()` — returns `any`

**Available in:** `controller`
**Category:** Rendering Functions

## Description

Instructs the controller which view template and layout to render when it's finished processing the action.
Note that when passing values for controller and / or action, this function does not execute the actual action but rather just loads the corresponding view template.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `controller` | `string` | no | `[runtime expression]` | Controller to include the view page for. |
| `action` | `string` | no | `[runtime expression]` | Action to include the view page for. |
| `template` | `string` | no | — | A specific template to render. Prefix with a leading slash (`/`) if you need to build a path from the root `views` folder. |
| `layout` | `any` | no | — | The layout to wrap the content in. Prefix with a leading slash (`/`) if you need to build a path from the root `views` folder. Pass `false` to not load a layout at all. |
| `cache` | `any` | no | — | Number of minutes to cache the content for. |
| `returnAs` | `string` | no | — | Set to `string` to return the result instead of automatically sending it to the client. |
| `hideDebugInformation` | `boolean` | no | `false` | Set to `true` to hide the debug information at the end of the output. This is useful, for example, when you're testing XML output in an environment where the global setting for `showDebugInformation` is `true`. |
| `status` | `string` | no | `[runtime expression]` | Force request to return with specific HTTP status code. |

## Examples

<pre><code class='javascript'>// Render a view page for a different action within the same controller.
renderView(action=&quot;edit&quot;);

// Render a view page for a different action within a different controller.
renderView(controller=&quot;blog&quot;, action=&quot;new&quot;);

// Another way to render the blog/new template from within a different controller.
renderView(template=&quot;/blog/new&quot;);

// Render the view page for the current action but without a layout and cache it for 60 minutes.
renderView(layout=false, cache=60);

// Load a layout from a different folder within `views`.
renderView(layout=&quot;/layouts/blog&quot;);

// Don't render the view immediately but rather return and store in a variable for further processing.
myView = renderView(returnAs=&quot;string&quot;);
</code></pre>
