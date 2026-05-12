---
title: version()
description: "Scope routes under a version prefix within an API group. Creates a URL path prefix of <code>v{number}</code> (e.g., <code>/api/v1/users</code>) and a name prefi"
sidebar:
  label: version()
  order: 0
---

## Signature

`version()` — returns `struct`

**Available in:** `mapper`
**Category:** Routing

## Description

Scope routes under a version prefix within an API group. Creates a URL path prefix of <code>v{number}</code> (e.g., <code>/api/v1/users</code>) and a name prefix of <code>v{number}</code> for named route generation.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `number` | `numeric` | yes | — | The version number (e.g., `1` creates path prefix `v1`). |
| `path` | `string` | no | `[runtime expression]` | Override the path prefix. Defaults to `v{number}`. |
| `name` | `string` | no | `[runtime expression]` | Override the name prefix. Defaults to `v{number}`. |
| `callback` | `any` | no | — | A callback function to define nested routes within this version scope. |

</div>

