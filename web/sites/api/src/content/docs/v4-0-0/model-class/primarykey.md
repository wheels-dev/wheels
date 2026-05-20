---
title: primaryKey()
description: "Returns the name of the primary key for this model's table."
sidebar:
  label: primaryKey()
  order: 0
---

## Signature

`primaryKey()` — returns `string`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Returns the name of the primary key for this model's table.
This is determined through database introspection.
If composite primary keys have been used, they will both be returned in a list.
This function is also aliased as <code>primaryKeys()</code>.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `position` | `numeric` | no | `0` | If you are accessing a composite primary key, pass the position of a single key to fetch. |

</div>

