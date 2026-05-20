---
title: paginationNav()
description: "Creates a complete pagination navigation element wrapping individual pagination helpers."
sidebar:
  label: paginationNav()
  order: 0
---

## Signature

`paginationNav()` — returns `string`

**Available in:** `controller`
**Category:** Pagination Functions

## Description

Creates a complete pagination navigation element wrapping individual pagination helpers.
Outputs a <code><nav></code> element containing first/previous/page-numbers/next/last links and optional info text.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `handle` | `string` | no | `query` | The handle given to the query that the pagination should be displayed for. |
| `navClass` | `string` | no | `pagination` | CSS class for the wrapping nav element. |
| `showFirst` | `boolean` | no | `true` | Whether to show the first page link. |
| `showLast` | `boolean` | no | `true` | Whether to show the last page link. |
| `showPrevious` | `boolean` | no | `true` | Whether to show the previous page link. |
| `showNext` | `boolean` | no | `true` | Whether to show the next page link. |
| `showInfo` | `boolean` | no | `false` | Whether to show the pagination info text. |
| `showSinglePage` | `boolean` | no | `false` | Whether to show pagination when there is only one page. |
| `encode` | `any` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |

</div>

