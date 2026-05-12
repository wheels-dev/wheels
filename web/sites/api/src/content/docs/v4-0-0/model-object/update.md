---
title: update()
description: "Updates the object with the supplied <code>properties</code> and saves it to the database."
sidebar:
  label: update()
  order: 0
---

## Signature

`update()` — returns `boolean`

**Available in:** `model`
**Category:** CRUD Functions

## Description

Updates the object with the supplied <code>properties</code> and saves it to the database.
Returns <code>true</code> if the object was saved successfully to the database and <code>false</code> otherwise.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `properties` | `struct` | no | `[runtime expression]` | The properties you want to set on the object (can also be passed in as named arguments). |
| `parameterize` | `any` | no | `true` | Set to `true` to use `cfqueryparam` on all columns, or pass in a list of property names to use `cfqueryparam` on those only. |
| `reload` | `boolean` | no | `false` | Set to `true` to force Wheels to query the database even though an identical query for this model may have been run in the same request. (The default in Wheels is to get the second query from the model's request-level cache.) |
| `validate` | `boolean` | no | `true` | Set to `false` to skip validations for this operation. |
| `transaction` | `string` | no | `[runtime expression]` | Set this to `commit` to update the database, `rollback` to run all the database queries but not commit them, or `none` to skip transaction handling altogether. |
| `callbacks` | `boolean` | no | `true` | Set to `false` to disable callbacks for this method. |
| `allowExplicitTimestamps` | `boolean` | no | `false` | Set this to `true` to allow explicit assignment of `createdAt` or `updatedAt` properties |

</div>

