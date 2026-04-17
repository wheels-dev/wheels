---
title: renderPartial()
description: "Instructs the controller to render a partial view when an action completes. Partials are reusable view fragments, typically prefixed with an underscore (e.g., _"
sidebar:
  label: renderPartial()
  order: 0
---

## Signature

`renderPartial()` — returns `any`

**Available in:** `controller`
**Category:** Rendering Functions

## Description

Instructs the controller to render a partial view when an action completes. Partials are reusable view fragments, typically prefixed with an underscore (e.g., _comment.cfm). This function allows you to render these fragments either directly to the client or capture them as a string for further processing. You can control caching, layouts, HTTP status codes, and data-loading behavior, making it flexible for both full-page updates and AJAX responses.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `partial` | `string` | yes | — | The name of the partial file to be used. Prefix with a leading slash (`/`) if you need to build a path from the root `views` folder. Do not include the partial filename's underscore and file extension. |
| `cache` | `any` | no | — | Number of minutes to cache the content for. |
| `layout` | `string` | no | — | The layout to wrap the content in. Prefix with a leading slash (`/`) if you need to build a path from the root `views` folder. Pass `false` to not load a layout at all. |
| `returnAs` | `string` | no | — | Set to `string` to return the result instead of automatically sending it to the client. |
| `dataFunction` | `any` | no | `true` | Name of a controller function to load data from. |
| `status` | `string` | no | `[runtime expression]` | Force request to return with specific HTTP status code. |

## Examples

<pre><code class='javascript'>1. Render a partial in the current controller's view folder
renderPartial(&quot;comment&quot;);

2. Render a partial from the shared folder
renderPartial(&quot;/shared/comment&quot;);

3. Render a partial without a layout
renderPartial(partial=&quot;/shared/comment&quot;, layout=false);

4. Render a partial and return it as a string
commentHtml = renderPartial(partial=&quot;comment&quot;, returnAs=&quot;string&quot;);

5. Render a partial with caching for 15 minutes
renderPartial(partial=&quot;comment&quot;, cache=15);

6. Render a partial with a custom HTTP status code
renderPartial(partial=&quot;comment&quot;, status=&quot;202&quot;);
</code></pre>
