---
title: dropForeignKey()
description: "Drops a foreign key constraint from the database"
sidebar:
  label: dropForeignKey()
  order: 0
---

## Signature

`dropForeignKey()` — returns `void`

**Available in:** `migration`
**Category:** Migration Functions

## Description

Drops a foreign key constraint from the database
Only available in a migration CFC



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `table` | `string` | yes | — | The table name to perform the operation on |
| `keyName` | `string` | yes | — | the name of the key to drop |

