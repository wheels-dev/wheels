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

<pre><code class='javascript'>// Render the partial `_comment.cfm` located in the current controller's view folder
renderPartial(&quot;comment&quot;);

// Render the partial at `views/shared/_comment.cfm`
renderPartial(&quot;/shared/comment&quot;);</code></pre>
