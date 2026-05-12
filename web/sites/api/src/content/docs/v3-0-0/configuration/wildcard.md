---
title: wildcard()
description: "Automatically generates dynamic routes for your controllers using placeholders like [controller], [action], and optionally [key] or [format]. This allows you to"
sidebar:
  label: wildcard()
  order: 0
---

## Signature

`wildcard()` — returns `struct`

**Available in:** `mapper`
**Category:** Routing

## Description

Automatically generates dynamic routes for your controllers using placeholders like [controller], [action], and optionally [key] or [format]. This allows you to quickly map standard URL patterns to controllers and actions without explicitly defining every route.


## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `method` | `string` | no | `get` | List of HTTP methods (verbs) to generate the wildcard routes for. We strongly recommend leaving the default value of `get` and using other routing mappers if you need to `POST` to a URL endpoint. For better readability, you can also pass this argument as `methods` if you're listing multiple methods. |
| `action` | `string` | no | `index` | Default action to specify if the value for the `[action]` placeholder is not provided. |
| `mapKey` | `boolean` | no | `false` | Whether or not to enable a `[key]` matcher, enabling a `[controller]/[action]/[key]` pattern. |
| `mapFormat` | `boolean` | no | `false` | Whether or not to add an optional `.[format]` pattern to the end of the generated routes. This is useful for providing formats via URL like `json`, `xml`, `pdf`, etc. |

</div>

## Examples

<pre><code class='javascript'>&lt;cfscript&gt;

mapper()
    // Enables `[controller]` and `[controller]/[action]`, only via `GET` requests.
    .wildcard()

    // Enables `[controller]/[action]/[key]` as well.
    .wildcard(mapKey=true)

    // Also enables patterns like `[controller].[format]` and
    // `[controller]/[action].[format]`
    .wildcard(mapFormat=true)

    // Allow additional methods beyond just `GET`
    //
    // Note that this can open some serious security holes unless you use `verifies`
    // in the controller to make sure that requests changing data can only occur
    // with a `POST` method.
    .wildcard(methods=&quot;get,post&quot;)
.end();

&lt;/cfscript&gt;</code></pre>
