---
title: root()
description: "Create a route that matches the root of its current context. This mapper can be used for the application's web root (or home page), or it can generate a route f"
sidebar:
  label: root()
  order: 0
---

## Signature

`root()` — returns `struct`

**Available in:** `mapper`
**Category:** Routing

## Description

Create a route that matches the root of its current context. This mapper can be used for the application's web root (or home page), or it can generate a route for the root of a namespace or other path scoping mapper.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `to` | `string` | no | — | Set `controller##action` combination to map the route to. You may use either this argument or a combination of `controller` and `action`. |
| `mapFormat` | `boolean` | no | — | Set to `true` to include the format (e.g. `.json`) in the route. |

## Examples

<pre><code class='javascript'>&lt;cfscript&gt;

mapper()
    .namespace(&quot;api&quot;)
        // Map the root of the `api` folder to the `index` action of the `apis`
        // controller.
        .root(controller=&quot;apis&quot;, action=&quot;index&quot;)
    .end()

    // Map the root of the application to the `show` action of the `dashboards`
    // controller.
    .root(to=&quot;dashboards##show&quot;)
.end();

&lt;/cfscript&gt;</code></pre>
