---
title: findLastOne()
description: "Fetches the last record ordered by primary key value."
sidebar:
  label: findLastOne()
  order: 0
---

## Signature

`findLastOne()` — returns `any`

**Available in:** `model`
**Category:** Read Functions

## Description

Fetches the last record ordered by primary key value.
Use the <code>property</code> argument to order by something else.
Returns a model object. Formerly known as findLast.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | no | — | Name of the property to order by. This argument is also aliased as `properties`. |

</div>

