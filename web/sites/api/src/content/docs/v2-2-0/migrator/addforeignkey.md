---
title: addForeignKey()
description: "Add a foreign key constraint to the database, using the reference name that was used to create it"
sidebar:
  label: addForeignKey()
  order: 0
---

## Signature

`addForeignKey()` — returns `void`

**Available in:** `migration`
**Category:** Migration Functions

## Description

Add a foreign key constraint to the database, using the reference name that was used to create it
Only available in a migration CFC



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `table` | `string` | yes | — | The table name to perform the operation on |
| `referenceTable` | `string` | yes | — | The reference table name to perform the operation on |
| `column` | `string` | yes | — | The column name to perform the operation on |
| `referenceColumn` | `string` | yes | — | The reference column name to perform the operation on |

