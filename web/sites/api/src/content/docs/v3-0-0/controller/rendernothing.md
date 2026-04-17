---
title: renderNothing()
description: "Instructs the controller to render an empty response when an action completes. Unlike using cfabort, which stops request processing immediately, renderNothing()"
sidebar:
  label: renderNothing()
  order: 0
---

## Signature

`renderNothing()` — returns `void`

**Available in:** `controller`
**Category:** Rendering Functions

## Description

Instructs the controller to render an empty response when an action completes. Unlike using cfabort, which stops request processing immediately, renderNothing() ensures that any after filters associated with the action still execute. You can optionally provide an HTTP status code to indicate the type of response being returned. This is useful for APIs or endpoints that need to signal a specific status without returning a body.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `status` | `string` | no | `[runtime expression]` | Force request to return with specific HTTP status code. |

## Examples

<pre><code class='javascript'>1. Render an empty page with default status (200 OK)
renderNothing();

2. Render nothing with a 204 No Content status
renderNothing(status=&quot;204&quot;);

3. Use renderNothing in an API endpoint after deleting a resource
function deleteResource() {
    resource = model(&quot;resource&quot;).findByKey(params.id);
    resource.delete();
    renderNothing(status=&quot;204&quot;);
}
</code></pre>
