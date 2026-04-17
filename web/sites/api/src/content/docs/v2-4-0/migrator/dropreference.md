---
title: dropReference()
description: "Drop a foreign key constraint from the database, using the reference name that was used to create it"
sidebar:
  label: dropReference()
  order: 0
---

## Signature

`dropReference()` — returns `void`

**Available in:** `migration`
**Category:** Migration Functions

## Description

Drop a foreign key constraint from the database, using the reference name that was used to create it
Only available in a migration CFC



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `table` | `string` | yes | — | The table name to perform the operation on |
| `referenceName` | `string` | yes | — | the name of the reference to drop |

