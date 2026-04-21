---
title: references()
description: "adds integer reference columns to table definition and creates foreign key constraints"
sidebar:
  label: references()
  order: 0
---

## Signature

`references()` — returns `any`

**Available in:** `tabledefinition`
**Category:** Table Definition Functions

## Description

adds integer reference columns to table definition and creates foreign key constraints



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `referenceNames` | `string` | yes | — |  |
| `default` | `string` | no | — |  |
| `null` | `boolean` | no | `false` |  |
| `polymorphic` | `boolean` | no | `false` |  |
| `foreignKey` | `boolean` | no | `true` |  |
| `onUpdate` | `string` | no | — |  |
| `onDelete` | `string` | no | — |  |

</div>

