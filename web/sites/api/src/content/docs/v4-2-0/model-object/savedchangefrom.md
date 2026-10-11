---
title: savedChangeFrom()
description: "Returns the value a property had before the last successful save changed it, or an empty"
sidebar:
  label: savedChangeFrom()
  order: 0
---

## Signature

`savedChangeFrom()` — returns `string`

**Available in:** `model`
**Category:** Change Functions

## Description

Returns the value a property had before the last successful save changed it, or an empty
string when that save didn't change it.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | Name of property to get the previous value for. |

</div>

