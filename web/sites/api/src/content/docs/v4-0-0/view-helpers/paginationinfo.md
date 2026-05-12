---
title: paginationInfo()
description: "Displays a text summary of the current pagination state, e.g. \"Showing 26-50 of 1,000 records\"."
sidebar:
  label: paginationInfo()
  order: 0
---

## Signature

`paginationInfo()` — returns `string`

**Available in:** `controller`
**Category:** Pagination Functions

## Description

Displays a text summary of the current pagination state, e.g. "Showing 26-50 of 1,000 records".
Uses token replacement in the format string: 


## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `handle` | `string` | no | `query` | The handle given to the query that the pagination info should be displayed for. |
| `format` | `string` | no | `Showing [startRow]-[endRow] of [totalRecords] records` | Format string with tokens: [startRow], [endRow], [totalRecords], [currentPage], [totalPages]. |
| `encode` | `any` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |

</div>

