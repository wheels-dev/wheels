---
title: group()
description: "Group routes together with shared attributes like path prefix, name prefix, and constraints without implying a controller package or namespace. Unlike <code>nam"
sidebar:
  label: group()
  order: 0
---

## Signature

`group()` — returns `struct`

**Available in:** `mapper`
**Category:** Routing

## Description

Group routes together with shared attributes like path prefix, name prefix, and constraints without implying a controller package or namespace. Unlike <code>namespace()</code> (which maps to a subfolder and URL prefix) or <code>package()</code> (which maps to a subfolder), <code>group()</code> is a pure organizational grouping mechanism.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | no | — | Name to prepend to child route names for use when building links, forms, and other URLs. |
| `path` | `string` | no | — | URL path prefix to apply to all child routes. |
| `constraints` | `struct` | no | — | Variable patterns (regex constraints) to apply to all child routes. |
| `callback` | `any` | no | — | A callback function to define nested routes within this group. If provided, the group is automatically closed when the callback completes. |

</div>

