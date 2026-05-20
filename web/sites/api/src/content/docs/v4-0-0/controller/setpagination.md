---
title: setPagination()
description: "Allows you to set a pagination handle for a custom query so you can perform pagination on it in your view with <code>paginationLinks</code>."
sidebar:
  label: setPagination()
  order: 0
---

## Signature

`setPagination()` — returns `void`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** Pagination Functions

## Description

Allows you to set a pagination handle for a custom query so you can perform pagination on it in your view with <code>paginationLinks</code>.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `totalRecords` | `numeric` | yes | — | Total count of records that should be represented by the paginated links. |
| `currentPage` | `numeric` | no | `1` | Page number that should be represented by the data being fetched and the paginated links. |
| `perPage` | `numeric` | no | `25` | Number of records that should be represented on each page of data. |
| `handle` | `string` | no | `query` | Name of handle to reference in `paginationLinks`. |

</div>

