---
title: addReference()
description: "Add a foreign key constraint to the database, using the reference name that was used to create it"
sidebar:
  label: addReference()
  order: 0
---

## Signature

`addReference()` — returns `void`

**Available in:** `migration`
**Category:** Migration Functions

## Description

Add a foreign key constraint to the database, using the reference name that was used to create it
Only available in a migration CFC



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `table` | `string` | yes | — | The table name to perform the operation on |
| `referenceName` | `string` | yes | — | The reference table name to perform the operation on |

</div>

