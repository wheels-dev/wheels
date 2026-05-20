---
title: pagination()
description: "Returns a struct with information about the specified paginated query."
sidebar:
  label: pagination()
  order: 0
---

## Signature

`pagination()` — returns `struct`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** Pagination Functions

## Description

Returns a struct with information about the specified paginated query.
The keys that will be included in the struct are <code>currentPage</code>, <code>totalPages</code> and <code>totalRecords</code>.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `handle` | `string` | no | `query` | The handle given to the query to return pagination information for. |

</div>

