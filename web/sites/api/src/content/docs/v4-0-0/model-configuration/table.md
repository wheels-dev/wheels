---
title: table()
description: "Use this method to tell Wheels what database table to connect to for this model."
sidebar:
  label: table()
  order: 0
---

## Signature

`table()` — returns `void`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Use this method to tell Wheels what database table to connect to for this model.
You only need to use this method when your table naming does not follow the standard Wheels convention of a singular object name mapping to a plural table name.
To not use a table for your model at all, call <code>table(false)</code>.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `any` | yes | — | Name of the table to map this model to. |

</div>

