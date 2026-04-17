---
title: controller()
description: "The controller() function in Wheels is used to define routes that point to a specific controller. However, it is considered deprecated, because it does not alig"
sidebar:
  label: controller()
  order: 0
---

## Signature

`controller()` — returns `struct`

**Available in:** `mapper`
**Category:** Routing

## Description

The controller() function in Wheels is used to define routes that point to a specific controller. However, it is considered deprecated, because it does not align with RESTful routing principles. Wheels encourages using resources() and other RESTful routing helpers instead.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `controller` | `string` | yes | — |  |
| `name` | `string` | no | `[runtime expression]` |  |
| `path` | `string` | no | `[runtime expression]` |  |

