---
title: afterFind()
description: "Registers method(s) that should be called after an existing object has been initialized (which is usually done with the <code>findByKey</code> or <code>findOne<"
sidebar:
  label: afterFind()
  order: 0
---

## Signature

`afterFind()` — returns `void`

**Available in:** `model`
**Category:** Callback Functions

## Description

Registers method(s) that should be called after an existing object has been initialized (which is usually done with the <code>findByKey</code> or <code>findOne</code> method).



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names that should be called when this callback event occurs in an object's life cycle (can also be called with the `method` argument). |

</div>

