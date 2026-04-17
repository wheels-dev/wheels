---
title: removeColumn()
description: "Removes a column from a database table"
sidebar:
  label: removeColumn()
  order: 0
---

## Signature

`removeColumn()` — returns `void`

**Available in:** `migration`
**Category:** Migration Functions

## Description

Removes a column from a database table
Only available in a migration CFC



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `table` | `string` | yes | — | The table containing the column to remove |
| `columnName` | `string` | no | — | The column name to remove |
| `referenceName` | `string` | no | — | optional reference name |

