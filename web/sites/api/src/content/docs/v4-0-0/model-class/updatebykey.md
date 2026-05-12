---
title: updateByKey()
description: "Finds the object with the supplied <code>key</code> and saves it (if validation permits it) with the supplied <code>properties</code> and / or named arguments."
sidebar:
  label: updateByKey()
  order: 0
---

## Signature

`updateByKey()` — returns `boolean`

**Available in:** `model`
**Category:** Update Functions

## Description

Finds the object with the supplied <code>key</code> and saves it (if validation permits it) with the supplied <code>properties</code> and / or named arguments.
Property names and values can be passed in either using named arguments or as a struct to the <code>properties</code> argument.
Returns <code>true</code> if the object was found and updated successfully, <code>false</code> otherwise.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `key` | `any` | yes | — | Primary key value(s) of the record to fetch. Separate with comma if passing in multiple primary key values. Accepts a string, list, or a numeric value. |
| `properties` | `struct` | no | `[runtime expression]` | The properties you want to set on the object (can also be passed in as named arguments). |
| `reload` | `boolean` | no | `false` | Set to `true` to force Wheels to query the database even though an identical query for this model may have been run in the same request. (The default in Wheels is to get the second query from the model's request-level cache.) |
| `validate` | `boolean` | no | `true` | Set to `false` to skip validations for this operation. |
| `transaction` | `string` | no | `[runtime expression]` | Set this to `commit` to update the database, `rollback` to run all the database queries but not commit them, or `none` to skip transaction handling altogether. |
| `callbacks` | `boolean` | no | `true` | Set to `false` to disable callbacks for this method. |
| `includeSoftDeletes` | `boolean` | no | `false` | Set to `true` to include soft-deleted records in the queries that this method runs. |

</div>

