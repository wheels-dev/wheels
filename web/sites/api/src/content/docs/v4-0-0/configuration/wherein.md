---
title: whereIn()
description: "Constrain a route variable to only match one of a set of allowed values. Similar to an enum constraint."
sidebar:
  label: whereIn()
  order: 0
---

## Signature

`whereIn()` — returns `struct`

**Available in:** `mapper`
**Category:** Routing

## Description

Constrain a route variable to only match one of a set of allowed values. Similar to an enum constraint.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `variableName` | `string` | yes | — | The route variable name to constrain. |
| `values` | `string` | yes | — | A comma-delimited list of allowed values (e.g., `"active,inactive,pending"`). |

</div>

