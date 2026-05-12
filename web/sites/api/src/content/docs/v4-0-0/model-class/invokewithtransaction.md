---
title: invokeWithTransaction()
description: "Runs the specified method within a single database transaction."
sidebar:
  label: invokeWithTransaction()
  order: 0
---

## Signature

`invokeWithTransaction()` — returns `any`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Runs the specified method within a single database transaction.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `method` | `string` | yes | — | Model method to run. |
| `transaction` | `string` | no | `commit` | Set this to `commit` to update the database, `rollback` to run all the database queries but not commit them, or `none` to skip transaction handling altogether. |
| `isolation` | `string` | no | `read_committed` | Isolation level to be passed through to the cftransaction tag. See your CFML engine's documentation for more details about cftransaction's isolation attribute. |

</div>

