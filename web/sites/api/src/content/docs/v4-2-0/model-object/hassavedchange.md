---
title: hasSavedChange()
description: "Returns <code>true</code> if the last successful save changed the specified property, or any property if"
sidebar:
  label: hasSavedChange()
  order: 0
---

## Signature

`hasSavedChange()` — returns `boolean`

**Available in:** `model`
**Category:** Change Functions

## Description

Returns <code>true</code> if the last successful save changed the specified property, or any property if
none is passed in. See <code>savedChanges()</code> for when that information is available.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | no | — | Name of property (or a list of properties) to check. |

</div>

