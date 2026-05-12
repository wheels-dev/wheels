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
| `$call` | `string` | no | `scope` |  |

</div>

