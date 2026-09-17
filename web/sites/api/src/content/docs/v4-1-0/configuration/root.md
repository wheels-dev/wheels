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

Create a route that matches the root of its current context. This mapper can be used for the application's web root (or home page), or it can generate a route for the root of a namespace or other path scoping mapper. The route only responds to the <code>GET</code> verb unless you explicitly pass a <code>method</code> (or <code>methods</code>) argument.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `to` | `string` | no | — | Set `controller##action` combination to map the route to. You may use either this argument or a combination of `controller` and `action`. |
| `mapFormat` | `boolean` | no | — | Set to `true` to include the format (e.g. `.json`) in the route. |

</div>

## Examples

<pre><code class='javascript'>&lt;cfscript&gt;

// 1. Map the application's web root (home page) to a specific controller action
mapper()
    // Map &quot;/&quot; to the `index` action of the `home` controller
    .root(to=&quot;home##index&quot;)
.end();

// 2. Map the root of a namespace scope using separate controller and action arguments
mapper()
    .namespace(&quot;admin&quot;)
        // Map &quot;/admin/&quot; to the `dashboard` action of the `admin` controller
        .root(controller=&quot;admin&quot;, action=&quot;dashboard&quot;)
    .end()
.end();

// 3. Map the root with format matching enabled so &quot;.json&quot; etc. are captured
mapper()
    .namespace(&quot;api&quot;)
        // Map &quot;/api/&quot; and &quot;/api/.json&quot; (etc.) to the `apis` controller's `index` action
        .root(to=&quot;apis##index&quot;, mapFormat=true)
    .end()
.end();

&lt;/cfscript&gt;
</code></pre>
