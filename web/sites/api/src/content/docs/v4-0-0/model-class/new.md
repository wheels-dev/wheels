---
title: new()
description: "Creates a new object based on supplied <code>properties</code> and returns it."
sidebar:
  label: new()
  order: 0
---

## Signature

`new()` — returns `any`

**Available in:** `model`
**Category:** Create Functions

## Description

Creates a new object based on supplied <code>properties</code> and returns it.
The object is not saved to the database, it only exists in memory.
Property names and values can be passed in either using named arguments or as a struct to the <code>properties</code> argument.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `properties` | `struct` | no | `[runtime expression]` | The properties you want to set on the object (can also be passed in as named arguments). |
| `callbacks` | `boolean` | no | `true` | Set to `false` to disable callbacks for this method. |
| `allowExplicitTimestamps` | `boolean` | no | `false` | Set this to `true` to allow explicit assignment of `createdAt` or `updatedAt` properties |

</div>

