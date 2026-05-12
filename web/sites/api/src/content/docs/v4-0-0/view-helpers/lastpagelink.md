---
title: lastPageLink()
description: "Creates a link to the last page, or a disabled span when already on the last page."
sidebar:
  label: lastPageLink()
  order: 0
---

## Signature

`lastPageLink()` — returns `string`

**Available in:** `controller`
**Category:** Pagination Functions

## Description

Creates a link to the last page, or a disabled span when already on the last page.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `text` | `string` | no | `Last` | The text for the link. |
| `handle` | `string` | no | `query` | The handle given to the query that the pagination should be displayed for. |
| `name` | `string` | no | `page` | The name of the param that holds the current page number. |
| `class` | `string` | no | — | CSS class for the link element. |
| `disabledClass` | `string` | no | `disabled` | CSS class for the disabled span element. |
| `showDisabled` | `boolean` | no | `true` | Whether to render a disabled span when already on the last page. |
| `pageNumberAsParam` | `boolean` | no | `true` | Decides whether to link the page number as a param or as part of a route. |
| `encode` | `any` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |

</div>

