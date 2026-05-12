---
title: createTable()
description: "Creates a table definition object to store table properties"
sidebar:
  label: createTable()
  order: 0
---

## Signature

`createTable()` — returns `TableDefinition`

**Available in:** `migration`
**Category:** Migration Functions

## Description

Creates a table definition object to store table properties
Only available in a migration CFC



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | The name of the table to create |
| `force` | `boolean` | no | `false` | whether to drop the table before creating it |
| `id` | `boolean` | no | `true` | Whether to create a default primarykey or not |
| `primaryKey` | `string` | no | `id` | Name of the primary key field to create |

</div>

