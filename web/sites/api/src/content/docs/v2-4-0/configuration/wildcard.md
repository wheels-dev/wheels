---
title: wildcard()
description: "Special wildcard matching generates routes with `"
sidebar:
  label: wildcard()
  order: 0
---

## Signature

`wildcard()` — returns `struct`

**Available in:** `mapper`
**Category:** Routing

## Description

Special wildcard matching generates routes with `


## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `method` | `string` | no | `get` | List of HTTP methods (verbs) to generate the wildcard routes for. We strongly recommend leaving the default value of `get` and using other routing mappers if you need to `POST` to a URL endpoint. For better readability, you can also pass this argument as `methods` if you're listing multiple methods. |
| `action` | `string` | no | `index` | Default action to specify if the value for the `[action]` placeholder is not provided. |
| `mapKey` | `boolean` | no | `false` | Whether or not to enable a `[key]` matcher, enabling a `[controller]/[action]/[key]` pattern. |
| `mapFormat` | `boolean` | no | `false` | Whether or not to add an optional `.[format]` pattern to the end of the generated routes. This is useful for providing formats via URL like `json`, `xml`, `pdf`, etc. |

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
