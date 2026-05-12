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
| `$call` | `string` | no | `scope` |  |

</div>

## Examples

<pre><code class='javascript'>&lt;cfscript&gt;

mapper()
    // All routes inside will use the `freeForAll` controller.
    .scope(controller=&quot;freeForAll&quot;)
        .get(name=&quot;bananas&quot;, action=&quot;bananas&quot;)
        .root(action=&quot;index&quot;)
    .end()

    // All routes's controllers inside will be inside the `public` package/subfolder.
    .scope(package=&quot;public&quot;)
        .resource(name=&quot;search&quot;, only=&quot;show,create&quot;)
    .end()

    // All routes inside will be prepended with a URL path of `phones/`.
    .scope(path=&quot;phones&quot;)
        .get(name=&quot;newest&quot;, to=&quot;phones##newest&quot;)
        .get(name=&quot;sortOfNew&quot;, to=&quot;phones##sortOfNew&quot;)
    .end()
.end();

&lt;/cfscript&gt;</code></pre>
