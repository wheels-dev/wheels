---
title: afterCommit()
description: "Registers method(s) to run AFTER the database transaction commits (v4.2.0)."
sidebar:
  label: afterCommit()
  order: 0
---

## Signature

`afterCommit()` — returns `void`

**Available in:** `model`
**Category:** Callback Functions

## Description

Registers method(s) to run AFTER the database transaction commits (v4.2.0).
They run only when the OUTERMOST transaction commits; a rollback discards
them. With no transaction (transactionMode="none"/"false") they fire
immediately after the write, since it is already committed.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names that should be called when this callback event occurs in an object's life cycle (can also be called with the `method` argument). |
| `on` | `string` | no | — | Restrict to one or more operations: create, update, delete (comma-delimited; blank = all). |

</div>

