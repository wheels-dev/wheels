---
title: renderPartial()
description: "Instructs the controller to render a partial when it's finished processing the action."
sidebar:
  label: renderPartial()
  order: 0
---

## Signature

`renderPartial()` — returns `any`

**Available in:** `controller`
**Category:** Rendering Functions

## Description

Instructs the controller to render a partial when it's finished processing the action.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `partial` | `string` | yes | — | The name of the partial file to be used. Prefix with a leading slash (`/`) if you need to build a path from the root `views` folder. Do not include the partial filename's underscore and file extension. |
| `cache` | `any` | no | — | Number of minutes to cache the content for. |
| `layout` | `string` | no | — | The layout to wrap the content in. Prefix with a leading slash (`/`) if you need to build a path from the root `views` folder. Pass `false` to not load a layout at all. |
| `returnAs` | `string` | no | — | Set to `string` to return the result instead of automatically sending it to the client. |
| `dataFunction` | `any` | no | `true` | Name of a controller function to load data from. |
| `status` | `string` | no | `[runtime expression]` | Force request to return with specific HTTP status code. |

</div>

## Examples

<pre><code class='javascript'>// 1. Render the partial `_comment.cfm` located in the current controller's view folder
renderPartial(&quot;comment&quot;);

// 2. Render the partial at `app/views/shared/_comment.cfm` using an absolute path
renderPartial(&quot;/shared/comment&quot;);

// 3. Return the rendered partial as a string instead of sending it to the client
commentHtml = renderPartial(partial=&quot;comment&quot;, returnAs=&quot;string&quot;);

// 4. Render a shared partial wrapped in a layout and cache it for 5 minutes
renderPartial(partial=&quot;/shared/sidebar&quot;, layout=&quot;/layouts/sidebar&quot;, cache=5);

// 5. Render a partial using a named data-loading function to supply variables
//    (the controller must have a private function named `comment` returning a struct)
renderPartial(partial=&quot;comment&quot;, dataFunction=&quot;comment&quot;);

// 6. Render a partial and force a specific HTTP status code (e.g. for AJAX responses)
renderPartial(partial=&quot;/shared/error&quot;, status=422);
</code></pre>
