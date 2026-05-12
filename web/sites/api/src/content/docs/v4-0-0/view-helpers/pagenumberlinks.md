---
title: pageNumberLinks()
description: "Creates a windowed set of page number links around the current page."
sidebar:
  label: pageNumberLinks()
  order: 0
---

## Signature

`pageNumberLinks()` — returns `string`

**Available in:** `controller`
**Category:** Pagination Functions

## Description

Creates a windowed set of page number links around the current page.
The current page is rendered as a span (not a link) unless <code>linkToCurrentPage</code> is true.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `windowSize` | `numeric` | no | `2` | The number of page links to show around the current page. |
| `handle` | `string` | no | `query` | The handle given to the query that the pagination should be displayed for. |
| `name` | `string` | no | `page` | The name of the param that holds the current page number. |
| `class` | `string` | no | — | CSS class for each page number link. |
| `classForCurrent` | `string` | no | `current` | CSS class for the current page span or link. |
| `linkToCurrentPage` | `boolean` | no | `false` | Whether to render the current page as a link. |
| `prependToPage` | `string` | no | — | String to prepend before each page number. |
| `appendToPage` | `string` | no | — | String to append after each page number. |
| `pageNumberAsParam` | `boolean` | no | `true` | Decides whether to link the page number as a param or as part of a route. |
| `encode` | `any` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |

</div>

