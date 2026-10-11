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

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `method` | `string` | no | `get` | List of HTTP methods (verbs) to generate the wildcard routes for. We strongly recommend leaving the default value of `get` and using other routing mappers if you need to `POST` to a URL endpoint. Pass an empty string to generate the wildcard routes for all verbs (`get`, `post`, `put`, `patch`, and `delete`). |
| `action` | `string` | no | `index` | Default action to specify if the value for the `[action]` placeholder is not provided. |
| `mapKey` | `boolean` | no | `false` | Whether or not to enable a `[key]` matcher, enabling a `[controller]/[action]/[key]` pattern. |
| `mapFormat` | `boolean` | no | `false` | Whether or not to add an optional `.[format]` pattern to the end of the generated routes. This is useful for providing formats via URL like `json`, `xml`, `pdf`, etc. |
| `methods` | `string` | no | — | Alias for `method`, provided for better readability when listing multiple methods. Takes precedence over `method` when both are passed. |

</div>

## Examples

<pre><code class='javascript'>&lt;cfscript&gt;

mapper()
    // 1. Basic wildcard: enables `[controller]` and `[controller]/[action]`
    //    patterns via GET requests only.
    .wildcard()

    // 2. Also enable a `[controller]/[action]/[key]` pattern.
    .wildcard(mapKey=true)

    // 3. Add an optional `.[format]` suffix to every generated pattern,
    //    e.g. `[controller]/[action].json`.
    .wildcard(mapFormat=true)

    // 4. Change the default action when only `[controller]` is matched.
    //    Requests to `/photos` will route to `photos##home` instead of
    //    `photos##index`.
    .wildcard(action=&quot;home&quot;)

    // 5. Allow additional HTTP methods beyond GET.
    //    Note: opening up extra methods can create security holes unless
    //    you use `verifies` in your controller to guard data-changing actions.
    .wildcard(method=&quot;get,post&quot;)
.end();

&lt;/cfscript&gt;
</code></pre>
