---
title: enum()
description: "Maps a property to a set of named values (like Rails enums)."
sidebar:
  label: enum()
  order: 0
---

## Signature

`enum()` — returns `void`

**Available in:** `model`
**Category:** Enum Functions

## Description

Maps a property to a set of named values (like Rails enums).
Generates boolean checker methods (<code>is<Value>()</code>), scopes for each value,
and validates that the property value is one of the allowed values.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | The name of the model property to map as an enum. |
| `values` | `any` | yes | — | Either a comma-delimited list of string values (e.g. `"draft,published,archived"`) or a struct mapping names to stored values (e.g. `{low: 0, medium: 1, high: 2}`). |

</div>

