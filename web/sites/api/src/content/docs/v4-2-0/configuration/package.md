---
title: package()
description: "Scopes any the controllers for any routes configured within this block to a subfolder (package) without adding the package name to the URL."
sidebar:
  label: package()
  order: 0
---

## Signature

`package()` — returns `struct`

**Available in:** `mapper`
**Category:** Routing

## Description

Scopes any the controllers for any routes configured within this block to a subfolder (package) without adding the package name to the URL.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Name to prepend to child route names. |
| `package` | `string` | no | `[runtime expression]` | Subfolder (package) to reference for controllers. This defaults to the value provided for `name`. |

</div>

## Examples

<pre><code class='javascript'>&lt;cfscript&gt;

// 1. Scope controllers into a subfolder without adding the package name to the URL
mapper()
    .package(&quot;admin&quot;)
        // Route name:  adminProducts
        // Example URL: /products (no &quot;admin&quot; in the URL)
        // Controller:  admin.Products
        .resources(&quot;products&quot;)

        // Example URL: /users (no &quot;admin&quot; in the URL)
        // Controller:  admin.Users
        .resources(&quot;users&quot;)
    .end()
.end();

// 2. Use the `package` argument to override the subfolder name
mapper()
    .package(name=&quot;v2&quot;, package=&quot;api/v2&quot;)
        // Route name:  v2Articles
        // Example URL: /articles
        // Controller:  api/v2.Articles
        .resources(&quot;articles&quot;)
    .end()
.end();

// 3. Nest a `package` inside a resource to scope sub-resource controllers
mapper()
    .resources(name=&quot;users&quot;, nested=true)
        // Calling `package` here scopes nested routes to a subfolder without
        // changing the URL structure.
        .package(&quot;users&quot;)
            // Route name:  usersProfile
            // Example URL: /users/4321/profile
            // Controller:  users.Profiles
            .resource(&quot;profile&quot;)
        .end()
    .end()
.end();

&lt;/cfscript&gt;
</code></pre>
