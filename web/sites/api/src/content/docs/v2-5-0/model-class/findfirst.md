---
title: findFirst()
description: "Fetches the first record ordered by primary key value."
sidebar:
  label: findFirst()
  order: 0
---

## Signature

`findFirst()` — returns `any`

**Available in:** `model`
**Category:** Read Functions

## Description

Fetches the first record ordered by primary key value.
Use the <code>property</code> argument to order by something else.
Returns a model object.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | no | `[runtime expression]` | Name of the property to order by. This argument is also aliased as `properties`. |
| `$sort` | `string` | no | `ASC` |  |

