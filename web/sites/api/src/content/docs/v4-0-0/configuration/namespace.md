---
title: namespace()
description: "Scopes any the controllers for any routes configured within this block to a subfolder (package) and also adds the package name to the URL."
sidebar:
  label: namespace()
  order: 0
---

## Signature

`namespace()` — returns `struct`

**Available in:** `mapper`
**Category:** Routing

## Description

Scopes any the controllers for any routes configured within this block to a subfolder (package) and also adds the package name to the URL.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Name to prepend to child route names. |
| `package` | `string` | no | `[runtime expression]` | Subfolder (package) to reference for controllers. This defaults to the value provided for `name`. |
| `path` | `string` | no | `[runtime expression]` | Subfolder path to add to the URL. |

</div>

