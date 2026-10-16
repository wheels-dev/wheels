---
title: forgetCachedQueries()
description: "Clears the per-request finder cache that <code>cacheQueriesDuringRequest</code> fills, namespaced under the"
sidebar:
  label: forgetCachedQueries()
  order: 0
---

## Signature

`forgetCachedQueries()` — returns `any`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** General Functions

## Description

Clears the per-request finder cache that <code>cacheQueriesDuringRequest</code> fills, namespaced under the
reserved <code>request.wheels

</code>model("X").forgetCachedQueries()`.
outside a model.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `modelName` | `string` | no | — | Clear only this model's slot. Defaults to the calling model's own name when invoked as |
| `all` | `boolean` | no | `false` | Clear every model's cached queries for the request. Required (true) to wipe everything from |

</div>

