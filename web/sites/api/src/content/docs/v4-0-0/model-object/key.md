---
title: key()
description: "Returns the value of the primary key for the object."
sidebar:
  label: key()
  order: 0
---

## Signature

`key()` — returns `string`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Returns the value of the primary key for the object.
If you have a single primary key named id, then <code>someObject.key()</code> is functionally equivalent to <code>someObject.id</code>.
This method is more useful when you do dynamic programming and don't know the name of the primary key or when you use composite keys (in which case it's convenient to use this method to get a list of both key values returned).



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `$persisted` | `boolean` | no | `false` |  |
| `$returnTickCountWhenNew` | `boolean` | no | `false` |  |

</div>

