---
title: namespace()
description: "The namespace() function in Wheels is used to group controllers and routes under a specific namespace (subfolder/package). It also prepends the namespace to rou"
sidebar:
  label: namespace()
  order: 0
---

## Signature

`namespace()` — returns `struct`

**Available in:** `mapper`
**Category:** Routing

## Description

The namespace() function in Wheels is used to group controllers and routes under a specific namespace (subfolder/package). It also prepends the namespace to route names and can modify the URL path. This is useful for organizing APIs, versioning, or modular applications. Namespaces can be nested for hierarchical routing, e.g., /api/v1/... and /api/v2/....



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Name to prepend to child route names. |
| `package` | `string` | no | `[runtime expression]` | Subfolder (package) to reference for controllers. This defaults to the value provided for `name`. |
| `path` | `string` | no | `[runtime expression]` | Subfolder path to add to the URL. |

</div>

## Examples

<pre><code class='javascript'>&lt;cfscript&gt;

mapper()
    .namespace(&quot;api&quot;)
        .namespace(&quot;v2&quot;)
            // Route name:  apiV2Products
            // Example URL: /api/v2/products/1234
            // Controller:  api.v2.Products
            .resources(&quot;products&quot;)
        .end()

        .namespace(&quot;v1&quot;)
            // Route name:  apiV1Users
            // Example URL: /api/v1/users
            // Controller:  api.v1.Users
            .get(name=&quot;users&quot;, to=&quot;users##index&quot;)
        .end()
    .end()

    .namespace(name=&quot;foo&quot;, package=&quot;foos&quot;, path=&quot;foose&quot;)
        // Route name:  fooBars
        // Example URL: /foose/bars
        // Controller:  foos.Bars
        .post(name=&quot;bars&quot;, to=&quot;bars##create&quot;)
    .end()
.end();

&lt;/cfscript&gt;</code></pre>
