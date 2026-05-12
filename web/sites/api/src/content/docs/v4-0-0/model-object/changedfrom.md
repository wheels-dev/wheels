---
title: changedFrom()
description: "Returns the previous value of a property that has changed."
sidebar:
  label: changedFrom()
  order: 0
---

## Signature

`changedFrom()` — returns `string`

**Available in:** `model`
**Category:** Change Functions

## Description

Returns the previous value of a property that has changed.
Returns an empty string if no previous value exists.
Wheels will keep a note of the previous property value until the object is saved to the database.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | Name of property to get the previous value for. |

</div>

