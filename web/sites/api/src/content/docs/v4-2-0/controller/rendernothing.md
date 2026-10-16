---
title: renderNothing()
description: "Instructs the controller to render an empty string when it's finished processing the action."
sidebar:
  label: renderNothing()
  order: 0
---

## Signature

`renderNothing()` — returns `void`

**Available in:** `controller`
**Category:** Rendering Functions

## Description

Instructs the controller to render an empty string when it's finished processing the action.
This is very similar to calling <code>cfabort</code> with the advantage that any after filters you have set on the action will still be run.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `status` | `string` | no | `[runtime expression]` | Force request to return with specific HTTP status code. |

</div>

## Examples

<pre><code class='javascript'>// 1. Render a blank response (useful for AJAX fire-and-forget actions)
renderNothing();

// 2. Render a blank response with a specific HTTP status code (e.g., 204 No Content)
renderNothing(status=204);

// 3. Use renderNothing() instead of cfabort so that after-filters still run
// In a controller action:
function markAsRead() {
    post = model(&quot;Post&quot;).findByKey(params.key);
    post.update(read=true);
    // After-filters (e.g. logging) will still execute, unlike cfabort
    renderNothing();
}
</code></pre>
