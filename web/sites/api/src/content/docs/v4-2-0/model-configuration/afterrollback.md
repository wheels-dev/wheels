---
title: afterRollback()
description: "Registers method(s) to run AFTER the database transaction rolls back (v4.2.0)."
sidebar:
  label: afterRollback()
  order: 0
---

## Signature

`afterRollback()` — returns `void`

**Available in:** `model`
**Category:** Callback Functions

## Description

Registers method(s) to run AFTER the database transaction rolls back (v4.2.0).



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names that should be called when this callback event occurs in an object's life cycle (can also be called with the `method` argument). |
| `on` | `string` | no | — | Restrict to one or more operations: create, update, delete (comma-delimited; blank = all). |

</div>

