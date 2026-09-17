---
title: scope()
description: "Set any number of parameters to be inherited by mappers called within this matcher's block. For example, set a package or URL path to be used by all child route"
sidebar:
  label: scope()
  order: 0
---

## Signature

`scope()` — returns `struct`

**Available in:** `mapper`
**Category:** Routing

## Description

Set any number of parameters to be inherited by mappers called within this matcher's block. For example, set a package or URL path to be used by all child routes.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | no | — | Name to prepend to child route names for use when building links, forms, and other URLs. |
| `path` | `string` | no | — | Path to prefix to all child routes. |
| `package` | `string` | no | — | Package namespace to append to controllers. |
| `controller` | `string` | no | — | Controller to use for routes. |
| `shallow` | `boolean` | no | — | Turn on shallow resources to eliminate routing added before this one. |
| `shallowPath` | `string` | no | — | Shallow path prefix. |
| `shallowName` | `string` | no | — | Shallow name prefix. |
| `constraints` | `struct` | no | — | Variable patterns to use for matching. |
| `middleware` | `any` | no | — |  |
| `binding` | `any` | no | — |  |
| `bindBy` | `any` | no | — |  |
| `callback` | `any` | no | — | A callback function to define nested routes within this scope. If provided, the scope is automatically closed when the callback completes. |
| `$call` | `string` | no | `scope` |  |

</div>

## Examples

<pre><code class='javascript'>&lt;cfscript&gt;

mapper()
    // 1. Scope routes to a specific controller.
    // All routes inside will use the `freeForAll` controller.
    .scope(controller=&quot;freeForAll&quot;)
        .get(name=&quot;bananas&quot;, action=&quot;bananas&quot;)
        .root(action=&quot;index&quot;)
    .end()

    // 2. Scope routes to a package (subfolder) without affecting the URL.
    // All routes' controllers inside will be inside the `public` package/subfolder.
    .scope(package=&quot;public&quot;)
        .resource(name=&quot;search&quot;, only=&quot;show,create&quot;)
    .end()

    // 3. Scope routes under a URL path prefix.
    // All routes inside will be prepended with a URL path of `phones/`.
    .scope(path=&quot;phones&quot;)
        .get(name=&quot;newest&quot;, to=&quot;phones##newest&quot;)
        .get(name=&quot;sortOfNew&quot;, to=&quot;phones##sortOfNew&quot;)
    .end()

    // 4. Scope routes with both a name prefix and URL path prefix.
    // Generates named routes like `adminUsers` and `adminPosts`.
    .scope(name=&quot;admin&quot;, path=&quot;admin&quot;)
        .resources(name=&quot;users&quot;)
        .resources(name=&quot;posts&quot;)
    .end()

    // 5. Scope routes with URL variable constraints applied to all children.
    .scope(constraints={id=&quot;[0-9]+&quot;})
        .get(name=&quot;userProfile&quot;, to=&quot;users##profile&quot;)
        .resources(name=&quot;orders&quot;)
    .end()
.end();

&lt;/cfscript&gt;
</code></pre>
