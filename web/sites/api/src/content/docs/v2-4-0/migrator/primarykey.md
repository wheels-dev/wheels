---
title: primaryKey()
description: "Adds a primary key definition to the table. this method also allows for multiple primary keys."
sidebar:
  label: primaryKey()
  order: 0
---

## Signature

`primaryKey()` — returns `any`

**Available in:** `tabledefinition`
**Category:** Table Definition Functions

## Description

Adds a primary key definition to the table. this method also allows for multiple primary keys.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — |  |
| `type` | `string` | no | `integer` |  |
| `autoIncrement` | `boolean` | no | `false` |  |
| `limit` | `numeric` | no | — |  |
| `precision` | `numeric` | no | — |  |
| `scale` | `numeric` | no | — |  |
| `references` | `string` | no | — |  |
| `onUpdate` | `string` | no | — |  |
| `onDelete` | `string` | no | — |  |

</div>

