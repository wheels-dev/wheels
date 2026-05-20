---
title: package()
description: "Scopes any the controllers for any routes configured within this block to a subfolder (package) without adding the package name to the URL."
sidebar:
  label: package()
  order: 0
---

## Signature

`package()` — returns `struct`

**Available in:** `mapper`
**Category:** Routing

## Description

Scopes any the controllers for any routes configured within this block to a subfolder (package) without adding the package name to the URL.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Name to prepend to child route names. |
| `package` | `string` | no | `[runtime expression]` | Subfolder (package) to reference for controllers. This defaults to the value provided for `name`. |

</div>

