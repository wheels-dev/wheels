---
title: hasChanged()
description: "Returns <code>true</code> if the specified property (or any if none was passed in) has been changed but not yet saved to the database."
sidebar:
  label: hasChanged()
  order: 0
---

## Signature

`hasChanged()` — returns `boolean`

**Available in:** `model`
**Category:** Change Functions

## Description

Returns <code>true</code> if the specified property (or any if none was passed in) has been changed but not yet saved to the database.
Will also return <code>true</code> if the object is new and no record for it exists in the database.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | no | — | Name of property to check for change. |

</div>

