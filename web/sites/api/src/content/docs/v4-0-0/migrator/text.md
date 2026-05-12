---
title: text()
description: "Adds text columns to table definition."
sidebar:
  label: text()
  order: 0
---

## Signature

`text()` — returns `any`

**Available in:** `tabledefinition`
**Category:** Table Definition Functions

## Description

Adds text columns to table definition.
In MySQL databases, you can specify different text sizes:
- Regular TEXT (65KB) - default when no size is specified
- MEDIUMTEXT (16MB) - specify size="mediumtext"
- LONGTEXT (4GB) - specify size="longtext"
For other database engines, the size parameter is ignored and the default text type is used.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `columnNames` | `string` | no | — |  |
| `default` | `string` | no | — |  |
| `allowNull` | `boolean` | no | — |  |
| `size` | `string` | no | — |  |

</div>

