---
title: package()
description: "Scopes the controllers for any routes defined inside its block to a specific subfolder (package) without adding the package name to the URL. This is useful for"
sidebar:
  label: package()
  order: 0
---

## Signature

`package()` — returns `struct`

**Available in:** `mapper`
**Category:** Routing

## Description

Scopes the controllers for any routes defined inside its block to a specific subfolder (package) without adding the package name to the URL. This is useful for organizing your controllers in subfolders while keeping the URL structure clean.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Name to prepend to child route names. |
| `package` | `string` | no | `[runtime expression]` | Subfolder (package) to reference for controllers. This defaults to the value provided for `name`. |

## Examples

<pre><code class='javascript'>&lt;cfscript&gt;

mapper()
    .package(&quot;public&quot;)
        // Example URL: /products/1234
        // Controller:  public.Products
        .resources(&quot;products&quot;)
    .end()

    // Example URL: /users/4321
    // Controller:  Users
    .resources(name=&quot;users&quot;, nested=true)
        // Calling `package` here is useful to scope nested routes for the `users`
        // resource into a subfolder.
        .package(&quot;users&quot;)
            // Example URL: /users/4321/profile
            // Controller:  users.Profiles
            .resource(&quot;profile&quot;)
        .end()
    .end()
.end();

&lt;/cfscript&gt;</code></pre>
